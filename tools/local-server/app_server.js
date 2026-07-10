// RicetteBuddy — server locale: statico (build web) + API reale con import da
// GialloZafferano/Instagram/Pinterest + veganizzazione/arricchimento AI e
// persistenza su file. (In produzione la stessa logica vive nelle Edge Functions.)
//
// Avvio:  cd tools/local-server && node app_server.js
// Richiede la build web:  cd ../../app && flutter build web
const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

// Carica le variabili da tools/local-server/.env (se presente) PRIMA di
// richiedere i moduli che leggono ANTHROPIC_API_KEY. Il file .env è gitignored:
// ci metti la chiave una volta e i riavvii successivi non la richiedono più.
(() => {
  const file = process.env.ENV_FILE || path.join(__dirname, ".env");
  try {
    const txt = fs.readFileSync(file, "utf8");
    for (const line of txt.split(/\r?\n/)) {
      const m = line.match(/^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$/);
      if (m && !process.env[m[1]]) {
        process.env[m[1]] = m[2].replace(/^["']|["']$/g, "").trim();
      }
    }
  } catch {}
})();

const { parseRecipe, listVeganUrls } = require("./gz_parser.js");
const { importInstagram, importInstagramPost } = require("./instagram.js");
const { importFacebookPost, extractFacebook } = require("./facebook.js");
const { importTikTok } = require("./tiktok.js");
const { importYouTube } = require("./youtube.js");
const { importPinterest, parseGenericRecipe } = require("./pinterest.js");
const { enrichRecipe, enrichRecipeStream } = require("./enrich_server.js");
const SSE_HEADERS = {
  "Content-Type": "text/event-stream",
  "Cache-Control": "no-cache",
  "Connection": "keep-alive",
  "X-Accel-Buffering": "no",
};

// --- Cache locale delle foto ricetta -----------------------------------
// Gli URL immagine dei social (scontent IG/FB) sono FIRMATI e scadono dopo
// qualche settimana: all'import scarichiamo la foto in media/ e salviamo il
// percorso locale, così le ricette non perdono mai l'immagine.
const _fs = require("fs");
const _path = require("path");
const MEDIA_DIR = _path.join(__dirname, "media");
try { _fs.mkdirSync(MEDIA_DIR, { recursive: true }); } catch { /* già esiste */ }

async function cacheImage(u, id) {
  try {
    if (!u || !/^https?:\/\//i.test(String(u))) return u;
    const r = await fetch(u, {
      headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" },
      redirect: "follow",
    });
    if (!r.ok) return u;
    const ct = String(r.headers.get("content-type") || "");
    if (!ct.startsWith("image/")) return u; // mai salvare HTML/altro come foto
    const ext = ct.includes("png") ? "png" : ct.includes("webp") ? "webp" : "jpg";
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length < 1000) return u; // non è un'immagine vera
    const name = `r${id}.${ext}`;
    _fs.writeFileSync(_path.join(MEDIA_DIR, name), buf);
    return "media/" + name; // percorso relativo, risolto dall'app sul backend
  } catch { return u; }
}

// og:image di una pagina via fetch con UA crawler (veloce, niente browser).
async function ogImageOf(u) {
  try {
    const r = await fetch(u, {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; Twitterbot/1.0)" },
      redirect: "follow",
    });
    if (!r.ok) return null;
    const html = await r.text();
    const m = html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i) ||
      html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i);
    return m ? m[1].replace(/&amp;/g, "&") : null;
  } catch { return null; }
}

// GET /media/<file> — foto ricetta scaricate all'import (cache locale).
function serveMedia(req, res, url) {
  const name = url.pathname.slice(7);
  if (!/^[A-Za-z0-9._-]+$/.test(name)) { res.writeHead(400); return res.end("bad name"); }
  const fp = _path.join(MEDIA_DIR, name);
  if (!_fs.existsSync(fp)) { res.writeHead(404); return res.end("not found"); }
  const ext = name.split(".").pop();
  const mime = ext === "png" ? "image/png" : ext === "webp" ? "image/webp" : "image/jpeg";
  res.writeHead(200, { "Content-Type": mime, "Cache-Control": "public, max-age=31536000" });
  res.end(_fs.readFileSync(fp));
}
const { iconSvg } = require("./icongen.js");

const ROOT = process.env.WEB_ROOT || path.join(__dirname, "../../app/build/web");
const DB = path.join(__dirname, "recipes.json");
const PORT = process.env.PORT || 8080;
// Sul PC resta 127.0.0.1 (solo locale); sulla VPS si mette HOST=0.0.0.0 per
// esporre l'API all'esterno (IP:porta).
const HOST = process.env.HOST || "127.0.0.1";
const FFMPEG = process.env.FFMPEG || "ffmpeg"; // per lo streaming video
const crypto = require("crypto");
const CACHE = path.join(__dirname, "video-cache");
fs.mkdirSync(CACHE, { recursive: true });

// Video: gli MP4 di GZ non sono "faststart" (moov in fondo), quindi il browser
// aspetterebbe il download completo. Li rimuxiamo con ffmpeg in un file
// faststart (moov all'inizio) servito con supporto Range: il player parte
// subito ed è seekabile. Il file remuxato è messo in cache.
function serveFileRange(req, res, file) {
  const size = fs.statSync(file).size;
  const range = req.headers.range;
  if (range) {
    const m = range.match(/bytes=(\d+)-(\d*)/);
    const s = parseInt(m[1], 10);
    const e = m[2] ? parseInt(m[2], 10) : size - 1;
    res.writeHead(206, {
      "Content-Type": "video/mp4",
      "Accept-Ranges": "bytes",
      "Content-Range": `bytes ${s}-${e}/${size}`,
      "Content-Length": e - s + 1,
    });
    fs.createReadStream(file, { start: s, end: e }).pipe(res);
  } else {
    res.writeHead(200, {
      "Content-Type": "video/mp4",
      "Accept-Ranges": "bytes",
      "Content-Length": size,
    });
    fs.createReadStream(file).pipe(res);
  }
}

function streamVideo(req, res, u) {
  const key = crypto.createHash("md5").update(u).digest("hex");
  const file = path.join(CACHE, key + ".mp4");
  if (fs.existsSync(file) && fs.statSync(file).size > 0) {
    return serveFileRange(req, res, file);
  }
  const tmp = file + ".tmp";
  const ff = spawn(FFMPEG, [
    "-y", "-loglevel", "error", "-i", u, "-c", "copy",
    "-movflags", "+faststart", "-f", "mp4", tmp,
  ]);
  ff.on("error", () => { res.writeHead(502); res.end("ffmpeg error"); });
  ff.on("close", (code) => {
    if (code === 0 && fs.existsSync(tmp) && fs.statSync(tmp).size > 0) {
      fs.renameSync(tmp, file);
      serveFileRange(req, res, file);
    } else {
      try { fs.unlinkSync(tmp); } catch {}
      res.writeHead(502); res.end("remux failed");
    }
  });
}
const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120 Safari/537.36";

// Proxy immagini: le immagini di GialloZafferano non hanno header CORS e
// Flutter web (CanvasKit) ne scarica i byte -> fallirebbero. Le serviamo
// same-origin attraverso il server.
async function proxyImage(res, u) {
  try {
    const r = await fetch(u, {
      headers: { "User-Agent": UA, Referer: "https://www.giallozafferano.it/" },
    });
    const buf = Buffer.from(await r.arrayBuffer());
    res.writeHead(r.status, {
      "Content-Type": r.headers.get("content-type") || "image/jpeg",
      "Cache-Control": "public, max-age=86400",
    });
    res.end(buf);
  } catch (e) {
    res.writeHead(502); res.end("proxy error");
  }
}

let recipes = [];
try { recipes = JSON.parse(fs.readFileSync(DB, "utf8")); } catch { recipes = []; }
let seq = recipes.reduce((m, r) => Math.max(m, +r.id || 0), 0);
const save = () => fs.writeFileSync(DB, JSON.stringify(recipes));

const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript",
  ".json": "application/json", ".css": "text/css", ".wasm": "application/wasm",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
  ".svg": "image/svg+xml", ".ico": "image/x-icon", ".ttf": "font/ttf",
  ".woff": "font/woff", ".woff2": "font/woff2", ".map": "application/json",
  ".otf": "font/otf" };

function sendJson(res, code, body) {
  res.writeHead(code, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body));
}
function readBody(req) {
  return new Promise((resolve) => {
    let d = ""; req.on("data", (c) => (d += c));
    req.on("end", () => { try { resolve(JSON.parse(d || "{}")); } catch { resolve({}); } });
  });
}
function matchesDiets(recipeDiets, active) {
  return active.every((d) => (recipeDiets || []).includes(d));
}

async function handleApi(req, res, url) {
  const parts = url.pathname.split("/").filter(Boolean); // ['api', ...]

  // GET /api/ingredient-icon?name=...  -> icona SVG (cache + genera al bisogno)
  if (req.method === "GET" && url.pathname === "/api/ingredient-icon") {
    const name = url.searchParams.get("name") || "";
    if (!name.trim()) { res.writeHead(400); return res.end(""); }
    let svg = null;
    try { svg = await iconSvg(name); } catch (e) { console.log("icon ERR:", e.message); }
    if (!svg) { res.writeHead(404); return res.end(""); }
    res.writeHead(200, {
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Cache-Control": "public, max-age=604800",
    });
    return res.end(svg);
  }

  if (req.method === "GET" && url.pathname === "/api/recipes") {
    return sendJson(res, 200, recipes);
  }
  if (req.method === "GET" && parts[1] === "recipes" && parts[2]) {
    const r = recipes.find((x) => x.id === parts[2]);
    return r ? sendJson(res, 200, r) : sendJson(res, 404, { error: "not found" });
  }
  if (req.method === "POST" && url.pathname === "/api/recipes") {
    const body = await readBody(req);
    const r = { ...body, id: String(++seq) };
    recipes.unshift(r); save();
    return sendJson(res, 201, r);
  }
  if (req.method === "PUT" && parts[1] === "recipes" && parts[2]) {
    const body = await readBody(req);
    const i = recipes.findIndex((x) => x.id === parts[2]);
    if (i < 0) return sendJson(res, 404, { error: "not found" });
    recipes[i] = { ...recipes[i], ...body, id: parts[2] }; save();
    return sendJson(res, 200, recipes[i]);
  }
  if (req.method === "DELETE" && parts[1] === "recipes" && parts[2]) {
    recipes = recipes.filter((x) => x.id !== parts[2]); save();
    return sendJson(res, 200, { ok: true });
  }
  // POST /api/recipes/:id/refresh — aggiorna la FOTO della ricetta: ri-estrae
  // l'immagine dalla fonte (veloce, senza AI) e la salva in cache locale.
  if (req.method === "POST" && parts[1] === "recipes" && parts[2] && parts[3] === "refresh") {
    const idx = recipes.findIndex((x) => x.id === parts[2]);
    if (idx < 0) return sendJson(res, 404, { error: "Ricetta non trovata" });
    const old = recipes[idx];
    try {
      console.log("refresh foto:", old.id, old.title);
      const u = String(old.source_url || "");
      const isLocal = (s) => /^media\//.test(String(s || ""));
      if (!/^https?:/i.test(u)) {
        return sendJson(res, 422, {
          error: "Questa ricetta non ha una fonte collegata: reimportala per recuperare la foto.",
        });
      }
      let newImg = null;
      if (/facebook\.com|fb\.watch/i.test(u)) { try { newImg = (await extractFacebook(u)).image_url; } catch (e) { console.log("refresh fb:", e.message); } }
      else if (/tiktok\.com/i.test(u)) { try { newImg = (await importTikTok(u)).image_url; } catch (e) { console.log("refresh tt:", e.message); } }
      else if (/youtube\.com|youtu\.be/i.test(u)) {
        const m = u.match(/(?:youtu\.be\/|v=|shorts\/)([A-Za-z0-9_-]{6,})/);
        if (m) newImg = `https://i.ytimg.com/vi/${m[1]}/hqdefault.jpg`;
      }
      // Instagram, Pinterest, siti: og:image via fetch (funziona dal VPS).
      if (!newImg) newImg = await ogImageOf(u);

      // Regola: MAI degradare una foto locale funzionante.
      let finalImg = old.image_url;
      if (newImg) {
        const cached = await cacheImage(newImg, old.id);
        if (isLocal(cached)) finalImg = cached;
        else if (!isLocal(old.image_url)) finalImg = newImg;
      } else if (/^https?:/i.test(String(old.image_url || ""))) {
        // Nessuna nuova foto: prova almeno a mettere in cache quella attuale.
        const cached = await cacheImage(old.image_url, old.id);
        if (isLocal(cached)) finalImg = cached;
      }
      if (!finalImg || (!isLocal(finalImg) && finalImg === old.image_url && !newImg)) {
        return sendJson(res, 422, { error: "Non riesco a recuperare la foto dalla fonte." });
      }
      recipes[idx] = { ...old, image_url: finalImg }; save();
      console.log("refresh foto ok:", String(finalImg).slice(0, 60));
      return sendJson(res, 200, recipes[idx]);
    } catch (e) { return sendJson(res, 500, { error: String(e) }); }
  }
  // POST /api/import-url {url}
  if (req.method === "POST" && url.pathname === "/api/import-url") {
    const { url: u } = await readBody(req);
    try {
      console.log("import-url:", u);
      // DOPPIONE: stessa fonte già in libreria -> non re-importa, avvisa.
      const cached = recipes.find((x) => x.source_url === u);
      if (cached) {
        console.log("duplicate (url):", cached.title);
        return sendJson(res, 200, { ...cached, duplicate: true });
      }
      let r = null;
      if (/instagram\.com/i.test(u)) {
        // Singolo post/reel Instagram (didascalia via browser headless).
        try { r = await importInstagramPost(u); }
        catch (e) {
          console.log("ig post:", e.message);
          return sendJson(res, 422, { error: e.message || "Import Instagram non riuscito" });
        }
      } else if (/facebook\.com|fb\.watch/i.test(u)) {
        // Reel/video/post Facebook (didascalia dal meta og:title).
        try { r = await importFacebookPost(u); }
        catch (e) {
          console.log("fb post:", e.message);
          return sendJson(res, 422, { error: e.message || "Import Facebook non riuscito" });
        }
      } else if (/youtube\.com|youtu\.be/i.test(u)) {
        // Video/Shorts YouTube (ricetta dalla descrizione).
        try { r = await importYouTube(u); }
        catch (e) {
          console.log("yt:", e.message);
          return sendJson(res, 422, { error: e.message || "Import YouTube non riuscito" });
        }
      } else if (/tiktok\.com/i.test(u)) {
        // Video TikTok (didascalia via browser headless).
        try { r = await importTikTok(u); }
        catch (e) {
          console.log("tt:", e.message);
          return sendJson(res, 422, { error: e.message || "Import TikTok non riuscito" });
        }
      } else {
        // GialloZafferano -> parser ricco; altri siti -> parser JSON-LD generico.
        if (/giallozafferano/i.test(u)) {
          try { r = await parseRecipe(u); } catch (e) { console.log("gz parse:", e.message); }
        }
        if (!r) {
          try { r = await parseGenericRecipe(u); } catch (e) { console.log("generic parse:", e.message); }
        }
      }
      if (!r) return sendJson(res, 422, { error: "Ricetta non riconosciuta su questo sito" });
      // DOPPIONE (URL canonico): i social normalizzano la source_url togliendo i
      // parametri, quindi ricontrolliamo qui PRIMA dell'enrich (per non sprecare
      // la chiamata AI su una ricetta già presente).
      const dup = recipes.find((x) => x.source_url === r.source_url);
      if (dup) {
        console.log("duplicate (canonico):", dup.title);
        return sendJson(res, 200, { ...dup, duplicate: true });
      }
      console.log("parsed:", r.title, "-> enrich...");
      try { r = await enrichRecipe(r); console.log("enriched. was_vegan:", r.was_vegan); }
      catch (e) { console.log("enrich ERR:", e.message, "| cause:", e.cause && (e.cause.code || e.cause.message)); }
      const saved = { ...r, id: String(++seq) };
      saved.image_url = await cacheImage(saved.image_url, saved.id);
      recipes.unshift(saved); save();
      return sendJson(res, 201, saved);
    } catch (e) { return sendJson(res, 500, { error: String(e) }); }
  }
  // POST /api/extract-social {url} — estrazione server-side via yt-dlp
  // (Facebook e altri social che il dispositivo non può leggere): ritorna
  // {title, text, image_url, source_url} senza fare l'enrich.
  if (req.method === "POST" && url.pathname === "/api/extract-social") {
    const { url: u } = await readBody(req);
    try {
      console.log("extract-social:", u);
      const p = await extractFacebook(u); // yt-dlp è generico, non solo FB
      return sendJson(res, 200, p);
    } catch (e) {
      console.log("extract-social ERR:", e.message);
      return sendJson(res, 422, { error: e.message || "Estrazione non riuscita" });
    }
  }
  // POST /api/debug-log — diagnostica: appende il payload ricevuto a debug.log.
  if (req.method === "POST" && url.pathname === "/api/debug-log") {
    try {
      const body = await readBody(req);
      const line = new Date().toISOString() + " " + JSON.stringify(body) + "\n";
      require("fs").appendFileSync(require("path").join(__dirname, "debug.log"), line);
      console.log("DEBUG-LOG:", line.slice(0, 500));
    } catch (e) { console.log("debug-log err:", e.message); }
    return sendJson(res, 200, { ok: true });
  }
  // POST /api/enrich {title, text, image_url, source_url}
  // L'app estrae il contenuto SUL DISPOSITIVO (connessione e login dell'utente,
  // così i social non bloccano) e qui il server fa SOLO l'AI (veganizza,
  // struttura ingredienti+passi, traduce, quantità). Niente scraping centrale.
  if (req.method === "POST" && url.pathname === "/api/enrich") {
    const { title = "", text = "", image_url = null, source_url = "" } =
      await readBody(req);
    // Streaming SSE se richiesto: le fasi arrivano MENTRE l'AI genera davvero.
    const wantStream = String(req.headers.accept || "").includes("text/event-stream");
    const sse = (event, data) => res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
    try {
      if (!text || String(text).trim().length < 30) {
        if (wantStream) { res.writeHead(200, SSE_HEADERS); sse("error", { error: "Testo insufficiente per una ricetta." }); return res.end(); }
        return sendJson(res, 422, { error: "Testo insufficiente per una ricetta." });
      }
      if (source_url) {
        const dup = recipes.find((x) => x.source_url === source_url);
        if (dup) {
          console.log("duplicate (enrich):", dup.title);
          if (wantStream) { res.writeHead(200, SSE_HEADERS); sse("done", { ...dup, duplicate: true }); return res.end(); }
          return sendJson(res, 200, { ...dup, duplicate: true });
        }
      }
      let r = {
        title: (title || "Ricetta").slice(0, 80),
        image_url, source_url, source_type: "social",
        cook_minutes: null, diet_tags: [], ingredients: [],
        steps: [{ position: 0, text: String(text) }],
      };
      console.log("enrich (device-extracted):", r.title, wantStream ? "[stream]" : "");
      if (wantStream) {
        res.writeHead(200, SSE_HEADERS);
        // Heartbeat: tiene viva la connessione (l'app non va in timeout se
        // una fase dell'AI dura a lungo).
        const beat = setInterval(() => { try { res.write(": ping\n\n"); } catch { /* chiusa */ } }, 10000);
        try {
          r = await enrichRecipeStream(r, (phase) => sse("phase", { phase }));
        } catch (e) {
          clearInterval(beat);
          console.log("enrich stream ERR:", e.message);
          sse("error", { error: String(e.message || e) });
          return res.end();
        }
        clearInterval(beat);
        const saved = { ...r, id: String(++seq) };
        saved.image_url = await cacheImage(saved.image_url, saved.id);
        recipes.unshift(saved); save();
        sse("done", saved);
        return res.end();
      }
      try { r = await enrichRecipe(r); } catch (e) { console.log("enrich ERR:", e.message); }
      const saved = { ...r, id: String(++seq) };
      saved.image_url = await cacheImage(saved.image_url, saved.id);
      recipes.unshift(saved); save();
      return sendJson(res, 201, saved);
    } catch (e) {
      if (wantStream) { try { sse("error", { error: String(e) }); res.end(); } catch {} return; }
      return sendJson(res, 500, { error: String(e) });
    }
  }
  // POST /api/analyze {type, reference, diets, limit, pages}
  if (req.method === "POST" && url.pathname === "/api/analyze") {
    const { type = "web", reference = "", diets = [], limit = 30, pages = 15 } =
      await readBody(req);

    // Instagram: importatore interno (post pubblici -> ricetta dalla didascalia).
    if (type === "instagram") {
      try {
        const igRecipes = await importInstagram(reference);
        const existing = new Set(recipes.map((r) => r.source_url));
        const imported = [];
        for (const r of igRecipes) {
          if (existing.has(r.source_url)) continue;
          const saved = { ...r, id: String(++seq) };
          recipes.unshift(saved); imported.push(saved); existing.add(r.source_url);
        }
        save();
        return sendJson(res, 200, { imported });
      } catch (e) {
        return sendJson(res, 200, {
          imported: [], unsupported: true, message: String(e.message || e),
        });
      }
    }
    // Pinterest: board/profilo -> pin -> sito ricetta (headless).
    if (type === "pinterest") {
      try {
        const pinRecipes = await importPinterest(reference);
        const existing = new Set(recipes.map((r) => r.source_url));
        const imported = [];
        for (const r of pinRecipes) {
          if (existing.has(r.source_url)) continue;
          const saved = { ...r, id: String(++seq) };
          recipes.unshift(saved); imported.push(saved); existing.add(r.source_url);
        }
        save();
        return sendJson(res, 200, { imported });
      } catch (e) {
        return sendJson(res, 200, {
          imported: [], unsupported: true, message: String(e.message || e),
        });
      }
    }
    // Altri social non ancora supportati.
    if (type && type !== "web") {
      return sendJson(res, 200, {
        imported: [],
        unsupported: true,
        message: `Import da ${type} non ancora supportato. Per ora funzionano ` +
          `Instagram, Pinterest e i siti con ricette strutturate.`,
      });
    }

    try {
      const existing = new Set(recipes.map((r) => r.source_url));
      const imported = [];

      const isGzListing = /giallozafferano/i.test(reference) &&
        /(vegan|ricette-vegane|ricerca-ricette)/i.test(reference);
      const isSingleRecipe = /ricette\.giallozafferano\.it\/.+\.html/i.test(reference);

      if (isSingleRecipe && !isGzListing) {
        if (!existing.has(reference)) {
          const r = await parseRecipe(reference);
          if (r && matchesDiets(r.diet_tags, diets)) {
            const saved = { ...r, id: String(++seq) };
            recipes.unshift(saved); imported.push(saved);
          }
        }
      } else {
        const urls = await listVeganUrls(pages);
        for (const u of urls) {
          if (imported.length >= limit) break;
          if (existing.has(u)) continue;
          let r; try { r = await parseRecipe(u); } catch { continue; }
          if (!r || !matchesDiets(r.diet_tags, diets)) continue;
          const saved = { ...r, id: String(++seq) };
          recipes.unshift(saved); imported.push(saved); existing.add(u);
        }
      }
      save();
      return sendJson(res, 200, { imported });
    } catch (e) { return sendJson(res, 500, { error: String(e) }); }
  }
  return sendJson(res, 404, { error: "unknown api" });
}

function serveStatic(req, res, url) {
  let p = decodeURIComponent(url.pathname);
  if (p === "/") p = "/index.html";
  const file = path.join(ROOT, p);
  fs.readFile(file, (err, data) => {
    if (err) {
      fs.readFile(path.join(ROOT, "index.html"), (e2, idx) => {
        if (e2) { res.writeHead(404); return res.end("Not found"); }
        res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
        res.end(idx);
      });
      return;
    }
    const ext = path.extname(file).toLowerCase();
    res.writeHead(200, {
      "Content-Type": TYPES[ext] || "application/octet-stream",
      "Cache-Control": "no-cache",
    });
    res.end(data);
  });
}

http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  if (url.pathname === "/img") {
    const u = url.searchParams.get("u");
    if (!u) { res.writeHead(400); return res.end("missing u"); }
    return proxyImage(res, u);
  }
  if (url.pathname === "/video") {
    const u = url.searchParams.get("u");
    if (!u) { res.writeHead(400); return res.end("missing u"); }
    return streamVideo(req, res, u);
  }
  // Kill-switch: disinstalla eventuali vecchi service worker e svuota le cache
  // del browser, così viene sempre servita l'ultima build.
  if (url.pathname === "/flutter_service_worker.js") {
    res.writeHead(200, {
      "Content-Type": "text/javascript",
      "Cache-Control": "no-store",
    });
    return res.end(
      "self.addEventListener('install',()=>self.skipWaiting());" +
      "self.addEventListener('activate',(e)=>{e.waitUntil((async()=>{" +
      "try{const ks=await caches.keys();await Promise.all(ks.map(k=>caches.delete(k)));}catch(_){}" +
      "try{await self.registration.unregister();}catch(_){}" +
      "const cs=await self.clients.matchAll();cs.forEach(c=>c.navigate(c.url));" +
      "})());});",
    );
  }
  if (url.pathname.startsWith("/media/")) return serveMedia(req, res, url);
  if (url.pathname.startsWith("/api/")) return handleApi(req, res, url);
  serveStatic(req, res, url);
}).listen(PORT, HOST, () => {
  console.log(`RicetteBuddy server su http://${HOST}:${PORT} (${recipes.length} ricette salvate)`);
});

// RicetteBuddy — server locale di sviluppo: serve la build web e fornisce
// un'API reale con import da GialloZafferano e persistenza su file.
// (In produzione la stessa logica vive nelle Edge Functions Supabase.)
//
// Avvio:  cd tools/local-server && node app_server.js
// Richiede la build web:  cd ../../app && flutter build web
const http = require("http");
const fs = require("fs");
const path = require("path");
const { parseRecipe, listVeganUrls } = require("./gz_parser.js");

const ROOT = path.join(__dirname, "../../app/build/web");
const DB = path.join(__dirname, "recipes.json");
const PORT = 8080;
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
  const parts = url.pathname.split("/").filter(Boolean);

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
  if (req.method === "POST" && url.pathname === "/api/import-url") {
    const { url: u } = await readBody(req);
    try {
      const r = await parseRecipe(u);
      if (!r) return sendJson(res, 422, { error: "Ricetta non riconosciuta" });
      const saved = { ...r, id: String(++seq) };
      recipes.unshift(saved); save();
      return sendJson(res, 201, saved);
    } catch (e) { return sendJson(res, 500, { error: String(e) }); }
  }
  if (req.method === "POST" && url.pathname === "/api/analyze") {
    const { diets = [], limit = 24, pages = 6 } = await readBody(req);
    try {
      const urls = await listVeganUrls(pages);
      const existing = new Set(recipes.map((r) => r.source_url));
      const imported = [];
      for (const u of urls) {
        if (imported.length >= limit) break;
        if (existing.has(u)) continue;
        let r; try { r = await parseRecipe(u); } catch { continue; }
        if (!r || !matchesDiets(r.diet_tags, diets)) continue;
        const saved = { ...r, id: String(++seq) };
        recipes.unshift(saved); imported.push(saved); existing.add(u);
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
    res.writeHead(200, { "Content-Type": TYPES[ext] || "application/octet-stream" });
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
  if (url.pathname.startsWith("/api/")) return handleApi(req, res, url);
  serveStatic(req, res, url);
}).listen(PORT, "127.0.0.1", () => {
  console.log(`RicetteBuddy server su http://localhost:${PORT} (${recipes.length} ricette salvate)`);
});

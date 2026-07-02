// Parser reale delle ricette di GialloZafferano.
// Estrae: titolo, copertina, ingredienti, procedimento passo-passo con foto
// ALLINEATE ai passi (per posizione, come nella pagina), tempi, regimi, video.

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120 Safari/537.36";
const SITE = "https://www.giallozafferano.it";

async function fetchText(url) {
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
  return await res.text();
}

function jsonLdRecipe(html) {
  const re =
    /<script[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/gi;
  let m;
  while ((m = re.exec(html))) {
    let obj;
    try {
      obj = JSON.parse(m[1]);
    } catch {
      continue;
    }
    const arr = Array.isArray(obj) ? obj : obj["@graph"] || [obj];
    for (const it of arr) {
      const t = it && it["@type"];
      if (t === "Recipe" || (Array.isArray(t) && t.includes("Recipe"))) return it;
    }
  }
  return null;
}

function firstImage(img) {
  if (!img) return null;
  if (typeof img === "string") return img;
  if (Array.isArray(img)) return firstImage(img[0]);
  if (img.url) return img.url;
  return null;
}

function stripTags(s) {
  return s
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&#39;|&rsquo;|&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&agrave;/g, "à").replace(/&egrave;/g, "è").replace(/&eacute;/g, "é")
    .replace(/&igrave;/g, "ì").replace(/&ograve;/g, "ò").replace(/&ugrave;/g, "ù")
    .replace(/\s+/g, " ")
    .trim();
}

// Procedimento passo-passo con foto allineate per posizione nell'HTML.
function parseSteps(html) {
  const MARK = '<span class="num-step">';
  let sect = html;
  const last = html.lastIndexOf(MARK);
  const imgc = html.indexOf('<div class="gz-content-recipe-step-img');
  const h2 = html.search(/<h2[^>]*>\s*Preparazione/i);
  const start = imgc >= 0 ? imgc : h2 >= 0 ? h2 : html.indexOf(MARK);
  if (start >= 0 && last > start) sect = html.slice(start, last + 60);

  // Sostituisce ogni immagine dei passi con un token delimitato, così dopo lo
  // split sui marker num-step possiamo assegnare a ciascun passo la foto che
  // compare nel suo segmento (allineamento identico alla pagina originale).
  const T = "@@RBIMG@@";
  const withTokens = sect.replace(
    /<img[^>]+(?:src|data-src)="([^"]+\.jpe?g)"[^>]*>/gi,
    (_m, u) => T + (u.startsWith("http") ? u : SITE + u) + T,
  );

  const tokenRe = new RegExp(T + "([^@]+)" + T);
  const parts = withTokens.split(/<span class="num-step">(\d+)<\/span>/i);
  const steps = [];
  for (let k = 1; k < parts.length; k += 2) {
    const n = parseInt(parts[k], 10);
    const seg = parts[k - 1];
    const im = seg.match(tokenRe);
    const image = im ? im[1] : null;
    // rimuove i token immagine dal testo del passo
    const clean = seg.split(T).filter((_, i) => i % 2 === 0).join(" ");
    const text = stripTags(clean).replace(/^[\s.,;:!?]+/, "").trim();
    if (text.length < 2) continue;
    steps.push({ position: n - 1, text, image });
  }
  // fallback: nessun marker -> usa i <p>
  if (steps.length === 0) {
    const ps = [...sect.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/gi)]
      .map((x) => stripTags(x[1]))
      .filter((t) => t.length > 10);
    ps.forEach((t, i) => steps.push({ position: i, text: t, image: null }));
  }
  return steps;
}

function parseVideo(html) {
  const id = html.match(/data-videoid="([^"]+)"/);
  if (!id) return null;
  return { id: id[1], poster: `https://ptps.stbm.it/t/${id[1]}_large.jpg` };
}

const GLUTEN = ["farina", "pasta", "pane", "couscous", "cous cous", "farro",
  "orzo", "seitan", "pangrattato", "bulgur", "semola", "birra", "grano",
  "lasagne", "brioche", "biscotti"];

function classifyDiets(ingredients) {
  const diets = ["vegan", "vegetarian", "lactoseFree", "pescetarian"];
  const joined = ingredients.join(" ").toLowerCase();
  if (!GLUTEN.some((g) => joined.includes(g))) diets.push("glutenFree");
  return diets;
}

function parseISODuration(iso) {
  if (!iso) return null;
  const m = String(iso).match(/PT(?:(\d+)H)?(?:(\d+)M)?/);
  if (!m) return null;
  return parseInt(m[1] || 0, 10) * 60 + parseInt(m[2] || 0, 10);
}

async function parseRecipe(url) {
  const html = await fetchText(url);
  const ld = jsonLdRecipe(html);
  if (!ld) return null;
  const ingredients = (ld.recipeIngredient || []).map((s) => stripTags(String(s)));
  const steps = parseSteps(html);
  const video = parseVideo(html);
  return {
    title: stripTags(ld.name || "Ricetta"),
    image_url: firstImage(ld.image),
    source_url: url,
    source_type: "web",
    cook_minutes: parseISODuration(ld.totalTime),
    diet_tags: classifyDiets(ingredients),
    category: ld.recipeCategory || null,
    ingredients: ingredients.map((raw_text) => ({ raw_text })),
    steps,
    video_url: video ? video.poster : null,
    video_id: video ? video.id : null,
  };
}

// La ricerca vegana di GZ pagina con /ricerca-ricette/pageN/vegano/ (il numero
// pagina sta nel path, PRIMA del termine) e le ricette sono nei data-recipeurl.
async function listVeganUrls(maxPages) {
  const urls = [];
  for (let p = 1; p <= maxPages; p++) {
    const u = p === 1
      ? `${SITE}/ricerca-ricette/vegano/`
      : `${SITE}/ricerca-ricette/page${p}/vegano/`;
    let html;
    try {
      html = await fetchText(u);
    } catch {
      break;
    }
    const found = [
      ...html.matchAll(
        /data-recipeurl="(https:\/\/ricette\.giallozafferano\.it\/[A-Za-z0-9-]+\.html)"/g,
      ),
    ].map((x) => x[1]);
    const uniq = [...new Set(found)];
    if (uniq.length === 0) break;
    urls.push(...uniq);
  }
  return [...new Set(urls)];
}

module.exports = { parseRecipe, listVeganUrls };

if (require.main === module) {
  (async () => {
    for (const slug of ["Couscous-alle-verdure", "Zuppa-di-miso", "Lasagne-vegane"]) {
      const r = await parseRecipe(`https://ricette.giallozafferano.it/${slug}.html`);
      const wi = r.steps.filter((s) => s.image).length;
      console.log(`${r.title}: ${r.steps.length} passi, ${wi} con foto allineata, video:${r.video_id || "no"}`);
    }
  })();
}

// Importatore Pinterest (logica BOARD/PROFILO): usa un browser headless per
// elencare i pin della board, ne ricava il sito-ricetta collegato e importa la
// ricetta con un parser JSON-LD generico (schema.org/Recipe).
const { chromium } = require("playwright");

const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36";

function stripTags(s) {
  return String(s).replace(/<[^>]+>/g, "").replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&").replace(/&#39;|&rsquo;/g, "'").replace(/&quot;/g, '"')
    .replace(/\s+/g, " ").trim();
}

function jsonLdRecipe(html) {
  const re = /<script[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/gi;
  let m;
  while ((m = re.exec(html))) {
    let obj; try { obj = JSON.parse(m[1]); } catch { continue; }
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
function stepsFrom(v) {
  const out = [];
  const push = (t) => { const s = stripTags(t); if (s.length > 3) out.push(s); };
  const rec = (x) => {
    if (typeof x === "string") push(x);
    else if (Array.isArray(x)) x.forEach(rec);
    else if (x && x.text) push(x.text);
    else if (x && x.itemListElement) rec(x.itemListElement);
  };
  rec(v);
  return out.map((text, i) => ({ position: i, text, image: null }));
}

async function parseGenericRecipe(url) {
  const html = await (await fetch(url, { headers: { "User-Agent": UA } })).text();
  const ld = jsonLdRecipe(html);
  if (!ld) return null;
  const ingredients = (ld.recipeIngredient || []).map((s) => stripTags(s)).filter(Boolean);
  const steps = stepsFrom(ld.recipeInstructions);
  if (ingredients.length < 2 || steps.length < 1) return null;
  return {
    title: stripTags(ld.name || "Ricetta"),
    image_url: firstImage(ld.image),
    source_url: url,
    source_type: "social",
    cook_minutes: null,
    diet_tags: [],
    ingredients: ingredients.map((raw_text) => ({ raw_text })),
    steps,
    video_url: null, video_id: null, video_mp4: null,
  };
}

function extractSource(html) {
  const pats = [
    /"link":"(https?:\\?\/\\?\/[^"]+?)"/,
    /"tracked_link":"(https?:\\?\/\\?\/[^"]+?)"/,
  ];
  for (const p of pats) {
    const m = html.match(p);
    if (m) {
      const u = m[1].replace(/\\u002F/g, "/").replace(/\\\//g, "/").replace(/\\/g, "");
      if (!u.includes("pinterest.")) return u;
    }
  }
  return null;
}

async function listPins(boardUrl, max = 25) {
  const browser = await chromium.launch({ headless: true });
  try {
    const ctx = await browser.newContext({ userAgent: UA, locale: "it-IT", viewport: { width: 1280, height: 1600 } });
    const page = await ctx.newPage();
    await page.goto(boardUrl, { waitUntil: "domcontentloaded", timeout: 45000 });
    await page.waitForTimeout(3000);
    for (let i = 0; i < 5; i++) { await page.mouse.wheel(0, 3000); await page.waitForTimeout(1200); }
    const pins = await page.evaluate(() =>
      [...new Set([...document.querySelectorAll('a[href*="/pin/"]')].map((a) => a.href))]);
    return pins.slice(0, max);
  } finally { await browser.close(); }
}

async function importPinterest(reference) {
  let url = String(reference).trim();
  if (!/^https?:/.test(url)) url = `https://www.pinterest.com/${url.replace(/^@/, "")}/`;
  const pins = await listPins(url);
  if (pins.length === 0) throw new Error("Nessun pin trovato (board privata o URL errato).");
  const seen = new Set();
  const recipes = [];
  for (const p of pins) {
    if (recipes.length >= 15) break;
    try {
      const html = await (await fetch(p, { headers: { "User-Agent": UA } })).text();
      const src = extractSource(html);
      if (!src || seen.has(src)) continue;
      seen.add(src);
      const r = await parseGenericRecipe(src);
      if (r) recipes.push(r);
    } catch { /* salta */ }
  }
  return recipes;
}

module.exports = { importPinterest, parseGenericRecipe };

if (require.main === module) {
  const ref = process.argv[2] || "https://www.pinterest.it/giallozafferano/le-migliori-ricette-di-giallozafferano/";
  importPinterest(ref).then((rs) => {
    console.log("RICETTE DA PINTEREST:", rs.length);
    rs.slice(0, 6).forEach((r) => console.log(` ▶ ${r.title} | ingr:${r.ingredients.length} passi:${r.steps.length} | ${(r.source_url || "").slice(0, 50)}`));
  }).catch((e) => console.log("ERR", e.message));
}

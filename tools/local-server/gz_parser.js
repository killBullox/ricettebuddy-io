// Parser reale delle ricette di GialloZafferano.
// Estrae: titolo, copertina, ingredienti, procedimento passo-passo con foto,
// tempi, regimi (euristica), video (poster+id).

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

// Procedimento passo-passo: divide sul marker <span class="num-step">N</span>
// e associa la foto _N.jpg. Ritorna [{position, text, image}].
function parseSteps(html) {
  // Isola la sezione procedimento: dall'h2 "Preparazione" fino all'ultimo
  // marker num-step (i marker sono unici del procedimento).
  const MARK = '<span class="num-step">';
  let sect = html;
  const last = html.lastIndexOf(MARK);
  const imgc = html.indexOf('<div class="gz-content-recipe-step-img');
  const h2 = html.search(/<h2[^>]*>\s*Preparazione/i);
  const start = imgc >= 0 ? imgc : h2 >= 0 ? h2 : html.indexOf(MARK);
  if (start >= 0 && last > start) sect = html.slice(start, last + 60);

  // mappa numero->immagine dal nome file ..._N.jpg (nei vari percorsi /images/)
  const imgMap = {};
  const imgRe = /(?:src|data-src)="((?:https:\/\/www\.giallozafferano\.it)?\/images\/[^"]+?_(\d{1,3})\.jpg)"/gi;
  let im;
  while ((im = imgRe.exec(html))) {
    const n = parseInt(im[2], 10);
    if (n < 1 || n > 200) continue;
    const url = im[1].startsWith("http") ? im[1] : SITE + im[1];
    if (!imgMap[n]) imgMap[n] = url;
  }

  // dividi il testo sui marker num-step
  const parts = sect.split(/<span class="num-step">(\d+)<\/span>/i);
  // parts: [testo0, N1, testo1, N2, testo2, ...] dove testoK precede il marker N(K+1)
  const steps = [];
  for (let k = 1; k < parts.length; k += 2) {
    const n = parseInt(parts[k], 10);
    const text = stripTags(parts[k - 1]).replace(/^[\s.,;:!?]+/, "").trim();
    if (text.length < 2) continue;
    steps.push({ position: n - 1, text, image: imgMap[n] || null });
  }
  // fallback: se non trova marker, usa i <p> del blocco
  if (steps.length === 0) {
    const ps = [...sect.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/gi)]
      .map((x) => stripTags(x[1]))
      .filter((t) => t.length > 10);
    ps.forEach((t, i) => steps.push({ position: i, text: t, image: imgMap[i + 1] || null }));
  }
  return steps;
}

// Galleria foto del procedimento: tutte le immagini nei contenitori step
// (gestisce sia _N.jpg sia le "strip" delle ricette recenti).
function parseStepGallery(html) {
  const out = [];
  const re =
    /gz-content-recipe-step-img[\s\S]{0,200}?<img[^>]+src="([^"]+\.jpe?g)"/gi;
  let m;
  while ((m = re.exec(html))) {
    let u = m[1];
    if (u.startsWith("data:")) continue;
    if (!u.startsWith("http")) u = SITE + u;
    if (!out.includes(u)) out.push(u);
  }
  return out;
}

function parseVideo(html) {
  const id = html.match(/data-videoid="([^"]+)"/);
  if (!id) return null;
  return {
    id: id[1],
    poster: `https://ptps.stbm.it/t/${id[1]}_large.jpg`,
  };
}

const GLUTEN = ["farina", "pasta", "pane", "couscous", "cous cous", "farro",
  "orzo", "seitan", "pangrattato", "bulgur", "semola", "birra", "grano"];

function classifyDiets(ingredients) {
  // Dal listato vegane: vegano => anche vegetariano, senza lattosio, pescetariano.
  const diets = ["vegan", "vegetarian", "lactoseFree", "pescetarian"];
  const joined = ingredients.join(" ").toLowerCase();
  if (!GLUTEN.some((g) => joined.includes(g))) diets.push("glutenFree");
  return diets;
}

async function parseRecipe(url) {
  const html = await fetchText(url);
  const ld = jsonLdRecipe(html);
  if (!ld) return null;
  const ingredients = (ld.recipeIngredient || []).map((s) => stripTags(String(s)));
  const steps = parseSteps(html);
  const gallery = parseStepGallery(html);
  const video = parseVideo(html);
  const mins = parseISODuration(ld.totalTime);
  return {
    title: stripTags(ld.name || "Ricetta"),
    image_url: firstImage(ld.image),
    source_url: url,
    source_type: "web",
    cook_minutes: mins,
    diet_tags: classifyDiets(ingredients),
    category: ld.recipeCategory || null,
    ingredients: ingredients.map((raw_text) => ({ raw_text })),
    steps,
    step_gallery: gallery,
    video_url: video ? video.poster : null,
    video_id: video ? video.id : null,
  };
}

function parseISODuration(iso) {
  if (!iso) return null;
  const m = String(iso).match(/PT(?:(\d+)H)?(?:(\d+)M)?/);
  if (!m) return null;
  return (parseInt(m[1] || 0, 10) * 60) + parseInt(m[2] || 0, 10);
}

async function listVeganUrls(maxPages) {
  const urls = [];
  for (let p = 1; p <= maxPages; p++) {
    const u = p === 1
      ? `${SITE}/ricette-vegane/`
      : `${SITE}/ricette-vegane/?pagina=${p}`;
    let html;
    try {
      html = await fetchText(u);
    } catch {
      break;
    }
    const found = [
      ...html.matchAll(/https:\/\/ricette\.giallozafferano\.it\/[A-Za-z0-9-]+\.html/g),
    ].map((x) => x[0]);
    const uniq = [...new Set(found)];
    if (uniq.length === 0) break;
    urls.push(...uniq);
  }
  return [...new Set(urls)];
}

module.exports = { parseRecipe, listVeganUrls, classifyDiets };

// Test diretto: node gz_parser.js
if (require.main === module) {
  (async () => {
    const r = await parseRecipe(
      "https://ricette.giallozafferano.it/Couscous-alle-verdure.html",
    );
    console.log("TITOLO:", r.title);
    console.log("COPERTINA:", r.image_url);
    console.log("TEMPO:", r.cook_minutes, "min");
    console.log("REGIMI:", r.diet_tags.join(", "));
    console.log("INGREDIENTI:", r.ingredients.length, "es:", r.ingredients.slice(0, 3).map(i => i.raw_text));
    console.log("PASSAGGI:", r.steps.length);
    console.log("  step 1:", JSON.stringify(r.steps[0]));
    console.log("  step con foto:", r.steps.filter(s => s.image).length, "su", r.steps.length);
    console.log("VIDEO:", r.video_id, r.video_url);
  })();
}

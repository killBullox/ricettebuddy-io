// Parser reale delle ricette di GialloZafferano (Deno / Edge Functions).
// Stessa logica testata in tools/local-server/gz_parser.js: estrae titolo,
// copertina, ingredienti, procedimento passo-passo con foto ALLINEATE, tempi,
// regimi e video (poster + MP4 diretto).

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120 Safari/537.36";
const SITE = "https://www.giallozafferano.it";

export interface ParsedStep { position: number; text: string; image: string | null }
export interface ParsedRecipe {
  title: string;
  image_url: string | null;
  source_url: string;
  source_type: "web";
  cook_minutes: number | null;
  diet_tags: string[];
  category: string | null;
  ingredients: { raw_text: string }[];
  steps: ParsedStep[];
  video_url: string | null;
  video_id: string | null;
  video_mp4: string | null;
}

async function fetchText(url: string): Promise<string> {
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
  return await res.text();
}

// deno-lint-ignore no-explicit-any
function jsonLdRecipe(html: string): any | null {
  const re =
    /<script[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html))) {
    let obj: unknown;
    try {
      obj = JSON.parse(m[1]);
    } catch {
      continue;
    }
    // deno-lint-ignore no-explicit-any
    const arr: any[] = Array.isArray(obj)
      ? obj
      // deno-lint-ignore no-explicit-any
      : ((obj as any)["@graph"] || [obj]);
    for (const it of arr) {
      const t = it && it["@type"];
      if (t === "Recipe" || (Array.isArray(t) && t.includes("Recipe"))) return it;
    }
  }
  return null;
}

// deno-lint-ignore no-explicit-any
function firstImage(img: any): string | null {
  if (!img) return null;
  if (typeof img === "string") return img;
  if (Array.isArray(img)) return firstImage(img[0]);
  if (img.url) return img.url;
  return null;
}

function stripTags(s: string): string {
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

function parseSteps(html: string): ParsedStep[] {
  const MARK = '<span class="num-step">';
  let sect = html;
  const last = html.lastIndexOf(MARK);
  const imgc = html.indexOf('<div class="gz-content-recipe-step-img');
  const h2 = html.search(/<h2[^>]*>\s*Preparazione/i);
  const start = imgc >= 0 ? imgc : h2 >= 0 ? h2 : html.indexOf(MARK);
  if (start >= 0 && last > start) sect = html.slice(start, last + 60);

  const T = "@@RBIMG@@";
  const withTokens = sect.replace(
    /<img[^>]+(?:src|data-src)="([^"]+\.jpe?g)"[^>]*>/gi,
    (_m, u) => T + (u.startsWith("http") ? u : SITE + u) + T,
  );

  const tokenRe = new RegExp(T + "([^@]+)" + T);
  const parts = withTokens.split(/<span class="num-step">(\d+)<\/span>/i);
  const steps: ParsedStep[] = [];
  for (let k = 1; k < parts.length; k += 2) {
    const n = parseInt(parts[k], 10);
    const seg = parts[k - 1];
    const im = seg.match(tokenRe);
    const image = im ? im[1] : null;
    const clean = seg.split(T).filter((_, i) => i % 2 === 0).join(" ");
    const text = stripTags(clean).replace(/^[\s.,;:!?]+/, "").trim();
    if (text.length < 2) continue;
    steps.push({ position: n - 1, text, image });
  }
  if (steps.length === 0) {
    const ps = [...sect.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/gi)]
      .map((x) => stripTags(x[1]))
      .filter((t) => t.length > 10);
    ps.forEach((t, i) => steps.push({ position: i, text: t, image: null }));
  }
  return steps;
}

function parseVideoId(html: string): string | null {
  const id = html.match(/data-videoid="([^"]+)"/);
  return id ? id[1] : null;
}

async function videoMp4(id: string): Promise<string | null> {
  try {
    const r = await fetch(`https://ptp.stbm.it/v/${id}gzfg`, {
      headers: { "User-Agent": UA },
    });
    const t = await r.text();
    const m = t.match(/https:[^"\s]*?_alexa\.mp4/);
    return m ? m[0].replace(/\\/g, "") : null;
  } catch {
    return null;
  }
}

const GLUTEN = ["farina", "pasta", "pane", "couscous", "cous cous", "farro",
  "orzo", "seitan", "pangrattato", "bulgur", "semola", "birra", "grano",
  "lasagne", "brioche", "biscotti"];

function classifyDiets(ingredients: string[]): string[] {
  const diets = ["vegan", "vegetarian", "lactoseFree", "pescetarian"];
  const joined = ingredients.join(" ").toLowerCase();
  if (!GLUTEN.some((g) => joined.includes(g))) diets.push("glutenFree");
  return diets;
}

function parseISODuration(iso: string | undefined): number | null {
  if (!iso) return null;
  const m = String(iso).match(/PT(?:(\d+)H)?(?:(\d+)M)?/);
  if (!m) return null;
  return parseInt(m[1] || "0", 10) * 60 + parseInt(m[2] || "0", 10);
}

export async function parseRecipe(url: string): Promise<ParsedRecipe | null> {
  const html = await fetchText(url);
  const ld = jsonLdRecipe(html);
  if (!ld) return null;
  const ingredients = (ld.recipeIngredient || []).map((s: string) =>
    stripTags(String(s))
  );
  const steps = parseSteps(html);
  const vid = parseVideoId(html);
  const mp4 = vid ? await videoMp4(vid) : null;
  return {
    title: stripTags(ld.name || "Ricetta"),
    image_url: firstImage(ld.image),
    source_url: url,
    source_type: "web",
    cook_minutes: parseISODuration(ld.totalTime),
    diet_tags: classifyDiets(ingredients),
    category: ld.recipeCategory || null,
    ingredients: ingredients.map((raw_text: string) => ({ raw_text })),
    steps,
    video_url: vid ? `https://ptps.stbm.it/t/${vid}_large.jpg` : null,
    video_id: vid,
    video_mp4: mp4,
  };
}

export async function listVeganUrls(maxPages: number): Promise<string[]> {
  const urls: string[] = [];
  for (let p = 1; p <= maxPages; p++) {
    const u = p === 1
      ? `${SITE}/ricerca-ricette/vegano/`
      : `${SITE}/ricerca-ricette/page${p}/vegano/`;
    let html: string;
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

export function matchesDiets(recipeDiets: string[], active: string[]): boolean {
  return active.every((d) => (recipeDiets || []).includes(d));
}

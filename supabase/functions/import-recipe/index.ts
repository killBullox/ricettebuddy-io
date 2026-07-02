// Edge Function: import-recipe
// Scarica un URL, estrae schema.org/Recipe (JSON-LD) e restituisce una ricetta
// strutturata. Fallback: bozza con solo il link (da completare con structuring AI).
// Porting/estensione del JSONLDRecipeParser SwiftUI originale.
//
// Deploy:  supabase functions deploy import-recipe
// Invoke:  supabase.functions.invoke('import-recipe', body: { url })

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

interface OutRecipe {
  title: string;
  source_url: string;
  source_type: "web";
  original_language?: string;
  image_url?: string;
  ingredients: { raw_text: string }[];
  steps: { position: number; text: string }[];
}

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { url } = await req.json();
    if (!url || !/^https?:\/\//.test(url)) {
      return json({ error: "Link non valido." }, 400);
    }

    const html = await (await fetch(url, {
      headers: { "User-Agent": "RicetteBuddyBot/0.2 (+import)" },
    })).text();

    const recipe = parseJsonLd(html, url) ?? draft(url);
    return json(recipe, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

// --- Parsing JSON-LD ---------------------------------------------------------

function parseJsonLd(html: string, sourceURL: string): OutRecipe | null {
  for (const block of extractBlocks(html)) {
    let obj: unknown;
    try {
      obj = JSON.parse(block);
    } catch {
      continue;
    }
    const dict = findRecipe(obj);
    if (dict) return build(dict, sourceURL);
  }
  return null;
}

function extractBlocks(html: string): string[] {
  const re =
    /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  const out: string[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null) out.push(m[1].trim());
  return out;
}

// deno-lint-ignore no-explicit-any
function findRecipe(obj: any): any | null {
  if (Array.isArray(obj)) {
    for (const it of obj) {
      const f = findRecipe(it);
      if (f) return f;
    }
  } else if (obj && typeof obj === "object") {
    if (isRecipe(obj)) return obj;
    if (Array.isArray(obj["@graph"])) {
      for (const it of obj["@graph"]) {
        const f = findRecipe(it);
        if (f) return f;
      }
    }
  }
  return null;
}

// deno-lint-ignore no-explicit-any
function isRecipe(d: any): boolean {
  const t = d["@type"];
  if (typeof t === "string") return t === "Recipe";
  if (Array.isArray(t)) return t.includes("Recipe");
  return false;
}

// deno-lint-ignore no-explicit-any
function build(d: any, sourceURL: string): OutRecipe {
  const ingredients = (asArray(d.recipeIngredient) as string[])
    .filter((x) => typeof x === "string")
    .map((x) => ({ raw_text: decodeEntities(x) }));

  const steps = parseInstructions(d.recipeInstructions).map((text, i) => ({
    position: i,
    text: decodeEntities(text),
  }));

  return {
    title: decodeEntities(d.name ?? "Ricetta importata"),
    source_url: sourceURL,
    source_type: "web",
    original_language: typeof d.inLanguage === "string" ? d.inLanguage : undefined,
    image_url: firstImage(d.image),
    ingredients,
    steps,
  };
}

// deno-lint-ignore no-explicit-any
function parseInstructions(value: any): string[] {
  if (typeof value === "string") return [value];
  if (Array.isArray(value)) {
    const out: string[] = [];
    for (const it of value) {
      if (typeof it === "string") out.push(it);
      else if (it && typeof it.text === "string") out.push(it.text);
      // HowToSection -> itemListElement
      else if (it && Array.isArray(it.itemListElement)) {
        out.push(...parseInstructions(it.itemListElement));
      }
    }
    return out;
  }
  return [];
}

// deno-lint-ignore no-explicit-any
function firstImage(img: any): string | undefined {
  if (typeof img === "string") return img;
  if (Array.isArray(img)) return firstImage(img[0]);
  if (img && typeof img.url === "string") return img.url;
  return undefined;
}

// deno-lint-ignore no-explicit-any
function asArray(v: any): any[] {
  return Array.isArray(v) ? v : v == null ? [] : [v];
}

function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .trim();
}

function draft(url: string): OutRecipe {
  let host = url;
  try {
    host = new URL(url).host;
  } catch { /* keep url */ }
  return {
    title: host,
    source_url: url,
    source_type: "web",
    ingredients: [],
    steps: [],
  };
}

// Edge Function: import-recipe
// Importa una ricetta e la salva per l'utente autenticato, restituendola.
//  - { url }                       -> parsing JSON-LD (GialloZafferano e siti web)
//  - { text, title?, image_url?, source_url? } -> enrich AI (didascalia IG/social)
//
// L'estrazione della didascalia social avviene SUL DISPOSITIVO (SocialExtractor);
// qui il testo viene trasformato in ricetta vegana strutturata con l'AI. Nessuna
// dipendenza dal vecchio backend Node.
//
// Deploy:  supabase functions deploy import-recipe

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { parseRecipe } from "../_shared/gz.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

// Categorie del catalogo: l'AI sceglie la più vicina, così i filtri per portata
// funzionano anche sulle ricette importate.
const CATEGORIE = [
  "Antipasti e contorni", "Primi di pasta", "Riso e cereali", "Zuppe e minestre",
  "Legumi e secondi vegetali", "Lievitati, pane e pizza", "Dolci",
  "Medio Oriente e Nord Africa", "India e subcontinente", "Asia orientale e Sud Est",
  "Americhe", "Europa", "Africa subsahariana",
];

// Struttura normalizzata comune ai due rami, pronta per il salvataggio.
interface NormRecipe {
  title: string;
  image_url: string | null;
  source_url: string | null;
  source_type: string; // "web" | "social"
  category: string | null;
  cuisine: string | null;
  difficulty: string | null;
  servings: number | null;
  prep_minutes: number | null;
  cook_minutes: number | null;
  nutrition: Record<string, number> | null;
  diet_tags: string[];
  was_vegan: boolean | null;
  ingredients: { raw_text: string; normalized_name?: string | null }[];
  steps: { position: number; text: string; image?: string | null }[];
  video_url?: string | null;
  video_id?: string | null;
  video_mp4?: string | null;
}

async function enrichFromText(
  text: string,
  hintTitle: string | undefined,
): Promise<NormRecipe> {
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) throw new Error("ANTHROPIC_API_KEY mancante");
  const prompt =
    `Da questa didascalia/testo di un post di cucina, ricava una ricetta e ` +
    `rendila 100% VEGANA (sostituisci ogni ingrediente animale con un'alternativa ` +
    `vegetale sensata).\n\n` +
    (hintTitle ? `Titolo suggerito: ${hintTitle}\n` : "") +
    `Testo:\n"""${text.slice(0, 4000)}"""\n\n` +
    `Regole:\n` +
    `1. Ingredienti CON dose per le porzioni indicate (es. "200 g di tofu").\n` +
    `2. In OGNI passo ripeti la dose dell'ingrediente quando viene usato.\n` +
    `3. "nome" di ogni ingrediente = sostantivo pulito senza dose (es. "tofu").\n` +
    `4. nutrizione PER PORZIONE, realistica.\n` +
    `5. categoria: scegli la più vicina fra: ${CATEGORIE.join(" | ")}.\n` +
    `6. was_vegan = true se il piatto era già vegano, false se l'hai veganizzato.\n\n` +
    `Rispondi SOLO con JSON valido:\n` +
    `{"titolo":"...","categoria":"...","zona":"...","porzioni":4,"prep_min":15,` +
    `"cottura_min":20,"difficolta":"Facile|Media|Difficile","was_vegan":true,` +
    `"ingredienti":[{"testo":"...","nome":"..."}],"passi":["..."],` +
    `"nutrizione":{"kcal":0,"protein_g":0,"carbs_g":0,"fat_g":0,"fiber_g":0}}`;

  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": key,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: "claude-sonnet-5",
      max_tokens: 12000,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!r.ok) throw new Error(`Anthropic ${r.status}: ${await r.text()}`);
  const d = await r.json();
  const block = (d.content || []).find((b: { type: string }) => b.type === "text");
  if (!block) throw new Error(`Risposta AI senza testo (stop: ${d.stop_reason})`);
  const t = block.text as string;
  const a = t.indexOf("{"), b = t.lastIndexOf("}");
  if (a < 0 || b < a) throw new Error("Risposta AI non in JSON");
  let g: Record<string, unknown>;
  try { g = JSON.parse(t.slice(a, b + 1)); }
  catch { throw new Error(`JSON incompleto dall'AI (stop: ${d.stop_reason}). Riprova.`); }

  const ings = (g.ingredienti as { testo: string; nome?: string }[] | undefined) || [];
  const passi = (g.passi as string[] | undefined) || [];
  const n = (g.nutrizione as Record<string, number> | undefined) || {};
  return {
    title: String(g.titolo || hintTitle || "Ricetta"),
    image_url: null,
    source_url: null,
    source_type: "social",
    category: CATEGORIE.includes(String(g.categoria)) ? String(g.categoria) : null,
    cuisine: g.zona ? String(g.zona) : null,
    difficulty: g.difficolta ? String(g.difficolta) : null,
    servings: typeof g.porzioni === "number" ? g.porzioni : 2,
    prep_minutes: typeof g.prep_min === "number" ? g.prep_min : null,
    cook_minutes: typeof g.cottura_min === "number" ? g.cottura_min : null,
    nutrition: {
      kcal: +n.kcal || 0, protein_g: +n.protein_g || 0, carbs_g: +n.carbs_g || 0,
      fat_g: +n.fat_g || 0, fiber_g: +n.fiber_g || 0,
    },
    diet_tags: ["vegan"],
    was_vegan: typeof g.was_vegan === "boolean" ? g.was_vegan : null,
    ingredients: ings
      .filter((x) => x && x.testo)
      .map((x) => ({ raw_text: String(x.testo), normalized_name: x.nome ? String(x.nome) : null })),
    steps: passi
      .filter((p) => p && String(p).trim())
      .map((p, i) => ({ position: i, text: String(p).trim(), image: null })),
  };
}

// deno-lint-ignore no-explicit-any
async function saveRecipe(supabase: any, userId: string, r: NormRecipe) {
  const { data: inserted, error } = await supabase
    .from("recipes")
    .insert({
      user_id: userId,
      title: r.title,
      image_url: r.image_url,
      source_url: r.source_url,
      source_type: r.source_type,
      category: r.category,
      cuisine: r.cuisine,
      difficulty: r.difficulty,
      servings: r.servings ?? 2,
      prep_minutes: r.prep_minutes,
      cook_minutes: r.cook_minutes,
      nutrition: r.nutrition,
      diet_tags: r.diet_tags,
      video_url: r.video_url ?? null,
      video_id: r.video_id ?? null,
      video_mp4: r.video_mp4 ?? null,
    })
    .select("id, title")
    .single();
  if (error) throw error;
  const id = inserted.id;
  if (r.ingredients.length) {
    await supabase.from("ingredients").insert(
      r.ingredients.map((ing, i) => ({
        recipe_id: id, user_id: userId, position: i,
        raw_text: ing.raw_text, normalized_name: ing.normalized_name ?? null,
      })),
    );
  }
  if (r.steps.length) {
    await supabase.from("steps").insert(
      r.steps.map((s) => ({
        recipe_id: id, user_id: userId, position: s.position,
        text: s.text, image: s.image ?? null,
      })),
    );
  }
  return { id, title: inserted.title, duplicate: false };
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Solo POST" }, 405);
  try {
    const body = await req.json().catch(() => ({}));
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );
    const { data: userData } = await supabase.auth.getUser();
    if (!userData?.user) return json({ error: "Non autenticato" }, 401);

    let norm: NormRecipe | null = null;

    // Ramo TESTO (social/IG): enrich AI.
    const text = typeof body.text === "string" ? body.text.trim() : "";
    if (text.length >= 20) {
      norm = await enrichFromText(text, body.title);
      if (body.image_url) norm.image_url = String(body.image_url);
      if (body.source_url) norm.source_url = String(body.source_url);
    } else if (body.url && /^https?:\/\//.test(body.url)) {
      // Ramo URL: JSON-LD.
      const p = await parseRecipe(String(body.url));
      if (!p) return json({ error: "Ricetta non riconosciuta in questa pagina." }, 422);
      norm = {
        ...p,
        cuisine: null, difficulty: null, servings: null, prep_minutes: null,
        nutrition: null, was_vegan: null,
        ingredients: p.ingredients.map((x) => ({ raw_text: x.raw_text, normalized_name: null })),
      };
    } else {
      return json({ error: "Serve un link valido o il testo della ricetta." }, 400);
    }

    const saved = await saveRecipe(supabase, userData.user.id, norm);
    return json(saved, 201);
  } catch (e) {
    console.error("import-recipe", e);
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

// Arricchimento + veganizzazione lato server (per l'import dell'app).
// Prende una ricetta grezza (titolo, ingredienti, passi) e ritorna la ricetta
// pronta per l'app: se non vegana la veganizza, con nutrizione e classificazione.
const KEY = process.env.ANTHROPIC_API_KEY;
const MODEL = process.env.ENRICH_MODEL || "claude-sonnet-5";

const SYSTEM = `Sei uno chef vegano e nutrizionista. Ricevi una ricetta (titolo, ingredienti, procedimento). Devi:
1) capire se è GIÀ vegana (nessun ingrediente animale: carne, pesce, uova, latte/derivati, miele, ecc.);
2) se NON è vegana, VEGANIZZARLA con sostituzioni sensate e realistiche che mantengano gusto e tecnica;
3) restituire la ricetta finale strutturata e arricchita.
Rispondi SOLO con JSON valido:
{
  "was_vegan": boolean,
  "substitutions": [ {"original": string, "vegan": string, "note": string} ],
  "title": string,
  "servings": number,
  "prep_minutes": number|null,
  "cook_minutes": number|null,
  "ingredients": [ {"name": string, "quantity": number|null, "unit": "g"|"ml"|"pz"|null, "raw": string} ],
  "steps": [string],
  "nutrition_per_serving": {"kcal": number, "protein_g": number, "carbs_g": number, "fat_g": number, "fiber_g": number},
  "classification": {"category": string, "cuisine": string, "difficulty": "facile"|"media"|"difficile", "diet_tags": string[], "allergens": string[], "tags": string[]}
}
Regole: sostituzioni credibili (uova->aquafaba/lino; guanciale->tempeh/funghi affumicati; pecorino/parmigiano->lievito alimentare/parmigiano vegetale; panna->panna di soia/anacardi; burro->margarina/olio; miele->sciroppo d'acero). Adatta i passi. Ingredienti in grammi/ml. diet_tags sempre includa "vegan".`;

async function callClaude(input) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": KEY, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({ model: MODEL, max_tokens: 4096, system: SYSTEM, messages: [{ role: "user", content: input }] }),
  });
  const raw = await res.text();
  if (res.status !== 200) throw new Error(`Anthropic HTTP ${res.status}: ${raw.slice(0, 150)}`);
  const data = JSON.parse(raw);
  const block = (data.content || []).find((b) => b.type === "text");
  const t = block.text;
  return JSON.parse(t.slice(t.indexOf("{"), t.lastIndexOf("}") + 1));
}

// recipe = { title, ingredients:[{raw_text}], steps:[{text}], image_url, video_*... }
// Ritorna la ricetta arricchita in formato app (conserva media originali).
async function enrichRecipe(recipe) {
  if (!KEY) return recipe; // senza chiave, passa liscia
  const input = `Titolo: ${recipe.title}\n\nIngredienti:\n${(recipe.ingredients || []).map((i) => "- " + i.raw_text).join("\n")}\n\nProcedimento:\n${(recipe.steps || []).map((s, i) => `${i + 1}. ${s.text}`).join("\n")}`;
  const v = await callClaude(input);
  return {
    ...recipe,
    title: v.title || recipe.title,
    servings: v.servings || recipe.servings || 2,
    prep_minutes: v.prep_minutes,
    cook_minutes: v.cook_minutes ?? recipe.cook_minutes,
    ingredients: (v.ingredients || []).map((i, k) => ({
      position: k, raw_text: i.raw || i.name, quantity: i.quantity, unit: i.unit, normalized_name: i.name,
    })),
    steps: (v.steps || []).map((text, k) => ({ position: k, text })),
    diet_tags: (v.classification?.diet_tags || []),
    allergens: v.classification?.allergens || [],
    tags: v.classification?.tags || [],
    category: v.classification?.category || null,
    cuisine: v.classification?.cuisine || null,
    difficulty: v.classification?.difficulty || null,
    nutrition: v.nutrition_per_serving || null,
    was_vegan: v.was_vegan,
    substitutions: v.substitutions || [],
  };
}

module.exports = { enrichRecipe };

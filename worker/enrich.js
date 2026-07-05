// Arricchimento AI: didascalia grezza -> ricetta strutturata (procedimento,
// ingredienti in grammi, nutrizione, classificazione) via Claude.

const MODEL = process.env.ENRICH_MODEL || "claude-sonnet-5";
const KEY = process.env.ANTHROPIC_API_KEY;

const SYSTEM = `Sei un nutrizionista e chef. Ricevi la didascalia grezza di un post Instagram di una ricetta vegana (in italiano) e la trasformi in dati strutturati e puliti.
Rispondi SOLO con JSON valido, senza testo attorno, in questo schema:
{
  "is_recipe": boolean,                 // false se il post NON è una ricetta (promo, vlog...)
  "title": string,
  "servings": number,
  "prep_minutes": number|null,
  "cook_minutes": number|null,
  "ingredients": [ {"name": string, "quantity": number|null, "unit": "g"|"ml"|"pz"|null, "raw": string} ],
  "steps": [string],
  "nutrition_per_serving": {"kcal": number, "protein_g": number, "carbs_g": number, "fat_g": number, "fiber_g": number},
  "classification": {
    "category": string, "cuisine": string, "difficulty": "facile"|"media"|"difficile",
    "diet_tags": string[], "allergens": string[], "tags": string[]
  }
}
Regole: ingredienti in unità canoniche (grammi/ml dove possibile). "2 cucchiai olio"~20 ml, "1 tazza"~240 ml. Correggi refusi evidenti. Non inventare ingredienti assenti. Se non è una ricetta metti is_recipe=false e lascia gli altri campi vuoti.`;

async function enrichCaption(caption) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": KEY, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({
      model: MODEL, max_tokens: 4096, system: SYSTEM,
      messages: [{ role: "user", content: "Didascalia:\n\n" + String(caption).slice(0, 3500) }],
    }),
  });
  const raw = await res.text();
  if (res.status !== 200) throw new Error(`Anthropic HTTP ${res.status}: ${raw.slice(0, 200)}`);
  const data = JSON.parse(raw);
  const block = (data.content || []).find((b) => b.type === "text");
  if (!block) throw new Error("Nessun blocco testo nella risposta AI");
  const s = block.text.indexOf("{"), e = block.text.lastIndexOf("}");
  return JSON.parse(block.text.slice(s, e + 1));
}

module.exports = { enrichCaption };

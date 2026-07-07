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
  "title": string,   // nome del piatto BREVE e pulito, SENZA parentesi, descrizioni o slogan (es. "Carbonara Vegana", NON "Carbonara Vegana (autentica, a base vegetale)")
  "servings": number,
  "prep_minutes": number|null,
  "cook_minutes": number|null,
  "ingredients": [ {"name": string, "quantity": number|null, "unit": "g"|"ml"|"pz"|null, "raw": string} ],
  "steps": [string],
  "nutrition_per_serving": {"kcal": number, "protein_g": number, "carbs_g": number, "fat_g": number, "fiber_g": number},
  "classification": {"category": string, "cuisine": string, "difficulty": "facile"|"media"|"difficile", "diet_tags": string[], "allergens": string[], "tags": string[]}
}
Regole sostituzioni: credibili (uova->aquafaba/lino; guanciale->tempeh/funghi affumicati; pecorino/parmigiano->lievito alimentare/parmigiano vegetale; panna->panna di soia/anacardi; burro->margarina/olio; miele->sciroppo d'acero). Adatta i passi. diet_tags sempre includa "vegan".

LINGUA: scrivi TUTTO in ITALIANO — titolo, nomi ingredienti (sia "name" sia "raw"), passi, note delle sostituzioni, category, cuisine, tags. Se la ricetta di partenza è in un'altra lingua, TRADUCILA in italiano naturale e scorrevole (non lasciare parole in inglese o altre lingue).

UNITÀ DI MISURA: usa SEMPRE il sistema metrico. Converti ogni misura anglosassone/imperiale: cup/stick/oz/lb/pinch -> grammi o ml; fluid oz/tbsp/tsp -> ml (1 cucchiaio≈15 ml, 1 cucchiaino≈5 ml); °F -> °C; inch -> cm. Nei "steps" riporta le temperature in °C e le quantità in g/ml. Nel campo "unit" usa solo "g", "ml", "pz" oppure null. Nel campo "raw" scrivi la quantità in italiano con unità metrica (es. "200 g di tempeh", "2 cucchiai di olio d'oliva", "500 ml di brodo vegetale"); "name" è il nome pulito del prodotto in italiano (es. "tempeh", "olio d'oliva").

PASSAGGI CON QUANTITÀ: OGNI volta che nomini un ingrediente in un passaggio, mettici accanto la sua quantità/numero — SENZA ECCEZIONI. Questo vale anche per gli ingredienti a unità intera o frazionaria (scrivi "1 cetriolo", "1 peperone", "1 avocado", "mezza cipolla rossa", "1 spicchio d'aglio"), non solo per grammi e ml. Se in un passaggio elenchi più ingredienti insieme, metti la quantità accanto a CIASCUNO (es. "unisci 150 g di fagioli, 200 g di pomodorini, 1 cetriolo a cubetti e 1 peperone a listarelle"). Se lo stesso ingrediente compare in più passaggi con quantità diverse, ripartisci e specifica ogni volta (es. step 2 "100 g di farina", step 5 "i restanti 50 g di farina"): la somma per ingrediente deve corrispondere al totale in "ingredients". Unica cosa che puoi omettere: gli ingredienti a piacere/q.b. (sale, pepe, prezzemolo). Mantieni i passi scorrevoli, ma NON tralasciare mai una quantità.`;

async function callClaudeOnce(input) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": KEY, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({ model: MODEL, max_tokens: 8192, system: SYSTEM, messages: [{ role: "user", content: input }] }),
  });
  const raw = await res.text();
  if (res.status !== 200) throw new Error(`Anthropic HTTP ${res.status}: ${raw.slice(0, 150)}`);
  const data = JSON.parse(raw);
  const block = (data.content || []).find((b) => b.type === "text");
  const t = block.text;
  // Il modello a volte produce JSON leggermente malformato: riprovo (campione
  // diverso) invece di fallire.
  return JSON.parse(t.slice(t.indexOf("{"), t.lastIndexOf("}") + 1));
}

async function callClaude(input, tries = 3) {
  let lastErr;
  for (let k = 0; k < tries; k++) {
    try { return await callClaudeOnce(input); }
    catch (e) { lastErr = e; }
  }
  throw lastErr;
}

// recipe = { title, ingredients:[{raw_text}], steps:[{text}], image_url, video_*... }
// Ritorna la ricetta arricchita in formato app (conserva media originali).
// Titolo pulito: via eventuali parentesi/descrizioni finali aggiunte dall'AI.
function cleanTitle(t) {
  return String(t || "").replace(/\s*[\(\[][^)\]]*[\)\]]\s*$/g, "").trim() || String(t || "").trim();
}

async function enrichRecipe(recipe) {
  if (!KEY) return recipe; // senza chiave, passa liscia
  const input = `Titolo: ${recipe.title}\n\nIngredienti:\n${(recipe.ingredients || []).map((i) => "- " + i.raw_text).join("\n")}\n\nProcedimento:\n${(recipe.steps || []).map((s, i) => `${i + 1}. ${s.text}`).join("\n")}`;
  const v = await callClaude(input);
  return {
    ...recipe,
    title: cleanTitle(v.title || recipe.title),
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

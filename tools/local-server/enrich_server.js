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
  "ingredients": [ {"name": string, "quantity": number|null, "unit": "g"|"ml"|"pz"|null, "raw": string, "img": string} ],
  "steps": [string],
  "nutrition_per_serving": {"kcal": number, "protein_g": number, "carbs_g": number, "fat_g": number, "fiber_g": number},
  "co2_saved_kg": number,
  "classification": {"category": string, "cuisine": string, "difficulty": "facile"|"media"|"difficile", "diet_tags": string[], "allergens": string[], "tags": string[]}
}

IMPATTO CO2: "co2_saved_kg" = stima dei kg di CO2e RISPARMIATI PER PORZIONE scegliendo questa versione vegetale invece di un equivalente tradizionale a base animale. Usa fattori realistici (per kg di alimento): manzo ~20, agnello ~20, formaggio ~9, maiale ~7, pollo ~6, uova ~4.5, pesce ~5, latte/panna ~1.5; legumi/tofu/verdure/cereali ~0.5-2. Calcola la differenza sulle porzioni animali sostituite. Se la ricetta era GIÀ vegana, stima comunque il risparmio rispetto a un piatto analogo a base animale. Numero positivo con 1-2 decimali (es. 1.8).
Regole sostituzioni: credibili (uova->aquafaba/lino; guanciale->tempeh/funghi affumicati; pecorino/parmigiano->lievito alimentare/parmigiano vegetale; panna->panna di soia/anacardi; burro->margarina/olio; miele->sciroppo d'acero). Adatta i passi. diet_tags sempre includa "vegan".

FOTO INGREDIENTE ("img"): per OGNI ingrediente metti il nome INGLESE comune per la foto, minuscolo, SINGOLARE, con trattini tra le parole, nello stile della libreria Spoonacular (es. cipolla rossa->"red-onion", olio d'oliva->"olive-oil", pomodori->"tomato", farina->"flour", aglio->"garlic", zucchine->"zucchini", ceci->"chickpeas", basilico->"basil", menta->"mint", tofu->"tofu", latte di soia->"soy-milk", lievito alimentare->"nutritional-yeast", passata di pomodoro->"tomato-sauce"). Usa il termine generico più comune (non marche).
IMPORTANTE: traduci SEMPRE il nome COMPOSTO INTERO, mai solo la prima parola: burro di cacao->"cocoa-butter" (NON "butter"), bacca/baccello di vaniglia->"vanilla-bean" (NON "berry"), latte di cocco->"coconut-milk" (NON "milk"), farina di ceci->"chickpea-flour" (NON "flour"), aceto di riso->"rice-vinegar", zucchero a velo->"powdered-sugar", cioccolato bianco->"white-chocolate". Il significato dell'ingrediente sta nell'insieme, non nella testa del nome.

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

function buildInput(recipe) {
  return `Titolo: ${recipe.title}\n\nIngredienti:\n${(recipe.ingredients || []).map((i) => "- " + i.raw_text).join("\n")}\n\nProcedimento:\n${(recipe.steps || []).map((s, i) => `${i + 1}. ${s.text}`).join("\n")}`;
}

// --- Validazione foto ingrediente ---------------------------------------
// La libreria Spoonacular non ha tutti gli slug: verifichiamo che la foto
// ESISTA. Fallback: prova senza la parola-testa (vanilla-bean -> vanilla);
// MAI la sola testa (butter per cocoa-butter darebbe una foto sbagliata).
// Se niente esiste -> null (l'app mostra l'emoji, mai una foto errata).
const IMG_BASE = "https://img.spoonacular.com/ingredients_250x250/";
const _imgCache = new Map(); // slug -> filename|null

async function _imgExists(file) {
  try { const r = await fetch(IMG_BASE + file, { method: "HEAD" }); return r.ok; }
  catch { return false; }
}

async function resolveImg(slug) {
  const s = String(slug || "").toLowerCase().trim();
  if (!s) return null;
  if (_imgCache.has(s)) return _imgCache.get(s);
  const tries = [s];
  const parts = s.split("-");
  if (parts.length > 1) tries.push(parts.slice(0, -1).join("-")); // via la testa
  let found = null;
  outer: for (const t of tries) {
    for (const ext of ["jpg", "png"]) {
      if (await _imgExists(`${t}.${ext}`)) { found = `${t}.${ext}`; break outer; }
    }
  }
  _imgCache.set(s, found);
  return found;
}

async function resolveIngredientImages(ingredients) {
  await Promise.all((ingredients || []).map(async (i) => {
    i.img = await resolveImg(i.img);
  }));
  return ingredients;
}

function mapEnrich(recipe, v) {
  return {
    ...recipe,
    title: cleanTitle(v.title || recipe.title),
    servings: v.servings || recipe.servings || 2,
    prep_minutes: v.prep_minutes,
    cook_minutes: v.cook_minutes ?? recipe.cook_minutes,
    ingredients: (v.ingredients || []).map((i, k) => ({
      position: k, raw_text: i.raw || i.name, quantity: i.quantity, unit: i.unit,
      normalized_name: i.name, img: i.img || null,
    })),
    steps: (v.steps || []).map((text, k) => ({ position: k, text })),
    diet_tags: (v.classification?.diet_tags || []),
    allergens: v.classification?.allergens || [],
    tags: v.classification?.tags || [],
    category: v.classification?.category || null,
    cuisine: v.classification?.cuisine || null,
    difficulty: v.classification?.difficulty || null,
    nutrition: v.nutrition_per_serving || null,
    co2_saved_kg: typeof v.co2_saved_kg === "number" ? v.co2_saved_kg : null,
    was_vegan: v.was_vegan,
    substitutions: v.substitutions || [],
  };
}

async function enrichRecipe(recipe) {
  if (!KEY) return recipe; // senza chiave, passa liscia
  const v = await callClaude(buildInput(recipe));
  const out = mapEnrich(recipe, v);
  await resolveIngredientImages(out.ingredients);
  return out;
}

// Come enrichRecipe ma in STREAMING: chiama [onPhase] mano a mano che i campi
// vengono davvero generati dall'AI (was_vegan -> ingredients -> steps ->
// nutrition -> co2), così le fasi mostrate seguono il processo REALE.
async function enrichRecipeStream(recipe, onPhase) {
  if (!KEY) return recipe;
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": KEY, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({
      model: MODEL, max_tokens: 8192, system: SYSTEM, stream: true,
      messages: [{ role: "user", content: buildInput(recipe) }],
    }),
  });
  if (!res.ok || !res.body) {
    // fallback non-streaming
    return enrichRecipe(recipe);
  }
  const KEYS = [
    ['"was_vegan"', "analyzing"],
    ['"ingredients"', "ingredients"],
    ['"steps"', "steps"],
    ['"nutrition_per_serving"', "nutrition"],
    ['"co2_saved_kg"', "co2"],
  ];
  let acc = "";       // testo JSON della ricetta (dai delta)
  let sseBuf = "";    // buffer per righe SSE spezzate tra chunk
  const seen = new Set();
  for await (const chunk of res.body) {
    sseBuf += Buffer.isBuffer(chunk) ? chunk.toString() : Buffer.from(chunk).toString();
    let nl;
    while ((nl = sseBuf.indexOf("\n")) >= 0) {
      const line = sseBuf.slice(0, nl);
      sseBuf = sseBuf.slice(nl + 1);
      if (!line.startsWith("data:")) continue;
      const d = line.slice(5).trim();
      if (!d || d === "[DONE]") continue;
      let ev; try { ev = JSON.parse(d); } catch { continue; }
      const t = ev.type === "content_block_delta" && ev.delta && ev.delta.text;
      if (!t) continue;
      acc += t;
      for (const [tok, phase] of KEYS) {
        if (!seen.has(tok) && acc.includes(tok)) { seen.add(tok); try { onPhase(phase); } catch {} }
      }
    }
  }
  const v = JSON.parse(acc.slice(acc.indexOf("{"), acc.lastIndexOf("}") + 1));
  const out = mapEnrich(recipe, v);
  await resolveIngredientImages(out.ingredients);
  return out;
}

module.exports = { enrichRecipe, enrichRecipeStream };

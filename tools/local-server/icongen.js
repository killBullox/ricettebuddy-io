// Genera icone SVG per ingredienti via Claude e le mette in cache su file
// (icons.json). Stessa "chiave ingrediente" -> stessa icona, sempre (consistenza).
// Usato quando un ingrediente non ha un'emoji adatta.
const fs = require("fs");
const path = require("path");

const KEY = process.env.ANTHROPIC_API_KEY;
const MODEL = process.env.ICON_MODEL || "claude-sonnet-5";
const DB = path.join(__dirname, "icons.json");

const SYSTEM = `Sei un icon designer. Disegni icone alimentari minimali e RICONOSCIBILI in SVG.
Stile OBBLIGATORIO e coerente per tutte:
- viewBox="0 0 48 48", nessun testo, nessun <image>.
- forme piene semplici (flat), 2-3 colori max, palette naturale dell'ingrediente.
- soggetto centrato, margine ~4px, tratti spessi, leggibile a 32px.
- niente ombre, niente gradienti complessi.
Rispondi SOLO con il markup <svg ...>...</svg>, nient'altro.`;

let cache = {};
try { cache = JSON.parse(fs.readFileSync(DB, "utf8")); } catch { cache = {}; }
const persist = () => fs.writeFileSync(DB, JSON.stringify(cache));

// Unità/quantità/parole di contorno da togliere per ricavare il "nome pulito"
// dell'ingrediente, così ricette diverse riusano la stessa icona.
const UNIT_RE =
  /\b(g|gr|grammi?|kg|ml|cl|dl|l|litr\w*|cucchiai\w*|tazz\w*|q\.?\s?b\.?|pizzic\w*|spicch\w*|fogli\w*|foglie|ramett\w*|manciat\w*|fett\w*|pezz\w*|confezion\w*|barattol\w*|lattin\w*|mazzett\w*|noce|scatol\w*|bicchier\w*|circa|qualche)\b/gi;
const STOP_RE =
  /\b(di|de|d|del|della|dello|dei|degli|delle|al|allo|alla|ai|agli|un|una|uno|lo|la|le|gli|il|i|fresc[oaie]|tritat[oaie]|macinat[oaie]|in|polvere|a|piacere|per|con|e|ed|extra|vergine|bio|q|b)\b/gi;

/// Ricava la chiave di cache normalizzata da una riga ingrediente grezza.
function iconKey(raw) {
  let s = String(raw || "").toLowerCase();
  s = s.replace(/\([^)]*\)/g, " ");                 // via parentesi
  s = s.replace(/[0-9]+([.,/][0-9]+)?/g, " ");       // via numeri
  s = s.replace(/[½¼¾⅓⅔⅛]/g, " ");                   // via frazioni unicode
  s = s.replace(UNIT_RE, " ");
  s = s.replace(STOP_RE, " ");
  s = s.replace(/[^a-zà-ù\s]/g, " ");
  s = s.replace(/\s+/g, " ").trim();
  // massimo 3 parole significative
  return s.split(" ").filter(Boolean).slice(0, 3).join(" ");
}

async function generate(name) {
  if (!KEY) throw new Error("ANTHROPIC_API_KEY mancante");
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 1500,
      system: SYSTEM,
      messages: [{ role: "user", content: `Icona per: ${name}` }],
    }),
  });
  const data = JSON.parse(await res.text());
  const t = (data.content || []).find((b) => b.type === "text")?.text || "";
  const m = t.match(/<svg[\s\S]*<\/svg>/i);
  if (!m) throw new Error("nessun SVG generato");
  return m[0];
}

/// Ritorna l'SVG (dalla cache o generandolo). `null` in caso di errore.
async function iconSvg(raw) {
  const key = iconKey(raw);
  if (!key) return null;
  if (cache[key]) return cache[key];
  const svg = await generate(key);
  cache[key] = svg;
  persist();
  return svg;
}

module.exports = { iconSvg, iconKey };

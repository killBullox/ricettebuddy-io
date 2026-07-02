// Importatore Instagram interno (senza servizi a pagamento).
// Usa l'endpoint pubblico web_profile_info (una sola chiamata restituisce gli
// ultimi ~12 post con didascalia, foto e video). La didascalia è testo libero:
// un estrattore euristico ne ricava titolo, ingredienti e passaggi.

const APP_ID = "936619743392459";
const UAS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
];

function handleOf(reference) {
  return String(reference).replace(/^@/, "").trim()
    .replace(/^https?:\/\/(www\.)?instagram\.com\//i, "").replace(/\/.*$/, "");
}

async function fetchProfile(handle) {
  for (let i = 0; i < 3; i++) {
    const host = i % 2 ? "i.instagram.com" : "www.instagram.com";
    try {
      const r = await fetch(
        `https://${host}/api/v1/users/web_profile_info/?username=${handle}`,
        { headers: { "User-Agent": UAS[i % 2], "x-ig-app-id": APP_ID, "Accept": "application/json" } },
      );
      const t = await r.text();
      if (t.startsWith("{")) return JSON.parse(t);
    } catch { /* retry */ }
    if (i < 2) await new Promise((res) => setTimeout(res, 2500));
  }
  throw new Error(
    "Instagram ha bloccato temporaneamente le richieste. Riprova tra 5-10 minuti " +
    "(succede se si fanno troppe richieste ravvicinate).",
  );
}

// --- Estrattore ricetta dalla didascalia -----------------------------------

const ING_HDR = /(^|\s)(ingredienti|ingredients|ti servono|serve|serviranno)\b/i;
const STEP_HDR = /(^|\s)(procedimento|preparazione|come si (fa|prepara)|passaggi|esecuzione|come fare|instructions|method)\b/i;

function cleanLine(s) {
  return s.replace(/\s+/g, " ").trim();
}

function isHashtagLine(s) {
  const words = s.trim().split(/\s+/);
  return words.length > 0 && words.every((w) => w.startsWith("#"));
}

function parseCaption(caption) {
  const raw = caption.replace(/\r/g, "");
  // rimuovi il blocco finale di soli hashtag
  const lines = raw.split("\n").map((l) => l.replace(/\s+$/, ""));
  const kept = [];
  for (const l of lines) {
    if (isHashtagLine(l) && kept.length > 3) continue; // salta code di hashtag
    kept.push(l);
  }
  const nonEmpty = kept.map(cleanLine).filter((l) => l.length > 0);

  const title = (nonEmpty[0] || "Ricetta da Instagram")
    .replace(/[#@]\S+/g, "").replace(/^[^A-Za-zÀ-ÿ0-9]+/, "").slice(0, 90).trim() ||
    "Ricetta da Instagram";

  const ingIdx = nonEmpty.findIndex((l) => ING_HDR.test(l));
  const stepIdx = nonEmpty.findIndex((l) => STEP_HDR.test(l));

  let ingredients = [];
  let steps = [];
  if (ingIdx >= 0) {
    const end = stepIdx > ingIdx ? stepIdx : nonEmpty.length;
    ingredients = nonEmpty.slice(ingIdx + 1, end)
      .map((l) => l.replace(/^[-•*·▪️➡️👉\s]+/, "").trim())
      .filter((l) => l.length > 1 && !STEP_HDR.test(l));
  }
  if (stepIdx >= 0) {
    steps = nonEmpty.slice(stepIdx + 1)
      .map((l) => l.replace(/^[-•*·▪️➡️👉\d).\s]+/, "").trim())
      .filter((l) => l.length > 2);
  }
  // Fallback: nessuna sezione riconosciuta -> tutta la didascalia come testo.
  if (ingredients.length === 0 && steps.length === 0) {
    steps = [nonEmpty.slice(1).join(" ").slice(0, 1500)].filter((s) => s.length > 5);
  }
  return { title, ingredients, steps };
}

function postToRecipe(node, handle) {
  const cap = node.edge_media_to_caption?.edges?.[0]?.node?.text || "";
  if (cap.length < 40) return null; // scarta post senza testo utile
  const parsed = parseCaption(cap);
  const shortcode = node.shortcode;
  return {
    title: parsed.title,
    image_url: node.display_url || null,
    source_url: `https://www.instagram.com/p/${shortcode}/`,
    source_type: "social",
    cook_minutes: null,
    diet_tags: [], // dai social non classifichiamo il regime
    ingredients: parsed.ingredients.map((raw_text) => ({ raw_text })),
    steps: parsed.steps.map((text, i) => ({ position: i, text, image: null })),
    video_url: node.is_video ? (node.display_url || null) : null,
    video_id: node.is_video ? shortcode : null,
    video_mp4: node.is_video ? (node.video_url || null) : null,
  };
}

async function importInstagram(reference) {
  const handle = handleOf(reference);
  const j = await fetchProfile(handle);
  const user = j?.data?.user;
  if (!user) throw new Error(`Profilo @${handle} non trovato.`);
  if (user.is_private) throw new Error(`Il profilo @${handle} è privato.`);
  const edges = user.edge_owner_to_timeline_media?.edges || [];
  return edges.map((e) => postToRecipe(e.node, handle)).filter(Boolean);
}

module.exports = { importInstagram, parseCaption, handleOf };

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
  let lastErr = "";
  for (let i = 0; i < 3; i++) {
    try {
      const r = await fetch(
        `https://www.instagram.com/api/v1/users/web_profile_info/?username=${handle}`,
        {
          headers: {
            "User-Agent": UAS[0],
            "x-ig-app-id": APP_ID,
            "Accept": "*/*",
            "Referer": `https://www.instagram.com/${handle}/`,
            // Instagram esige gli header Sec-Fetch da browser reale,
            // altrimenti risponde "SecFetch Policy violation".
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "sec-ch-ua": '"Not_A Brand";v="8", "Chromium";v="120"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Windows"',
          },
        },
      );
      const t = await r.text();
      if (t.startsWith("{")) return JSON.parse(t);
      lastErr = `${r.status} ${t.slice(0, 60)}`;
    } catch (e) {
      lastErr = String(e).slice(0, 80);
    }
    if (i < 2) await new Promise((res) => setTimeout(res, 2500));
  }
  throw new Error(`Instagram non risponde (${lastErr}). Riprova tra qualche minuto.`);
}

// --- Estrattore ricetta dalla didascalia -----------------------------------
// Le didascalie sono testo libero: euristiche per riconoscere i post che sono
// davvero ricette, e per separare ingredienti (righe con quantità) e passaggi.

const ING_HDR = /^\s*[^\w]*\s*(ingredienti|ingredients|cosa (ti )?serve|ti servono|occorrente)\b/i;
const STEP_HDR = /^\s*[^\w]*\s*(procedimento|preparazione|come si (fa|prepara)|passaggi|esecuzione|come fare|instructions|method)\b/i;
// quantità: "200 g", "2 cucchiai", "1/2 tazza", "q.b.", "500ml", "3 uova"
const QTY = /(\b\d+([.,/]\d+)?\s*(g|gr|kg|ml|cl|l|cucchia\w*|tazz\w*|bicchier\w*|pizzic\w*|fett\w*|spicch\w*|foglie?|rametti?|uova|uovo)\b)|(\bq\.?\s?b\.?\b)/i;
// righe promozionali/CTA da scartare sempre
const CTA = /(scrivi\s.*comment|nei commenti|link in bio|seguim\w|salva (il|questo)|condividi|preordin\w|in libreria|codice sconto|shop|iscrivit\w|taggam\w|dimmi nei|ricettario|il mio libro)/i;

function cleanLine(s) {
  return s.replace(/\s+/g, " ").trim();
}

function isHashtagLine(s) {
  const words = s.trim().split(/\s+/);
  return words.length > 0 && words.every((w) => w.startsWith("#") || w.startsWith("@"));
}

function captionLines(caption) {
  return caption.replace(/\r/g, "").split("\n")
    .map(cleanLine)
    .filter((l) => l.length > 0 && !isHashtagLine(l) && !CTA.test(l));
}

/// Il post è una ricetta? Serve un header ingredienti o >=3 righe con quantità.
function looksLikeRecipe(caption) {
  const lines = captionLines(caption);
  if (lines.some((l) => ING_HDR.test(l))) return true;
  return lines.filter((l) => QTY.test(l)).length >= 3;
}

function extractTitle(lines) {
  let t = lines[0] || "Ricetta da Instagram";
  t = t.replace(/[#@]\S+/g, "").replace(/^[^A-Za-zÀ-ÿ0-9]+/, "").trim();
  // taglia alla prima frase o a 60 caratteri (i titoli veri sono corti)
  const dot = t.search(/[.!?:]/);
  if (dot > 8) t = t.slice(0, dot);
  if (t.length > 60) t = t.slice(0, 60).replace(/\s+\S*$/, "") + "…";
  return t || "Ricetta da Instagram";
}

function parseCaption(caption) {
  const lines = captionLines(caption);
  const title = extractTitle(lines);

  const ingIdx = lines.findIndex((l) => ING_HDR.test(l));
  const stepIdx = lines.findIndex((l) => STEP_HDR.test(l));

  let ingredients = [];
  let steps = [];

  if (ingIdx >= 0) {
    // sezione esplicita: dall'header fino all'header passaggi (o fine quantità)
    const end = stepIdx > ingIdx ? stepIdx : lines.length;
    ingredients = lines.slice(ingIdx + 1, end)
      .map((l) => l.replace(/^[-•*·▪️✔️☑️➡️👉🔸🔹\s]+/u, "").trim())
      .filter((l) => l.length > 1 && (QTY.test(l) || l.length < 60));
  } else {
    // nessun header: le righe con quantità sono ingredienti
    ingredients = lines.filter((l) => QTY.test(l) && l.length < 100)
      .map((l) => l.replace(/^[-•*·▪️✔️☑️➡️👉🔸🔹\s]+/u, "").trim());
  }

  if (stepIdx >= 0) {
    steps = lines.slice(stepIdx + 1)
      .map((l) => l.replace(/^[-•*·▪️➡️👉\s]*\d*[).:]?\s*/u, "").trim())
      .filter((l) => l.length > 15 && !QTY.test(l));
  } else {
    // nessun header: i passaggi sono le frasi lunghe non-ingrediente dopo il titolo
    const body = lines.slice(1)
      .filter((l) => !QTY.test(l) && l.length > 25 && !ING_HDR.test(l));
    steps = body.flatMap((p) => p.split(/(?<=[.!?])\s+/))
      .map((s) => s.trim())
      .filter((s) => s.length > 20)
      .slice(0, 12);
  }

  return { title, ingredients, steps };
}

function postToRecipe(node) {
  const cap = node.edge_media_to_caption?.edges?.[0]?.node?.text || "";
  if (cap.length < 60) return null; // niente testo utile
  if (!looksLikeRecipe(cap)) return null; // post non-ricetta (promo, vlog, ...)
  const parsed = parseCaption(cap);
  if (parsed.ingredients.length < 2) return null; // troppo povero per essere utile
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
  return edges.map((e) => postToRecipe(e.node)).filter(Boolean);
}

module.exports = { importInstagram, parseCaption, handleOf };

// Recupero post pubblici Instagram (una chiamata = ultimi ~12 post).
const APP_ID = "936619743392459";
const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36";

// Instagram blocca gli IP datacenter (VPS -> HTTP 429). Le richieste IG vanno
// instradate su un PROXY RESIDENZIALE. Imposta IG_PROXY (es.
// http://user:pass@host:porta). Se assente, va diretto (ok solo da IP residenziale).
let dispatcher = null;
if (process.env.IG_PROXY) {
  try {
    const { ProxyAgent } = require("undici");
    dispatcher = new ProxyAgent(process.env.IG_PROXY);
  } catch (e) {
    console.error("Proxy non inizializzato:", e.message);
  }
}

async function fetchProfile(handle) {
  let last = "";
  for (let i = 0; i < 3; i++) {
    try {
      const r = await fetch(
        `https://www.instagram.com/api/v1/users/web_profile_info/?username=${handle}`,
        {
          dispatcher: dispatcher || undefined,
          headers: {
            "User-Agent": UA, "x-ig-app-id": APP_ID, "Accept": "*/*",
            "Referer": `https://www.instagram.com/${handle}/`,
            "Sec-Fetch-Site": "same-origin", "Sec-Fetch-Mode": "cors", "Sec-Fetch-Dest": "empty",
            "sec-ch-ua": '"Not_A Brand";v="8", "Chromium";v="120"',
            "sec-ch-ua-mobile": "?0", "sec-ch-ua-platform": '"Windows"',
          },
        },
      );
      const t = await r.text();
      if (t.startsWith("{")) return JSON.parse(t);
      last = `HTTP ${r.status}`;
    } catch (e) { last = String(e.message || e); }
    if (i < 2) await new Promise((res) => setTimeout(res, 2500));
  }
  throw new Error(`Instagram non risponde (${last}). Serve un proxy residenziale se sei su VPS.`);
}

// Un post sembra una ricetta? header ingredienti o >=3 righe con quantità.
const QTY = /\b\d+([.,/]\d+)?\s*(g|gr|kg|ml|cl|l|cucchia|tazz|bicchier|spicch|foglie|uova|uovo)\b/i;
function looksLikeRecipe(caption) {
  if (/ingredienti|ingredients/i.test(caption)) return true;
  return (caption.split("\n").filter((l) => QTY.test(l)).length) >= 3;
}

async function recentPosts(handle) {
  const j = await fetchProfile(handle);
  const user = j?.data?.user;
  if (!user) throw new Error(`Profilo @${handle} non trovato.`);
  if (user.is_private) throw new Error(`Profilo @${handle} privato.`);
  return (user.edge_owner_to_timeline_media?.edges || []).map((e) => {
    const n = e.node;
    return {
      shortcode: n.shortcode,
      caption: n.edge_media_to_caption?.edges?.[0]?.node?.text || "",
      image: n.display_url || null,
      isVideo: !!n.is_video,
      videoUrl: n.video_url || null,
      url: `https://www.instagram.com/p/${n.shortcode}/`,
    };
  });
}

module.exports = { recentPosts, looksLikeRecipe };

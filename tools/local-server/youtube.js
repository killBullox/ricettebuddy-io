// Importatore YouTube (video e Shorts). Usa l'API interna "InnerTube" (client
// MWEB): a differenza dello scraping della pagina watch, non incappa nel muro
// di consenso/anti-bot che YouTube mostra agli IP da datacenter (il VPS).
// Prende titolo + descrizione (la ricetta). Se la descrizione è vuota — tipico
// negli Shorts, ricetta PARLATA — ripiega sui SOTTOTITOLI (trascrizione).
// Il testo va poi all'enrich AI per ingredienti+passi, veganizzazione, ecc.

const UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) " +
  "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile Safari/604.1";
const INNERTUBE_KEY = "AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"; // chiave pubblica del client web

function videoId(url) {
  const m = String(url).match(
    /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|shorts\/|embed\/|live\/))([A-Za-z0-9_-]{6,})/i);
  return m ? m[1] : null;
}

function decodeEntities(s) {
  return String(s)
    .replace(/&amp;/g, "&")
    .replace(/&#39;/g, "'").replace(/&#039;/g, "'").replace(/&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(+n))
    .replace(/&nbsp;/g, " ");
}

// Cookie di una sessione YouTube loggata (facoltativi): da IP datacenter YouTube
// mostra "Accedi per confermare di non essere un bot"; i cookie lo evitano.
// Impostare YT_COOKIE nel .env (stringa "NAME=VAL; NAME2=VAL2; ...").
const YT_COOKIE = (process.env.YT_COOKIE || "").trim();

// Chiama l'API player di YouTube col client MWEB (passa dal gate anti-bot).
async function innertubePlayer(id) {
  const headers = { "Content-Type": "application/json", "User-Agent": UA };
  if (YT_COOKIE) headers["Cookie"] = YT_COOKIE;
  const r = await fetch(
    `https://www.youtube.com/youtubei/v1/player?key=${INNERTUBE_KEY}&prettyPrint=false`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        context: { client: { clientName: "MWEB", clientVersion: "2.20240726.00.00", hl: "it", gl: "IT" } },
        videoId: id,
      }),
    });
  if (!r.ok) throw new Error(`InnerTube ${r.status}`);
  const j = await r.json();
  const st = j.playabilityStatus && j.playabilityStatus.status;
  if (st === "LOGIN_REQUIRED" || st === "ERROR") {
    throw new Error(YT_COOKIE
      ? "YouTube ha rifiutato la richiesta (cookie scaduti?)."
      : "YouTube blocca le richieste da questo server (serve un cookie di sessione).");
  }
  return j;
}

// Scarica la trascrizione da una lista di captionTracks (preferenza it > en).
async function fetchTranscript(tracks) {
  if (!Array.isArray(tracks) || !tracks.length) return "";
  const pick = tracks.find((t) => /^it/i.test(t.languageCode)) ||
    tracks.find((t) => /^en/i.test(t.languageCode)) || tracks[0];
  const baseUrl = pick && pick.baseUrl;
  if (!baseUrl) return "";
  const r = await fetch(baseUrl, { headers: { "User-Agent": UA } });
  const xml = await r.text();
  const parts = [...xml.matchAll(/<text[^>]*>([\s\S]*?)<\/text>/g)]
    .map((x) => decodeEntities(x[1]));
  return parts.join(" ").replace(/\s+/g, " ").trim();
}

// API UFFICIALE YouTube Data v3 (chiave gratuita in YT_API_KEY): stabile, senza
// bot-gate. Restituisce titolo + descrizione + thumbnail. È la via preferita.
const YT_API_KEY = (process.env.YT_API_KEY || "").trim();
async function officialApi(id) {
  const r = await fetch(
    `https://www.googleapis.com/youtube/v3/videos?part=snippet&id=${id}&key=${YT_API_KEY}`);
  if (!r.ok) throw new Error(`YouTube API ${r.status}`);
  const j = await r.json();
  const sn = j.items && j.items[0] && j.items[0].snippet;
  if (!sn) throw new Error("Video YouTube non trovato.");
  const t = sn.thumbnails || {};
  const image = (t.maxres || t.high || t.medium || t.default || {}).url ||
    `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;
  return { title: sn.title || "Ricetta da YouTube", desc: sn.description || "", image, captions: [] };
}

async function importYouTube(url) {
  const id = videoId(url);
  if (!id) throw new Error("Link YouTube non riconosciuto.");

  // 1) API ufficiale se configurata (stabile), altrimenti 2) InnerTube MWEB.
  let title, desc, image, captions;
  if (YT_API_KEY) {
    ({ title, desc, image, captions } = await officialApi(id));
  } else {
    const j = await innertubePlayer(id);
    const vd = j.videoDetails || {};
    title = vd.title || "Ricetta da YouTube";
    desc = vd.shortDescription || "";
    const thumbs = (vd.thumbnail && vd.thumbnail.thumbnails) || [];
    image = thumbs.length ? thumbs[thumbs.length - 1].url
      : `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;
    captions = (j.captions && j.captions.playerCaptionsTracklistRenderer &&
      j.captions.playerCaptionsTracklistRenderer.captionTracks) || [];
  }

  let text;
  if (desc.trim().length >= 40) {
    text = `${title}\n\n${desc}`;
  } else {
    // Descrizione assente (Shorts): ripiega sui sottotitoli/trascrizione.
    const transcript = await fetchTranscript(captions).catch(() => "");
    if (transcript && transcript.length >= 80) {
      text = `${title}\n\n(Trascrizione parlata del video)\n${transcript}`;
    } else {
      throw new Error("Il video YouTube non ha una ricetta nella descrizione " +
        "né sottotitoli leggibili da cui ricavarla.");
    }
  }

  return {
    title: title.slice(0, 80),
    image_url: image,
    source_url: `https://www.youtube.com/watch?v=${id}`,
    source_type: "social",
    cook_minutes: null,
    diet_tags: [],
    ingredients: [],
    steps: [{ position: 0, text }],
    video_url: null,
    video_id: id,
    video_mp4: null,
  };
}

module.exports = { importYouTube };

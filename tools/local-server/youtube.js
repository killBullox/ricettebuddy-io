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

// Chiama l'API player di YouTube col client MWEB (passa dal gate anti-bot).
async function innertubePlayer(id) {
  const r = await fetch(
    `https://www.youtube.com/youtubei/v1/player?key=${INNERTUBE_KEY}&prettyPrint=false`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "User-Agent": UA },
      body: JSON.stringify({
        context: { client: { clientName: "MWEB", clientVersion: "2.20240726.00.00", hl: "it", gl: "IT" } },
        videoId: id,
      }),
    });
  if (!r.ok) throw new Error(`InnerTube ${r.status}`);
  return r.json();
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

async function importYouTube(url) {
  const id = videoId(url);
  if (!id) throw new Error("Link YouTube non riconosciuto.");

  const j = await innertubePlayer(id);
  const vd = j.videoDetails || {};
  const title = vd.title || "Ricetta da YouTube";
  const desc = vd.shortDescription || "";
  const thumbs = (vd.thumbnail && vd.thumbnail.thumbnails) || [];
  const image = thumbs.length ? thumbs[thumbs.length - 1].url
    : `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;

  let text;
  if (desc.trim().length >= 40) {
    text = `${title}\n\n${desc}`;
  } else {
    // Descrizione assente (Shorts): ripiega sui sottotitoli/trascrizione.
    const caps = j.captions &&
      j.captions.playerCaptionsTracklistRenderer &&
      j.captions.playerCaptionsTracklistRenderer.captionTracks;
    const transcript = await fetchTranscript(caps || []).catch(() => "");
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

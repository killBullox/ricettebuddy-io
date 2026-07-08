// Importatore YouTube (video e Shorts). La ricetta si prende dalla descrizione
// (campo "shortDescription" del player). Se la descrizione è vuota — tipico
// negli Shorts, dove la ricetta è PARLATA — si ripiega sui SOTTOTITOLI
// (trascrizione), che poi l'enrich AI trasforma in ingredienti+passi.

const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120 Safari/537.36";

function videoId(url) {
  const m = String(url).match(
    /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|shorts\/|embed\/|live\/))([A-Za-z0-9_-]{6,})/i);
  return m ? m[1] : null;
}

function jsonStr(raw) {
  try { return JSON.parse('"' + raw + '"'); } catch { return raw; }
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

// Estrae la trascrizione (sottotitoli) dal player HTML. Preferisce IT, poi EN,
// poi la prima traccia disponibile (anche auto-generata).
async function fetchTranscript(html) {
  const m = html.match(/"captionTracks":(\[[\s\S]*?\}\])/);
  if (!m) return "";
  let tracks;
  try {
    tracks = JSON.parse(m[1].replace(/\\u0026/g, "&").replace(/\\"/g, '"').replace(/\\\//g, "/"));
  } catch { return ""; }
  if (!Array.isArray(tracks) || !tracks.length) return "";
  const pick = tracks.find((t) => /^it/i.test(t.languageCode)) ||
    tracks.find((t) => /^en/i.test(t.languageCode)) || tracks[0];
  let baseUrl = pick && pick.baseUrl;
  if (!baseUrl) return "";
  baseUrl = baseUrl.replace(/\\u0026/g, "&").replace(/\\\//g, "/");
  const r = await fetch(baseUrl, { headers: { "User-Agent": UA } });
  const xml = await r.text();
  const parts = [...xml.matchAll(/<text[^>]*>([\s\S]*?)<\/text>/g)]
    .map((x) => decodeEntities(x[1]));
  return parts.join(" ").replace(/\s+/g, " ").trim();
}

async function importYouTube(url) {
  const id = videoId(url);
  if (!id) throw new Error("Link YouTube non riconosciuto.");
  const r = await fetch(`https://www.youtube.com/watch?v=${id}`, {
    headers: { "User-Agent": UA, "Accept-Language": "it,en;q=0.9" },
  });
  const html = await r.text();

  const tm = html.match(/"title":"((?:[^"\\]|\\.)*?)","lengthSeconds"/) ||
    html.match(/<meta[^>]+property="og:title"[^>]+content="([^"]*)"/i);
  const dm = html.match(/"shortDescription":"((?:[^"\\]|\\.)*)"/);
  const im = html.match(/<meta[^>]+property="og:image"[^>]+content="([^"]*)"/i);

  const title = tm ? jsonStr(tm[1]) : "Ricetta da YouTube";
  const desc = dm ? jsonStr(dm[1]) : "";

  let text;
  if (desc.trim().length >= 40) {
    // Titolo + descrizione: entrambi utili all'AI per ricostruire la ricetta.
    text = `${title}\n\n${desc}`;
  } else {
    // Descrizione assente (Shorts): ripiego sui sottotitoli/trascrizione.
    const transcript = await fetchTranscript(html).catch(() => "");
    if (transcript && transcript.length >= 80) {
      text = `${title}\n\n(Trascrizione parlata del video)\n${transcript}`;
    } else {
      throw new Error("Il video YouTube non ha una ricetta nella descrizione " +
        "né sottotitoli leggibili da cui ricavarla.");
    }
  }

  return {
    title: title.slice(0, 80),
    image_url: im ? im[1] : `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
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

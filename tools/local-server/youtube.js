// Importatore YouTube (video e Shorts). La descrizione completa è nell'HTML
// della pagina watch (campo "shortDescription" del player), accessibile senza
// login. La passiamo all'enrich per estrarre ingredienti+passi, veganizzare,
// tradurre e mettere le quantità.

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
  if (desc.trim().length < 40) {
    throw new Error("La descrizione del video YouTube è troppo corta o assente " +
      "(il creator non ha scritto la ricetta nella descrizione).");
  }
  // Titolo + descrizione: entrambi utili all'AI per ricostruire la ricetta.
  const text = `${title}\n\n${desc}`;
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

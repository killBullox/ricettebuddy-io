// Importatore TikTok. La pagina video reindirizza al login in headless, ma
// l'endpoint pubblico oEmbed restituisce la didascalia completa (campo "title")
// senza login. La passiamo all'enrich (estrae ingredienti+passi, veganizza,
// traduce, mette le quantità).

const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120 Safari/537.36";

// Risolve i link brevi (vm.tiktok.com, tiktok.com/t/...) nell'URL canonico.
async function resolveUrl(url) {
  if (/\/video\/\d+/.test(url)) return url;
  try {
    const r = await fetch(url, { headers: { "User-Agent": UA }, redirect: "follow" });
    if (r.url && /tiktok\.com/i.test(r.url)) return r.url.split("?")[0];
  } catch { /* ignora */ }
  return url;
}

async function importTikTok(url) {
  const target = await resolveUrl(url);
  const r = await fetch(
    "https://www.tiktok.com/oembed?url=" + encodeURIComponent(target),
    { headers: { "User-Agent": UA } });
  const t = await r.text();
  if (!t.startsWith("{")) {
    throw new Error("TikTok non raggiungibile o video non pubblico.");
  }
  const j = JSON.parse(t);
  const caption = (j.title || "").trim();
  if (caption.length < 40) {
    throw new Error("La didascalia del video TikTok è troppo corta o assente " +
      "(il creator non ha scritto la ricetta nella descrizione).");
  }
  const idm = String(target).match(/video\/(\d+)/);
  const firstLine = caption.split("\n").map((s) => s.trim())
    .find((s) => s.length > 0) || "Ricetta da TikTok";
  return {
    title: firstLine.replace(/[#@]\S+/g, "").slice(0, 70).trim() || "Ricetta da TikTok",
    image_url: j.thumbnail_url || null,
    source_url: target,
    source_type: "social",
    cook_minutes: null,
    diet_tags: [],
    ingredients: [],
    steps: [{ position: 0, text: caption }],
    video_url: null,
    video_id: idm ? idm[1] : null,
    video_mp4: null,
  };
}

module.exports = { importTikTok };

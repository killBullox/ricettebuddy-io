// Importatore Facebook (reel/video/post pubblici) basato su yt-dlp: estrae
// titolo, didascalia COMPLETA e thumbnail senza login — funziona anche da IP
// datacenter (VPS). È lo stesso approccio delle app concorrenti.
const { execFile } = require("child_process");

const YTDLP = process.env.YTDLP_PATH || "yt-dlp";

function ytdlpJson(url) {
  return new Promise((resolve, reject) => {
    execFile(
      YTDLP,
      ["--no-warnings", "--skip-download", "--dump-json", url],
      { timeout: 90000, maxBuffer: 32 * 1024 * 1024 },
      (err, stdout) => {
        if (err) return reject(new Error("yt-dlp: " + String(err.message || err).slice(0, 200)));
        try { resolve(JSON.parse(stdout)); }
        catch (e) { reject(new Error("yt-dlp JSON: " + e.message)); }
      }
    );
  });
}

// Estrae il contenuto del post: {title, text, image_url, source_url}.
async function extractFacebook(url) {
  const j = await ytdlpJson(url);
  const desc = String(j.description || "").trim();
  // j.title è tipo "78K views · 618 reactions | <didascalia> | <autore>":
  // preferiamo la description (didascalia completa e pulita).
  const caption = desc.length >= 40 ? desc : String(j.title || "").trim();
  if (caption.length < 40) {
    throw new Error("Il post Facebook non contiene una didascalia leggibile.");
  }
  const firstLine = caption.split("\n").map((s) => s.trim())
    .find((s) => s.length > 0) || "Ricetta da Facebook";
  return {
    title: firstLine.replace(/[#@]\S+/g, "").slice(0, 70).trim() || "Ricetta da Facebook",
    text: caption,
    image_url: j.thumbnail || null,
    source_url: j.webpage_url || url,
  };
}

// Formato "ricetta grezza" per la route /api/import-url (poi passa all'enrich).
async function importFacebookPost(url) {
  const p = await extractFacebook(url);
  return {
    title: p.title,
    image_url: p.image_url,
    source_url: p.source_url,
    source_type: "social",
    cook_minutes: null,
    diet_tags: [],
    ingredients: [],
    steps: [{ position: 0, text: p.text }],
    video_url: null,
    video_id: null,
    video_mp4: null,
  };
}

module.exports = { importFacebookPost, extractFacebook };

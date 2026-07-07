// Importatore Facebook (reel/video/post pubblici). Facebook mostra un muro di
// login, ma la didascalia completa del reel è nel meta og:title della pagina.
// La leggiamo con un browser headless e la passiamo all'enrich (che estrae
// ingredienti+passi, veganizza, traduce, mette le quantità).

const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120 Safari/537.36";

async function fetchMeta(url) {
  const { getBrowser } = require("./browser.js"); // browser condiviso, riusato
  const b = await getBrowser();
  const ctx = await b.newContext({ userAgent: UA, locale: "it-IT" });
  try {
    const page = await ctx.newPage();
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 40000 })
      .catch(() => {});
    await page.waitForTimeout(3000);
    return await page.evaluate(() => {
      const g = (p) => document.querySelector(`meta[property="${p}"]`)?.content ||
        document.querySelector(`meta[name="${p}"]`)?.content || null;
      return {
        ogTitle: g("og:title"),
        ogDesc: g("og:description"),
        ogImage: g("og:image"),
        href: location.href,
      };
    });
  } finally {
    await ctx.close(); // chiude solo il context; il browser resta vivo
  }
}

// og:title dei reel: "Visualizzazioni: X · Reazioni: Y | <DIDASCALIA> | <Autore>"
function cleanCaption(ogTitle) {
  if (!ogTitle) return null;
  let s = ogTitle;
  s = s.replace(/^\s*Visualizzazioni:[^|]*\|\s*/i, "");      // prefisso statistiche (IT)
  s = s.replace(/^\s*[\d.,\sKkMm]+(visualizzazioni|views|reactions|reazioni)[^|]*\|\s*/i, "");
  s = s.replace(/\s*\|\s*[^|]{1,60}$/, "");                   // suffisso autore
  return s.trim();
}

async function importFacebookPost(url) {
  const { ogTitle, ogDesc, ogImage, href } = await fetchMeta(url);
  const caption = cleanCaption(ogTitle) || (ogDesc || "").trim();
  if (!caption || caption.length < 40) {
    throw new Error("Non riesco a leggere la didascalia del post Facebook " +
      "(privato, solo video senza testo, o rimosso).");
  }
  const firstLine = caption.split("\n").map((s) => s.trim())
    .find((s) => s.length > 0) || "Ricetta da Facebook";
  const idm = String(href || url).match(/(?:reel|videos?|posts?)\/(\d+)/i);
  return {
    title: firstLine.replace(/[#@]\S+/g, "").slice(0, 70).trim() || "Ricetta da Facebook",
    image_url: ogImage || null,
    source_url: /facebook\.com\/reel/i.test(href || "") ? href : url,
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

module.exports = { importFacebookPost };

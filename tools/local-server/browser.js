// Browser headless condiviso: lo lanciamo UNA volta e lo riusiamo per tutti gli
// import social (Instagram, Facebook, ...). Ogni import usa un context isolato
// che viene chiuso a fine lavoro; il browser resta vivo -> import più veloci
// (si risparmia il costo di avvio ~2-3s per ogni ricetta).
let _browser = null;

async function getBrowser() {
  const { chromium } = require("playwright"); // require pigro
  if (_browser) {
    try {
      if (_browser.isConnected()) return _browser;
    } catch { /* rilancio sotto */ }
  }
  _browser = await chromium.launch({ headless: true });
  return _browser;
}

module.exports = { getBrowser };

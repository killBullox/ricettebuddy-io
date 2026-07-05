// BeetIt — worker di ingest+arricchimento.
// Legge i creator monitorati, prende i loro post Instagram recenti, scarta i
// non-ricetta, arricchisce con l'AI e scrive nel catalogo globale Supabase.
//
// Uso:  node index.js --once   (un ciclo)   |   node index.js  (loop continuo)

try { require("dotenv").config(); } catch { /* dotenv opzionale */ }
const { createClient } = require("@supabase/supabase-js");
const { recentPosts, looksLikeRecipe } = require("./ig.js");
const { enrichCaption } = require("./enrich.js");

const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE, {
  auth: { persistSession: false },
});

const INTERVAL_MIN = parseInt(process.env.INTERVAL_MIN || "360", 10); // ogni 6h
const SEED = (process.env.SEED_CREATORS || "fabiolavegmamy").split(",").map((s) => s.trim()).filter(Boolean);

const log = (...a) => console.log(new Date().toISOString(), ...a);

async function ensureCreators() {
  const { data } = await db.from("creators").select("id").limit(1);
  if (data && data.length) return;
  for (const h of SEED) {
    await db.from("creators").upsert({ platform: "instagram", handle: h }, { onConflict: "platform,handle" });
  }
  log("seed creators:", SEED.join(", "));
}

async function existingUrls(urls) {
  if (!urls.length) return new Set();
  const { data } = await db.from("recipes").select("source_url").in("source_url", urls);
  return new Set((data || []).map((r) => r.source_url));
}

async function insertRecipe(enr, post, creator) {
  const { data: rec, error } = await db.from("recipes").insert({
    user_id: null,
    title: enr.title,
    image_url: post.image,
    source_url: post.url,
    source_type: "social",
    platform: "instagram",
    creator: creator.handle,
    servings: enr.servings || 2,
    prep_minutes: enr.prep_minutes,
    cook_minutes: enr.cook_minutes,
    category: enr.classification?.category,
    cuisine: enr.classification?.cuisine,
    difficulty: enr.classification?.difficulty,
    diet_tags: enr.classification?.diet_tags || [],
    allergens: enr.classification?.allergens || [],
    tags: enr.classification?.tags || [],
    nutrition: enr.nutrition_per_serving || null,
    video_url: post.isVideo ? post.image : null,
    video_id: post.isVideo ? post.shortcode : null,
    video_mp4: post.isVideo ? post.videoUrl : null,
  }).select("id").single();
  if (error) throw error;
  const id = rec.id;

  const ings = (enr.ingredients || []).filter((i) => i.name);
  if (ings.length) {
    await db.from("ingredients").insert(ings.map((i, k) => ({
      recipe_id: id, user_id: null, position: k,
      raw_text: i.raw || i.name, quantity: i.quantity, unit: i.unit, normalized_name: i.name,
    })));
  }
  const steps = (enr.steps || []).filter(Boolean);
  if (steps.length) {
    await db.from("steps").insert(steps.map((t, k) => ({
      recipe_id: id, user_id: null, position: k, text: t,
    })));
  }
  return id;
}

async function processCreator(creator) {
  let posts;
  try {
    posts = await recentPosts(creator.handle);
  } catch (e) {
    log(`  @${creator.handle}: ${e.message}`);
    return 0;
  }
  const candidates = posts.filter((p) => p.caption.length > 60 && looksLikeRecipe(p.caption));
  const already = await existingUrls(candidates.map((p) => p.url));
  let added = 0;
  for (const p of candidates) {
    if (already.has(p.url)) continue;
    try {
      const enr = await enrichCaption(p.caption);
      if (!enr.is_recipe || !(enr.ingredients || []).length) continue;
      await insertRecipe(enr, p, creator);
      added++;
      log(`  + ${enr.title}`);
    } catch (e) {
      log(`  ! errore su ${p.url}: ${String(e.message || e).slice(0, 120)}`);
    }
  }
  await db.from("creators").update({ last_checked_at: new Date().toISOString() }).eq("id", creator.id);
  return added;
}

async function cycle() {
  await ensureCreators();
  const { data: creators } = await db.from("creators").select("*").eq("active", true);
  log(`ciclo: ${creators.length} creator`);
  let total = 0;
  for (const c of creators) {
    log(`@${c.handle}...`);
    total += await processCreator(c);
    await new Promise((r) => setTimeout(r, 4000)); // gentile con IG
  }
  log(`ciclo finito: ${total} ricette nuove aggiunte al catalogo`);
}

(async () => {
  const once = process.argv.includes("--once");
  do {
    try { await cycle(); } catch (e) { log("errore ciclo:", e.message); }
    if (!once) await new Promise((r) => setTimeout(r, INTERVAL_MIN * 60 * 1000));
  } while (!once);
  if (once) process.exit(0);
})();

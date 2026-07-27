// Sync settimanale del catalogo cibi vegani pronti da Open Food Facts.
// Invocata dal cron (pg_cron -> pg_net) con header x-sync-secret.
// Scarica i prodotti vegani venduti in Italia (server .net, basic auth off:off)
// e li fa upsert in packaged_foods. Idempotente: on_conflict=code.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SYNC_SECRET = Deno.env.get('SYNC_SECRET') || '';

const OFF = 'https://world.openfoodfacts.net';
const OFF_AUTH = 'Basic ' + btoa('off:off');
const UA = 'BeetIt/1.0 (gianluca.davino@gmail.com)';
const FIELDS =
  'code,product_name,product_name_it,brands,quantity,image_front_url,image_url,categories,nutriments,nova_group,nutriscore_grade';

const num = (v: unknown): number | null => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.round(n * 10) / 10 : null;
};

// Marche 100% vegetali: OFF spesso non tagga "vegan" i loro prodotti, quindi
// vanno presi per marca (a prescindere dall'etichetta).
const VEGAN_BRANDS = ['kioene', 'valsoia', 'vemondo', 'amo-essere-veg', 'verso-natura-veg', 'mopur'];

async function getUrl(u: string, tries = 4): Promise<any[]> {
  for (let a = 0; a < tries; a++) {
    try {
      const r = await fetch(u, { headers: { 'User-Agent': UA, Authorization: OFF_AUTH } });
      if (!r.ok) { if (a < tries - 1) { await new Promise((s) => setTimeout(s, 2500 * (a + 1))); continue; } return []; }
      return (await r.json()).products || [];
    } catch { if (a < tries - 1) await new Promise((s) => setTimeout(s, 2500 * (a + 1))); }
  }
  return [];
}
const getPage = (sort: string, page: number) =>
  getUrl(`${OFF}/api/v2/search?labels_tags_en=vegan&countries_tags_en=italy&fields=${FIELDS}&sort_by=${sort}&page_size=100&page=${page}`);
const getBrandPage = (brand: string, page: number) =>
  getUrl(`${OFF}/api/v2/search?brands_tags=${brand}&countries_tags_en=italy&fields=${FIELDS}&page_size=100&page=${page}`);

function toRow(p: any) {
  const name = (p.product_name_it || p.product_name || '').trim();
  if (name.length < 2 || !p.code) return null;
  const nu = p.nutriments || {};
  let nova: number | null = parseInt(p.nova_group, 10);
  if (!Number.isFinite(nova)) nova = null;
  return {
    code: String(p.code).trim(),
    name: name.slice(0, 200),
    brand: (p.brands || '').slice(0, 120) || null,
    quantity: (p.quantity || '').slice(0, 60) || null,
    categories: (p.categories || '').slice(0, 300) || null,
    image_url: p.image_front_url || p.image_url || null,
    nutrition: {
      kcal: num(nu['energy-kcal_100g']), protein_g: num(nu.proteins_100g),
      carbs_g: num(nu.carbohydrates_100g), fat_g: num(nu.fat_100g),
      fiber_g: num(nu.fiber_100g), sugars_g: num(nu.sugars_100g), salt_g: num(nu.salt_100g),
    },
    nova_group: nova,
    nutriscore: (p.nutriscore_grade || '').slice(0, 2) || null,
    source: 'off',
  };
}

Deno.serve(async (req) => {
  // Solo il cron (o una chiamata con il segreto) puo' avviare il sync.
  if (SYNC_SECRET && req.headers.get('x-sync-secret') !== SYNC_SECRET) {
    return new Response('forbidden', { status: 403 });
  }
  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  const seen = new Set<string>();
  let added = 0;

  try {
    // Sync settimanale LEGGERO (entro i limiti dell'Edge Function): prende i
    // prodotti PIÙ RECENTI (per beccare le novità) e i più diffusi (aggiorna i
    // dati di quelli già noti). L'upsert non duplica. Il backfill completo del
    // catalogo storico si fa a parte, da uno script senza limiti di tempo.
    const flush = async (prods: any[]) => {
      const rows: any[] = [];
      for (const p of prods) {
        const row = toRow(p);
        if (!row || seen.has(row.code)) continue;
        seen.add(row.code); rows.push(row);
      }
      if (rows.length) {
        const { error } = await admin.from('packaged_foods')
          .upsert(rows, { onConflict: 'code', ignoreDuplicates: false });
        if (!error) added += rows.length;
      }
    };
    // 1) prodotti taggati vegan: piu' recenti + piu' diffusi
    for (const sort of ['created_t', 'unique_scans_n']) {
      for (let page = 1; page <= 6; page++) {
        const prods = await getPage(sort, page);
        if (!prods.length) break;
        await flush(prods);
      }
    }
    // 2) marche 100% vegetali (anche prodotti non taggati vegan su OFF)
    for (const brand of VEGAN_BRANDS) {
      for (let page = 1; page <= 3; page++) {
        const prods = await getBrandPage(brand, page);
        if (!prods.length) break;
        await flush(prods);
      }
    }
    const { count } = await admin.from('packaged_foods')
      .select('*', { count: 'exact', head: true });
    return new Response(JSON.stringify({ processed: seen.size, upserted: added, total: count }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error('sync-off', e);
    return new Response(JSON.stringify({ error: String((e as Error).message || e), upserted: added }), { status: 500 });
  }
});

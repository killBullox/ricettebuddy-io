// Prende un prodotto da Open Food Facts tramite EAN/codice a barre e lo inserisce
// (o aggiorna) in packaged_foods. Riservata al team (nutritionist/admin).
//
// POST { ean }  -> { product, vegan_label } | 404 se non trovato su OFF

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, content-type, apikey, x-client-info, x-supabase-api-version',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, 'Content-Type': 'application/json' } });

const FIELDS =
  'code,product_name,product_name_it,brands,quantity,image_front_url,image_url,categories,nutriments,nova_group,nutriscore_grade,labels_tags,ingredients_text,ingredients_text_it,ingredients_analysis_tags';

// "puo' contenere tracce" NON conta (avvertenza allergeni, non ingrediente)
const TRACES = /(pu[oò][\s']*contenere|may contain|tracce di|traces of|possibile presenza|prodotto in uno stabilimento)/i;
// frasi vegetali da togliere prima della scansione (evita falsi positivi)
const PLANT_SAFE =
  /(coconut|almond|soy|soya|oat|rice|cashew|hazelnut|hemp|nut|seed)\s+(milk|cream|butter)|cocoa butter|cream of tartar|latte di (cocco|mandorl\w*|soia|riso|avena|nocciol\w*|anacardi|arachid\w*|sesamo)|burro di (cacao|arachid\w*|mandorl\w*|nocciol\w*|semi|sesamo|anacardi|karit\w*)|(panna|formaggi\w*|yogurt|mozzarella)\s+(vegetal\w*|vegan\w*|di soia)|latte vegetale|bevanda (di|a base di) (soia|avena|riso|mandorl\w*|cocco)/gi;
// termini animali
const NEG =
  /\buov[oa]\b|albume|tuorl|ovoprodott|\begg\b|albumen|\byolk|(?<!senza )latte|lattosi|siero di latte|\bcasein|lattoalbumin|formagg|mozzarella|parmigian|pecorino|ricotta|mascarpone|\bmilk\b|\bwhey\b|lactose|\bcheese\b|\bbutter\b|\bcream\b|\bmiele\b|\bhoney\b|gelatin|\bstrutto\b|\blardo\b|\bsego\b|\btallow\b|\bcarne\b|pollo|tacchino|\bmanzo\b|maial|prosciutt|\bsalame\b|salamin|pancett|\bspeck\b|wurstel|mortadella|bresaola|\bbacon\b|\bham\b|sausage|\bmeat\b|chicken|\bbeef\b|\bpork\b|guancial|\bpesce\b|\btonno\b|acciugh|\balici\b|salmon|merluzz|gamber|crostace|mollusch|vongol|calamar|surimi|\bfish\b|\btuna\b|anchov|shrimp|prawn|colla di pesce|carminio|cocciniglia/i;

function veganCheck(p: any): { check: string; ingredients: string | null } {
  const a: string[] = p.ingredients_analysis_tags || [];
  let body = (p.ingredients_text_it || p.ingredients_text || '').toLowerCase();
  const m = body.match(TRACES);
  if (m && m.index !== undefined) body = body.slice(0, m.index); // via le tracce
  const ing = body.trim() ? body.slice(0, 1000) : null;
  if (a.includes('en:vegan')) return { check: 'vegan', ingredients: ing };
  if (a.includes('en:non-vegan')) return { check: 'non_vegan', ingredients: ing };
  const scan = body.replace(PLANT_SAFE, ' ');
  if (scan.trim() && NEG.test(scan)) return { check: 'non_vegan', ingredients: ing };
  return { check: 'da_verificare', ingredients: ing };
}

const num = (v: unknown): number | null => {
  const n = Number(v);
  return Number.isFinite(n) ? Math.round(n * 10) / 10 : null;
};

async function fetchOff(ean: string): Promise<any | null> {
  const hosts = [
    { url: `https://world.openfoodfacts.org/api/v2/product/${ean}.json?fields=${FIELDS}`, auth: '' },
    { url: `https://world.openfoodfacts.net/api/v2/product/${ean}.json?fields=${FIELDS}`, auth: 'Basic ' + btoa('off:off') },
  ];
  for (const h of hosts) {
    try {
      const headers: Record<string, string> = { 'User-Agent': 'BeetIt/1.0 (gianluca.davino@gmail.com)' };
      if (h.auth) headers.Authorization = h.auth;
      const r = await fetch(h.url, { headers });
      if (!r.ok) continue;
      const d = await r.json();
      if (d.status === 1 && d.product) return d.product;
    } catch { /* prova l'host successivo */ }
  }
  return null;
}

function toRow(p: any) {
  const name = (p.product_name_it || p.product_name || '').trim();
  const nu = p.nutriments || {};
  let nova: number | null = parseInt(p.nova_group, 10);
  if (!Number.isFinite(nova)) nova = null;
  return {
    code: String(p.code).trim(),
    name: name.slice(0, 200) || `Prodotto ${p.code}`,
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
    updated_at: new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Solo POST' }, 405);

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  const jwt = (req.headers.get('Authorization') || '').replace('Bearer ', '');
  const { data: u } = await admin.auth.getUser(jwt);
  if (!u?.user) return json({ error: 'Non autenticato' }, 401);
  const { data: prof } = await admin.from('profiles').select('role').eq('id', u.user.id).single();
  if (!prof || (prof.role !== 'nutritionist' && prof.role !== 'admin')) {
    return json({ error: 'Riservato al team' }, 403);
  }

  let body: Record<string, any>;
  try { body = await req.json(); } catch { return json({ error: 'JSON non valido' }, 400); }
  const ean = String(body.ean || '').replace(/\D/g, '');
  if (ean.length < 6) return json({ error: 'Codice a barre non valido' }, 400);

  try {
    const p = await fetchOff(ean);
    if (!p) return json({ error: 'Prodotto non trovato su Open Food Facts.', ean }, 404);
    const vc = veganCheck(p);
    const veganLabel = Array.isArray(p.labels_tags) && p.labels_tags.includes('en:vegan');
    // Prodotto NON vegano: non entra nel catalogo (che deve restare vegano).
    if (vc.check === 'non_vegan') {
      return json({
        rejected: true,
        vegan_check: 'non_vegan',
        error: 'Questo prodotto NON è vegano (contiene ingredienti di origine animale): non è stato aggiunto.',
        message: 'Questo prodotto NON è vegano (contiene ingredienti di origine animale) e non è stato aggiunto.',
        name: (p.product_name_it || p.product_name || '').trim() || `Prodotto ${p.code}`,
        ingredients: vc.ingredients,
      }, 422);
    }
    const row = { ...toRow(p), vegan_check: vc.check, ingredients_text: vc.ingredients };
    const { data: saved, error } = await admin.from('packaged_foods')
      .upsert(row, { onConflict: 'code', ignoreDuplicates: false })
      .select('*').single();
    if (error) throw new Error(error.message);
    return json({ product: saved, vegan_label: veganLabel, vegan_check: vc.check });
  } catch (e) {
    console.error('off-product', e);
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

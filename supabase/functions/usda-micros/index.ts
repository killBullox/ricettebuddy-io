// Arricchisce food_composition coi micronutrienti (set critico vegano) da USDA
// FoodData Central. Gira sulla rete Supabase (che raggiunge USDA, a differenza
// dell'ambiente locale). Guardata da un segreto (x-fn-secret == BACKFILL_SECRET).
//
// POST { items: [{ing_id, name, nome_it, categoria, fdc_id}] } -> upsert dei micro.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const USDA_KEY = Deno.env.get('USDA_API_KEY') || 'DEMO_KEY';
const SECRET = Deno.env.get('BACKFILL_SECRET') || '';

const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { 'Content-Type': 'application/json' } });

// set critico vegano -> id/numero nutriente USDA
const NUT: Record<string, string> = {
  '303': 'iron_mg', '1089': 'iron_mg', '309': 'zinc_mg', '1095': 'zinc_mg',
  '301': 'calcium_mg', '1087': 'calcium_mg', '304': 'magnesium_mg', '1090': 'magnesium_mg',
  '306': 'potassium_mg', '1092': 'potassium_mg', '418': 'b12_ug', '1178': 'b12_ug',
  '435': 'folate_ug', '1190': 'folate_ug', '417': 'folate_ug', '1177': 'folate_ug',
  '401': 'vitc_mg', '1162': 'vitc_mg', '328': 'vitd_ug', '1114': 'vitd_ug',
  '320': 'vita_ug', '1106': 'vita_ug', '323': 'vite_mg', '1109': 'vite_mg',
  '851': 'omega3_ala_g', '1404': 'omega3_ala_g', '314': 'iodine_ug', '1100': 'iodine_ug',
  '317': 'selenium_ug', '1103': 'selenium_ug',
};
const NIDS = '303,309,301,304,306,418,435,417,401,328,320,323,851,314,317';

function extract(foodNutrients: any[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const n of foodNutrients || []) {
    const nid = String(n?.nutrientId ?? n?.nutrientNumber ?? n?.nutrient?.id ?? n?.nutrient?.number ?? '');
    const key = NUT[nid];
    let val = n?.value; if (val == null) val = n?.amount;
    if (key && val != null && out[key] == null) out[key] = Math.round(Number(val) * 1000) / 1000;
  }
  return out;
}
async function getJSON(url: string): Promise<any | null> {
  for (let a = 0; a < 4; a++) {
    try {
      const r = await fetch(url);
      if (r.ok) return await r.json();
      if (r.status === 429 || r.status >= 500) { await new Promise((s) => setTimeout(s, 1500 * (a + 1))); continue; }
      return null;
    } catch { await new Promise((s) => setTimeout(s, 1500 * (a + 1))); }
  }
  return null;
}

Deno.serve(async (req) => {
  if (SECRET && req.headers.get('x-fn-secret') !== SECRET) return json({ error: 'forbidden' }, 403);
  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  let body: any = {};
  try { body = await req.json(); } catch { /* */ }
  const items: any[] = Array.isArray(body.items) ? body.items : [];
  let withValues = 0, without = 0;
  const rows: any[] = [];
  for (const it of items) {
    let per: Record<string, number> = {};
    let fdc = String(it.fdc_id || '').trim();
    if (fdc && /^\d+$/.test(fdc)) {
      const d = await getJSON(`https://api.nal.usda.gov/fdc/v1/food/${fdc}?api_key=${USDA_KEY}&nutrients=${NIDS}`);
      if (d) per = extract(d.foodNutrients);
    }
    if (Object.keys(per).length === 0) {
      const name = encodeURIComponent(it.name || it.nome_it || it.ing_id);
      const d = await getJSON(`https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${USDA_KEY}&query=${name}&pageSize=1&dataType=${encodeURIComponent('Foundation,SR Legacy')}`);
      const f = (d?.foods || [])[0];
      if (f) { fdc = String(f.fdcId || ''); per = extract(f.foodNutrients); }
    }
    if (Object.keys(per).length) withValues++; else without++;
    rows.push({
      ing_id: it.ing_id, nome_it: it.nome_it || null, nome_en: it.name || null,
      categoria: it.categoria || null, fdc_id: /^\d+$/.test(fdc) ? Number(fdc) : null,
      per_100g: per, fonte: 'USDA FDC', updated_at: new Date().toISOString(),
    });
  }
  if (rows.length) {
    const { error } = await admin.from('food_composition').upsert(rows, { onConflict: 'ing_id' });
    if (error) return json({ error: error.message }, 500);
  }
  return json({ processed: items.length, withValues, without });
});

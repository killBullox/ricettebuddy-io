// Funzione UNA-TANTUM: calcola zuccheri (sugars_g) e grassi saturi
// (saturated_fat_g) PER PORZIONE per le ricette che ne sono prive, a partire
// dagli ingredienti reali. Guardata da un segreto (x-backfill-secret).
//
// POST { limit?: number } -> processa un lotto di ricette senza sugars/saturated.
// Ritorna { updated, restanti, done } così il chiamante può ripetere fino a done.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANTHROPIC_KEY = Deno.env.get('ANTHROPIC_API_KEY')!;
const SECRET = Deno.env.get('BACKFILL_SECRET') || '';

const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { 'Content-Type': 'application/json' } });

const numOrNull = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);

async function estimateBatch(batch: any[]): Promise<Record<string, { sugars_g: number; saturated_fat_g: number }>> {
  const lines = batch.map((r) => {
    const n = r.nutrition || {};
    const ings = (r._ings || []).join('; ');
    return `ID ${r.id} — "${r.title}" (${r.category || '?'}, ${r.servings || 4} porzioni). ` +
      `Per porzione: carboidrati ${n.carbs_g ?? '?'} g, grassi ${n.fat_g ?? '?'} g. ` +
      `Ingredienti: ${ings || 'n/d'}`;
  }).join('\n');

  const prompt =
    `Sei il nutrizionista di un ricettario 100% vegetale. Per ogni ricetta stima, ` +
    `PER PORZIONE, i grammi di ZUCCHERI (sugars_g) e di GRASSI SATURI (saturated_fat_g), ` +
    `basandoti sugli ingredienti reali. Vincoli: sugars_g <= carboidrati indicati, ` +
    `saturated_fat_g <= grassi indicati, valori realistici (>=0), una cifra decimale.\n\n` +
    `Ricette:\n${lines}\n\n` +
    `Rispondi SOLO con un array JSON, un oggetto per ricetta, in questa forma:\n` +
    `[{"id":"<ID>","sugars_g":0.0,"saturated_fat_g":0.0}]`;

  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': ANTHROPIC_KEY, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
    body: JSON.stringify({ model: 'claude-sonnet-5', max_tokens: 8000, messages: [{ role: 'user', content: prompt }] }),
  });
  if (!r.ok) throw new Error(`Anthropic ${r.status}: ${await r.text()}`);
  const d = await r.json();
  const block = (d.content || []).find((b: { type: string }) => b.type === 'text');
  if (!block) throw new Error(`AI senza testo (stop: ${d.stop_reason})`);
  const txt = block.text as string;
  const a = txt.indexOf('['), b = txt.lastIndexOf(']');
  if (a < 0 || b < a) throw new Error(`AI non in JSON array: ${txt.slice(0, 160)}`);
  const arr = JSON.parse(txt.slice(a, b + 1)) as any[];
  const out: Record<string, { sugars_g: number; saturated_fat_g: number }> = {};
  for (const o of arr) {
    if (o && o.id != null) {
      out[String(o.id)] = {
        sugars_g: Math.max(0, Number(o.sugars_g) || 0),
        saturated_fat_g: Math.max(0, Number(o.saturated_fat_g) || 0),
      };
    }
  }
  return out;
}

Deno.serve(async (req) => {
  if (SECRET && req.headers.get('x-backfill-secret') !== SECRET) return json({ error: 'forbidden' }, 403);
  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  let body: Record<string, any> = {};
  try { body = await req.json(); } catch { /* default */ }
  const limit = Math.max(1, Math.min(20, parseInt(body.limit, 10) || 10));

  try {
    const { data: recipes, error } = await admin.from('recipes')
      .select('id, title, category, servings, nutrition')
      .not('nutrition->kcal', 'is', null)
      .is('nutrition->saturated_fat_g', null)
      .order('id')
      .limit(limit);
    if (error) throw new Error(error.message);
    if (!recipes || !recipes.length) return json({ updated: 0, restanti: 0, done: true });

    const ids = recipes.map((r) => r.id);
    const { data: ings } = await admin.from('ingredients')
      .select('recipe_id, raw_text').in('recipe_id', ids);
    const byRec: Record<string, string[]> = {};
    for (const i of (ings || [])) (byRec[i.recipe_id] ||= []).push(i.raw_text);
    for (const r of recipes) (r as any)._ings = byRec[r.id] || [];

    const est = await estimateBatch(recipes);

    let updated = 0;
    for (const r of recipes) {
      const e = est[String(r.id)];
      const n = { ...(r.nutrition || {}) } as any;
      const carbs = numOrNull(n.carbs_g), fat = numOrNull(n.fat_g);
      let sug = e ? e.sugars_g : 0, sat = e ? e.saturated_fat_g : 0;
      if (carbs != null) sug = Math.min(sug, carbs);
      if (fat != null) sat = Math.min(sat, fat);
      n.sugars_g = Math.round(sug * 10) / 10;
      n.saturated_fat_g = Math.round(sat * 10) / 10;
      const { error: ue } = await admin.from('recipes').update({ nutrition: n }).eq('id', r.id);
      if (!ue) updated++;
    }

    const { count } = await admin.from('recipes')
      .select('*', { count: 'exact', head: true })
      .not('nutrition->kcal', 'is', null)
      .is('nutrition->saturated_fat_g', null);
    return json({ updated, restanti: count ?? 0, done: (count ?? 0) === 0 });
  } catch (e) {
    console.error('nutri-backfill', e);
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

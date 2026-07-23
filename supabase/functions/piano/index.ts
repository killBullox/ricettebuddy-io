// Piano alimentare: ponte fra area team e app del cliente.
//
// Azioni TEAM (chi chiama deve essere nutritionist/admin):
//   { action: "cerca_clienti", q } -> cerca per email o nome/cognome
//   { action: "push", client_id, week_start, note, items:[{day_index,slot,base_code,title}] }
//        -> crea meal_plans + meal_plan_items
//
// Azione CLIENTE (chi chiama deve essere il cliente del piano):
//   { action: "importa", plan_id }
//        -> copia le ricette base nella collezione del cliente (dedup per
//           base_code) e crea le meal_plan_entries; segna il piano "imported".

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Solo POST' }, 405);

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  const jwt = (req.headers.get('Authorization') || '').replace('Bearer ', '');
  const { data: u } = await admin.auth.getUser(jwt);
  if (!u?.user) return json({ error: 'Non autenticato' }, 401);
  const uid = u.user.id;

  const { data: prof } = await admin.from('profiles').select('role').eq('id', uid).single();
  const isTeam = prof && (prof.role === 'nutritionist' || prof.role === 'admin');

  let body: Record<string, any>;
  try { body = await req.json(); } catch { return json({ error: 'JSON non valido' }, 400); }

  try {
    // ----------------------------------------------------- cerca clienti (team)
    if (body.action === 'cerca_clienti') {
      if (!isTeam) return json({ error: 'Riservato al team' }, 403);
      const q = String(body.q || '').trim().toLowerCase();

      const { data: clients } = await admin
        .from('profiles').select('id, full_name').eq('role', 'client');
      const byId: Record<string, { id: string; full_name: string | null; email: string }> = {};
      for (const c of clients || []) byId[c.id] = { id: c.id, full_name: c.full_name, email: '' };

      // le email vivono in auth.users: le prendiamo con l'admin API
      const { data: list } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
      for (const usr of list?.users || []) {
        if (byId[usr.id]) byId[usr.id].email = usr.email || '';
      }
      let out = Object.values(byId);
      if (q) {
        out = out.filter((c) =>
          c.email.toLowerCase().includes(q) ||
          (c.full_name || '').toLowerCase().includes(q));
      }
      out.sort((a, b) => (a.full_name || a.email).localeCompare(b.full_name || b.email));
      return json({ clienti: out.slice(0, 50) });
    }

    // ------------------------------------------------------------- push (team)
    if (body.action === 'push') {
      if (!isTeam) return json({ error: 'Riservato al team' }, 403);
      const clientId = String(body.client_id || '');
      const items = Array.isArray(body.items) ? body.items : [];
      if (!clientId) return json({ error: 'Manca il cliente' }, 400);
      if (!items.length) return json({ error: 'Il piano e\' vuoto' }, 400);

      const { data: plan, error: pe } = await admin.from('meal_plans').insert({
        client_id: clientId, nutritionist_id: uid,
        week_start: body.week_start || null, note: body.note || null, status: 'pending',
      }).select('id').single();
      if (pe) throw new Error('meal_plans: ' + pe.message);

      const rows = items.map((it: any, i: number) => ({
        plan_id: plan.id,
        day_index: Math.max(0, Math.min(6, parseInt(it.day_index, 10) || 0)),
        slot: it.slot, base_code: String(it.base_code || ''),
        title: String(it.title || ''), position: i,
      }));
      const { error: ie } = await admin.from('meal_plan_items').insert(rows);
      if (ie) { await admin.from('meal_plans').delete().eq('id', plan.id); throw new Error('items: ' + ie.message); }

      return json({ plan_id: plan.id, n_items: rows.length });
    }

    // ------------------------------------------------------- importa (cliente)
    if (body.action === 'importa') {
      const planId = String(body.plan_id || '');
      if (!planId) return json({ error: 'Manca il piano' }, 400);

      const { data: plan } = await admin.from('meal_plans')
        .select('id, client_id, week_start, status').eq('id', planId).single();
      if (!plan) return json({ error: 'Piano inesistente' }, 404);
      if (plan.client_id !== uid) return json({ error: 'Non e\' il tuo piano' }, 403);

      const { data: items } = await admin.from('meal_plan_items')
        .select('day_index, slot, base_code').eq('plan_id', planId).order('position');
      if (!items?.length) return json({ error: 'Piano vuoto' }, 400);

      // 1) copia le ricette base necessarie nella collezione del cliente,
      //    saltando quelle che ha gia' (dedup per base_code).
      const codes = [...new Set(items.map((i) => i.base_code))];
      const { data: owned } = await admin.from('recipes')
        .select('id, base_code').eq('user_id', uid).in('base_code', codes);
      const idByCode: Record<string, string> = {};
      for (const r of owned || []) if (r.base_code) idByCode[r.base_code] = r.id;

      const missing = codes.filter((c) => !idByCode[c]);
      for (const code of missing) {
        const { data: base } = await admin.from('recipes')
          .select('*').is('user_id', null).eq('base_code', code).single();
        if (!base) continue;
        const { id: _bid, created_at: _c, updated_at: _u, ...fields } = base;
        const { data: copy, error: ce } = await admin.from('recipes')
          .insert({ ...fields, user_id: uid }).select('id').single();
        if (ce) throw new Error(`copia ${code}: ${ce.message}`);
        idByCode[code] = copy.id;

        const { data: ings } = await admin.from('ingredients')
          .select('position, raw_text, quantity, unit, normalized_name, aisle_category')
          .eq('recipe_id', _bid).order('position');
        if (ings?.length) {
          await admin.from('ingredients').insert(
            ings.map((x) => ({ ...x, recipe_id: copy.id, user_id: uid })));
        }
        const { data: steps } = await admin.from('steps')
          .select('position, text').eq('recipe_id', _bid).order('position');
        if (steps?.length) {
          await admin.from('steps').insert(
            steps.map((x) => ({ ...x, recipe_id: copy.id, user_id: uid })));
        }
      }

      // 2) materializza il piano in meal_plan_entries (una riga per piatto).
      //    week_start = lunedi'; day_index 0..6 = giorni della settimana.
      const monday = plan.week_start ? new Date(plan.week_start + 'T00:00:00Z') : null;
      const fmt = (d: Date) => d.toISOString().slice(0, 10);
      // togliamo prima eventuali voci di un import precedente dello stesso piano
      if (monday) {
        const dates = [...new Set(items.map((i) => {
          const d = new Date(monday); d.setUTCDate(d.getUTCDate() + i.day_index); return fmt(d);
        }))];
        await admin.from('meal_plan_entries').delete().eq('user_id', uid).in('date', dates);
      }
      const entries = items.map((i) => {
        let date = fmt(new Date());
        if (monday) { const d = new Date(monday); d.setUTCDate(d.getUTCDate() + i.day_index); date = fmt(d); }
        return { user_id: uid, date, slot: i.slot, recipe_id: idByCode[i.base_code], servings: 2 };
      }).filter((e) => e.recipe_id);
      const { error: ee } = await admin.from('meal_plan_entries').insert(entries);
      if (ee) throw new Error('entries: ' + ee.message);

      await admin.from('meal_plans').update({ status: 'imported' }).eq('id', planId);
      return json({ imported: entries.length, recipes_copied: missing.length });
    }

    return json({ error: 'action sconosciuta' }, 400);
  } catch (e) {
    console.error('piano', body.action, e);
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

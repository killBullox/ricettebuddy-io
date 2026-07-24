// Generatore di piano alimentare automatico, condiviso da app e area team.
// Compone N settimane (diverse tra loro) rispettando: apporto calorico
// giornaliero, ingredienti preferiti / da evitare, e la presenza o meno di
// colazione, spuntini, dolci e frutta.
//
// Input (POST):
//   { kcal: number|null, preferiti: string[], evitare: string[],
//     colazione: bool, spuntini: bool, dolci: bool, frutta: bool,
//     settimane: number }
//
// Output:
//   { settimane: [ { items: [ {day_index, slot, base_code, title, kcal} ] } ],
//     catalogo: number }
//
// Chi chiama deve essere autenticato (cliente per il proprio piano, o team).

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

// ---------------------------------------------------------------- classificazione
// Port delle regex di auto_planner.dart. I piatti "veri" vincono sulle basi.
const reBreakfast = /colazion|breakfast|porridge|pancake|crep|smoothie|frullat|granola|overnight|chia|yogurt/i;
const reFrutta = /\bfrutta\b|macedonia|frutti di bosco|spremuta|frullato di frutta|coppa di frutta/i;
// \bdolce\b: evita che "agrodolce" (cipolline in agrodolce ecc.) sia un dolce.
const reDolce = /\bdolce\b|dessert|tort[ae]|muffin|biscott|budino|crostat|plumcake|gelato|mousse|cioccolat|tiramis|panna cotta|semifreddo|castagnaccio|mostaccioli/i;
const reAntipasto = /antipast|contorn|insalat|starter|side|bruschett|hummus|crostin|vellutata leggera/i;
const rePrimo = /\bprim[oi]\b|past[a]\b|spaghett|penne|rigaton|risott|gnocch|lasagn|zupp|minestr|vellutat|ramen|noodle|couscous|cous cous/i;
const reSecondo = /\bsecond[oi]\b|polpett|burger|cotolett|arrost|spezzatin|seitan|tempeh|tofu alla|scaloppin|involtin|frittat|falafel|polpett/i;
const rePiattoUnico = /piatto unico|bowl|buddha|poke|one[- ]pot|curry|chili|paella|parmigiana|lasagn|risott/i;
const reBase = /\bburro\b|margarin|maiones|ketchup|senape|salsa|\bsugo\b|pesto|condiment|brodo|\bdado\b|besciamell|panna vegetale|spalmabil|formaggio vegan|marmellat|confettur|conserva|sottacet|latte (di|vegetale)|yogurt fatto|impasto|lievito madre|pasta madre|base per|preparato/i;

type Course = 'breakfast' | 'frutta' | 'antipasto' | 'primo' | 'secondo' | 'piattoUnico' | 'dolce' | 'base';

function courseOf(r: any): Course {
  const hay = `${r.category || ''} ${(r.tags || []).join(' ')} ${r.title || ''}`;
  if (reBreakfast.test(hay)) return 'breakfast';
  if (reFrutta.test(hay)) return 'frutta';
  if (rePiattoUnico.test(hay)) return 'piattoUnico';
  if (rePrimo.test(hay)) return 'primo';
  if (reSecondo.test(hay)) return 'secondo';
  if (reBase.test(hay)) return 'base';
  if (reDolce.test(hay)) return 'dolce';
  if (reAntipasto.test(hay)) return 'antipasto';
  const k = kcalOf(r);
  if (k != null && k >= 350) return 'piattoUnico';
  return 'antipasto';
}
function kcalOf(r: any): number | null {
  const k = r?.nutrition?.kcal;
  return typeof k === 'number' ? k : null;
}

// quote caloriche per pasto (rinormalizzate se manca la colazione)
const SHARE: Record<string, number> = { breakfast: 0.22, lunch: 0.38, snack: 0.08, dinner: 0.32 };

// combinazioni per pranzo/cena, in ordine di preferenza
const COMBOS: Course[][] = [
  ['piattoUnico'],
  ['primo', 'secondo'],
  ['antipasto', 'primo'],
  ['antipasto', 'secondo'],
  ['antipasto', 'primo', 'secondo'],
];

// PRNG deterministico (nessun Math.random nelle Edge Function volatili è ok, ma
// vogliamo varietà riproducibile per seed).
function mulberry32(seed: number) {
  return () => {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
function shuffle<T>(arr: T[], rnd: () => number): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Solo POST' }, 405);

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);
  const jwt = (req.headers.get('Authorization') || '').replace('Bearer ', '');
  const { data: u } = await admin.auth.getUser(jwt);
  if (!u?.user) return json({ error: 'Non autenticato' }, 401);

  let b: Record<string, any>;
  try { b = await req.json(); } catch { return json({ error: 'JSON non valido' }, 400); }

  const kcal: number | null = typeof b.kcal === 'number' && b.kcal > 0 ? b.kcal : null;
  const preferiti: string[] = (Array.isArray(b.preferiti) ? b.preferiti : [])
    .map((s: string) => String(s).toLowerCase().trim()).filter(Boolean);
  const evitare: string[] = (Array.isArray(b.evitare) ? b.evitare : [])
    .map((s: string) => String(s).toLowerCase().trim()).filter(Boolean);
  const colazione = b.colazione !== false;
  const spuntini = !!b.spuntini;
  const dolci = !!b.dolci;
  const frutta = !!b.frutta;
  const settimane = Math.max(1, Math.min(8, parseInt(b.settimane, 10) || 1));

  try {
    // catalogo base + ingredienti (per il match preferiti/evitare)
    const { data: recipes } = await admin.from('recipes')
      .select('id, base_code, title, category, tags, nutrition')
      .is('user_id', null);

    // Gli ingredienti sono ~1500: PostgREST ne restituisce max 1000 per volta,
    // quindi vanno paginati o il filtro "evitare" salta metà delle ricette.
    const ings: any[] = [];
    for (let from = 0; ; from += 1000) {
      const { data: page } = await admin.from('ingredients')
        .select('recipe_id, raw_text, normalized_name')
        .is('user_id', null).range(from, from + 999);
      if (!page || !page.length) break;
      ings.push(...page);
      if (page.length < 1000) break;
    }

    const ingByRecipe: Record<string, string> = {};
    for (const i of ings) {
      const t = `${i.normalized_name || ''} ${i.raw_text || ''}`.toLowerCase();
      ingByRecipe[i.recipe_id] = (ingByRecipe[i.recipe_id] || '') + ' ' + t;
    }

    // prepara il pool: escludi le basi/condimenti e le ricette con ingredienti da evitare
    const pool = (recipes || [])
      .filter((r) => courseOf(r) !== 'base')
      .filter((r) => kcal == null || kcalOf(r) != null)
      .filter((r) => {
        if (!evitare.length) return true;
        const txt = ingByRecipe[r.id] || '';
        return !evitare.some((e) => txt.includes(e));
      })
      .map((r) => {
        const txt = ingByRecipe[r.id] || '';
        const score = preferiti.reduce((s, p) => s + (txt.includes(p) ? 1 : 0), 0);
        return { ...r, _course: courseOf(r), _score: score };
      });

    // indice per portata, ordinando i preferiti in cima
    const byCourse: Record<string, any[]> = {};
    for (const r of pool) (byCourse[r._course] ||= []).push(r);
    for (const c in byCourse) byCourse[c].sort((a, b) => b._score - a._score);

    const forCourse = (c: string, maxK: number): any[] => {
      let list: any[];
      if (c === 'breakfast') list = [...(byCourse.breakfast || []), ...(byCourse.dolce || [])];
      else if (c === 'snack') list = [
        ...(byCourse.dolce || []), ...(byCourse.breakfast || []), ...(byCourse.frutta || []),
        // se non ci sono dolci/colazioni/frutta liberi, uno spuntino può essere
        // anche un antipasto/contorno leggero (il catalogo ha pochi "snack veri").
        ...(byCourse.antipasto || []),
      ].filter((r) => (kcalOf(r) ?? 999) <= 250);
      else if (c === 'frutta') list = [...(byCourse.frutta || [])];
      else list = byCourse[c] || [];
      return list.filter((r) => (kcalOf(r) ?? 0) <= maxK);
    };

    const slots = [
      ...(colazione ? ['breakfast'] : []),
      'lunch',
      ...(spuntini ? ['snack'] : []),
      'dinner',
    ];
    // rinormalizza le quote sui pasti attivi
    const shareSum = slots.reduce((s, sl) => s + (SHARE[sl] || 0), 0);

    const used = new Set<string>();   // varietà tra i giorni e tra le settimane
    const rnd = mulberry32(0x9e37 ^ (kcal || 0) ^ settimane);

    // dayUsed: mai la stessa ricetta due volte nello stesso giorno (esclusione
    // netta); used: varietà tra i giorni e le settimane (solo preferenza).
    function pick(c: string, budget: number, dayUsed: Set<string>): any | null {
      const all = forCourse(c, budget).filter((r) => !dayUsed.has(r.base_code));
      if (!all.length) return null;
      let cands = all.filter((r) => !used.has(r.base_code));
      if (!cands.length) cands = all;
      const best = cands[0]._score;
      const top = cands.filter((r) => r._score === best);
      return shuffle(top.length ? top : cands, rnd)[0];
    }

    const settimaneOut: any[] = [];
    for (let w = 0; w < settimane; w++) {
      // ogni settimana ricomincia con varietà piena se il catalogo è piccolo
      if (used.size > pool.length * 0.7) used.clear();
      const items: any[] = [];

      for (let d = 0; d < 7; d++) {
        let remaining = kcal == null ? Infinity : kcal;
        const dayUsed = new Set<string>();

        for (const slot of slots) {
          const slotBudget = kcal == null
            ? Infinity
            : Math.min(remaining, (SHARE[slot] / shareSum) * kcal * 1.4);

          const add = (r: any) => {
            items.push({ day_index: d, slot, base_code: r.base_code, title: r.title, kcal: Math.round(kcalOf(r) || 0) });
            used.add(r.base_code);
            dayUsed.add(r.base_code);
            remaining -= kcalOf(r) || 0;
          };

          if (slot === 'breakfast' || slot === 'snack') {
            const r = pick(slot === 'breakfast' ? 'breakfast' : 'snack', slotBudget, dayUsed);
            if (r) add(r);
            // frutta a colazione/spuntino se richiesta
            if (frutta && remaining > 0) {
              const f = pick('frutta', Math.max(150, remaining), dayUsed);
              if (f) add(f);
            }
          } else {
            for (const combo of shuffle(COMBOS, rnd)) {
              const dishes: any[] = [];
              const comboUsed = new Set(dayUsed);
              let budget = slotBudget;
              let ok = true;
              for (const course of combo) {
                const r = pick(course, budget, comboUsed);
                if (!r) { ok = false; break; }
                dishes.push(r);
                comboUsed.add(r.base_code);
                budget -= kcalOf(r) || 0;
              }
              if (!ok) continue;
              if (dolci && budget > 80) {
                const dolce = pick('dolce', budget, comboUsed);
                if (dolce) dishes.push(dolce);
              }
              dishes.forEach(add);
              break;
            }
          }
        }
      }
      settimaneOut.push({ items });
    }

    return json({ settimane: settimaneOut, catalogo: pool.length });
  } catch (e) {
    console.error('genera-piano', e);
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

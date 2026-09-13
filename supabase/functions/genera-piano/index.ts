// Generatore di piano alimentare automatico, condiviso da app e area team.
// Compone N settimane rispettando: apporto calorico giornaliero, ingredienti
// preferiti/da evitare, colazione/spuntini/dolci/frutta, e — novità — la
// RIPARTIZIONE dei macronutrienti (Proteine/Carboidrati/Grassi come % delle
// calorie, che sommano a 100) con tolleranza ±3%. Zuccheri e grassi saturi
// restano TETTI massimi. Se il catalogo non permette di stare entro ±3% lo
// SEGNALA nel riepilogo (macro.warnings + macro.feasible=false).
//
// Input (POST): { kcal, preferiti[], evitare[], colazione, spuntini, dolci,
//   frutta, di_stagione, escludi_internazionali, settimane,
//   profilo:{protein,carbs,fat (target, somma 100), sugars,saturated (max)} }
// Output: { settimane:[{items:[{day_index,slot,base_code,title,kcal,
//   protein_g,carbs_g,fat_g}]}], catalogo, macro }

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
const reBreakfast = /colazion|breakfast|porridge|pancake|crep|smoothie|frullat|granola|overnight|chia|yogurt/i;
const reFrutta = /\bfrutta\b|macedonia|frutti di bosco|spremuta|frullato di frutta|coppa di frutta/i;
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

const SHARE: Record<string, number> = { breakfast: 0.22, lunch: 0.38, snack: 0.08, dinner: 0.32 };
const COMBOS: Course[][] = [
  ['piattoUnico'],
  ['primo', 'secondo'],
  ['antipasto', 'primo'],
  ['antipasto', 'secondo'],
  ['antipasto', 'primo', 'secondo'],
];

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

// kcal per grammo (zuccheri come i carbo, saturi come i grassi)
const FACT: Record<string, number> = { protein: 4, carbs: 4, sugars: 4, fat: 9, saturated: 9 };
const TARGET_MACROS = ['protein', 'carbs', 'fat'] as const; // ripartizione = 100
const CAP_MACROS = ['sugars', 'saturated'] as const;        // tetti massimi
const ALL_MACROS = ['protein', 'carbs', 'sugars', 'fat', 'saturated'] as const;
const TOLL = 3; // tolleranza ± sui macro target (punti percentuali)

const numOrNull = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const macrosOf = (r: any): Record<string, number> => {
  const n = r?.nutrition || {};
  return {
    protein: n.protein_g || 0, carbs: n.carbs_g || 0, sugars: n.sugars_g || 0,
    fat: n.fat_g || 0, saturated: n.saturated_fat_g || 0,
  };
};

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
  const escludiInternazionali = !!b.escludi_internazionali;
  const diStagione = !!b.di_stagione;
  const meseCorrente = new Date().getUTCMonth() + 1;

  // Profilo: protein/carbs/fat = TARGET (%, somma ~100); sugars/saturated = MAX.
  const pctIn = (v: unknown): number | null => {
    const n = Number(v);
    return Number.isFinite(n) && n > 0 ? Math.min(100, n) : null;
  };
  const pIn = (b.profilo && typeof b.profilo === 'object') ? b.profilo as Record<string, unknown> : {};
  const profilo: Record<string, number | null> = {
    protein: pctIn(pIn.protein), carbs: pctIn(pIn.carbs), fat: pctIn(pIn.fat),
    sugars: pctIn(pIn.sugars), saturated: pctIn(pIn.saturated),
  };
  const hasTargets = TARGET_MACROS.every((k) => profilo[k] != null);
  const hasProfile = ALL_MACROS.some((k) => profilo[k] != null);

  const CAT_ITALIANE = new Set([
    'Antipasti e contorni', 'Primi di pasta', 'Riso e cereali', 'Zuppe e minestre',
    'Legumi e secondi vegetali', 'Lievitati, pane e pizza', 'Dolci', 'Colazione',
  ]);
  const isInternazionale = (r: any) => !CAT_ITALIANE.has(r.category);

  try {
    const { data: recipes } = await admin.from('recipes')
      .select('id, base_code, title, category, tags, nutrition, season_months')
      .is('user_id', null);

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

    const pool = (recipes || [])
      .filter((r) => courseOf(r) !== 'base')
      .filter((r) => kcal == null || kcalOf(r) != null)
      .filter((r) => !escludiInternazionali || !isInternazionale(r))
      .filter((r) => {
        if (!evitare.length) return true;
        const txt = ingByRecipe[r.id] || '';
        return !evitare.some((e) => txt.includes(e));
      })
      .map((r) => {
        const txt = ingByRecipe[r.id] || '';
        const pref = preferiti.reduce((s, p) => s + (txt.includes(p) ? 1 : 0), 0);
        const inSeason = Array.isArray(r.season_months) && r.season_months.includes(meseCorrente);
        const seasonBonus = diStagione && inSeason ? 2 : 0;
        return { ...r, _course: courseOf(r), _score: pref + seasonBonus };
      });

    const byCourse: Record<string, any[]> = {};
    for (const r of pool) (byCourse[r._course] ||= []).push(r);
    for (const c in byCourse) byCourse[c].sort((a, b) => b._score - a._score);

    const forCourse = (c: string, maxK: number): any[] => {
      let list: any[];
      if (c === 'breakfast') list = [...(byCourse.breakfast || []), ...(byCourse.dolce || [])];
      else if (c === 'snack') list = [
        ...(byCourse.dolce || []), ...(byCourse.breakfast || []), ...(byCourse.frutta || []),
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
    const shareSum = slots.reduce((s, sl) => s + (SHARE[sl] || 0), 0);

    const used = new Set<string>();
    const rnd = mulberry32(0x9e37 ^ (kcal || 0) ^ settimane);

    // SCOSTAMENTO (in kcal) dalla ripartizione ideale se aggiungo il candidato.
    // Confronta i grammi proiettati con quelli "ideali" all'energia raggiunta:
    // così spinge la selezione verso la % target indipendentemente da quanto
    // si è già mangiato. Aggiunge una penale se sfora i tetti zuccheri/saturi.
    const deviation = (r: any, accN: Record<string, number>, accKcal: number): number => {
      if (!hasProfile) return 0;
      const g = macrosOf(r);
      const E = accKcal + (kcalOf(r) || 0);
      if (E <= 0) return 0;
      let pen = 0;
      for (const k of TARGET_MACROS) {
        if (profilo[k] == null) continue;
        const ideal = (profilo[k] as number) / 100 * E / FACT[k];
        const proj = (accN[k] || 0) + (g[k] || 0);
        pen += Math.abs(proj - ideal) * FACT[k];
      }
      for (const k of CAP_MACROS) {
        if (profilo[k] == null) continue;
        const capg = (profilo[k] as number) / 100 * E / FACT[k];
        const proj = (accN[k] || 0) + (g[k] || 0);
        if (proj > capg) pen += (proj - capg) * FACT[k] * 1.5;
      }
      return pen;
    };

    function pick(c: string, budget: number, dayUsed: Set<string>,
                  accN: Record<string, number>, accKcal: number): any | null {
      const all = forCourse(c, budget).filter((r) => !dayUsed.has(r.base_code));
      if (!all.length) return null;
      let cands = all.filter((r) => !used.has(r.base_code));
      if (!cands.length) cands = all;
      // ordina per: minimo scostamento dalla ripartizione, poi preferiti/stagione
      cands = cands.slice().sort((a, b) => {
        const va = deviation(a, accN, accKcal), vb = deviation(b, accN, accKcal);
        if (Math.abs(va - vb) > 1e-6) return va - vb;
        return b._score - a._score;
      });
      const minV = deviation(cands[0], accN, accKcal);
      const bestS = cands[0]._score;
      const top = cands.filter((r) => deviation(r, accN, accKcal) <= minV + 1e-6 && r._score === bestS);
      return shuffle(top.length ? top : [cands[0]], rnd)[0];
    }

    const agg: Record<string, number> = { kcal: 0, protein: 0, carbs: 0, sugars: 0, fat: 0, saturated: 0 };
    let missingData = 0;

    const settimaneOut: any[] = [];
    for (let w = 0; w < settimane; w++) {
      if (used.size > pool.length * 0.7) used.clear();
      const items: any[] = [];

      for (let d = 0; d < 7; d++) {
        let remaining = kcal == null ? Infinity : kcal;
        const dayUsed = new Set<string>();
        const dayN: Record<string, number> = { protein: 0, carbs: 0, sugars: 0, fat: 0, saturated: 0 };
        let dayKcal = 0;

        for (const slot of slots) {
          const slotBudget = kcal == null
            ? Infinity
            : Math.min(remaining, (SHARE[slot] / shareSum) * kcal * 1.4);

          const add = (r: any) => {
            const g = macrosOf(r);
            const rk = Math.round(kcalOf(r) || 0);
            items.push({
              day_index: d, slot, base_code: r.base_code, title: r.title, kcal: rk,
              protein_g: Math.round(g.protein), carbs_g: Math.round(g.carbs), fat_g: Math.round(g.fat),
            });
            used.add(r.base_code); dayUsed.add(r.base_code);
            remaining -= kcalOf(r) || 0;
            for (const k of ALL_MACROS) { dayN[k] += g[k] || 0; agg[k] += g[k] || 0; }
            dayKcal += kcalOf(r) || 0; agg.kcal += kcalOf(r) || 0;
            const n = r?.nutrition || {};
            if (n.sugars_g == null || n.saturated_fat_g == null) missingData++;
          };

          if (slot === 'breakfast' || slot === 'snack') {
            const r = pick(slot === 'breakfast' ? 'breakfast' : 'snack', slotBudget, dayUsed, dayN, dayKcal);
            if (r) add(r);
            if (frutta && remaining > 0) {
              const f = pick('frutta', Math.max(150, remaining), dayUsed, dayN, dayKcal);
              if (f) add(f);
            }
          } else {
            const mealBudget = kcal == null ? Infinity : (SHARE[slot] / shareSum) * kcal * 1.6;
            let placed = false;
            for (const combo of shuffle(COMBOS, rnd)) {
              const dishes: any[] = [];
              const comboUsed = new Set(dayUsed);
              const comboN: Record<string, number> = { ...dayN };
              let comboKcal = dayKcal;
              let budget = mealBudget;
              let ok = true;
              for (const course of combo) {
                const r = pick(course, budget, comboUsed, comboN, comboKcal);
                if (!r) { ok = false; break; }
                dishes.push(r);
                comboUsed.add(r.base_code);
                budget -= kcalOf(r) || 0;
                const g = macrosOf(r);
                for (const k of ALL_MACROS) comboN[k] += g[k] || 0;
                comboKcal += kcalOf(r) || 0;
              }
              if (!ok) continue;
              if (dolci && budget > 80) {
                const dolce = pick('dolce', budget, comboUsed, comboN, comboKcal);
                if (dolce) dishes.push(dolce);
              }
              dishes.forEach(add);
              placed = true;
              break;
            }
            if (!placed) {
              const r = pick('piattoUnico', Infinity, dayUsed, dayN, dayKcal)
                || pick('primo', Infinity, dayUsed, dayN, dayKcal)
                || pick('secondo', Infinity, dayUsed, dayN, dayKcal)
                || pick('antipasto', Infinity, dayUsed, dayN, dayKcal);
              if (r) add(r);
            }
          }
        }
      }
      settimaneOut.push({ items });
    }

    // ---- Riepilogo macro del piano: target vs reale, tolleranza ±3% ----
    const LABEL: Record<string, string> = {
      protein: 'Proteine', carbs: 'Carboidrati', sugars: 'Zuccheri', fat: 'Grassi', saturated: 'Grassi saturi',
    };
    const actualPct = (k: string): number | null =>
      agg.kcal > 0 ? Math.round((agg[k] * FACT[k] / agg.kcal * 100) * 10) / 10 : null;

    const macro: Record<string, any> = {
      kcal_avg: Math.round(agg.kcal / (settimane * 7)),
      warnings: [] as string[], missing_data: missingData, feasible: true, targets: hasTargets,
    };
    for (const k of TARGET_MACROS) {
      const act = actualPct(k), tgt = profilo[k];
      macro[k] = { actual: act, target: tgt };
      if (tgt != null && act != null) {
        const ok = Math.abs(act - (tgt as number)) <= TOLL + 0.05;
        macro[k].ok = ok;
        if (!ok) {
          macro.feasible = false;
          macro.warnings.push(`${LABEL[k]}: ${act}% (obiettivo ${tgt}% ±${TOLL}) — il catalogo non offre combinazioni per rientrare.`);
        }
      }
    }
    for (const k of CAP_MACROS) {
      const act = actualPct(k), max = profilo[k];
      macro[k] = { actual: act, max };
      if (max != null && act != null) {
        const ok = act <= (max as number) + 0.05;
        macro[k].ok = ok;
        if (!ok) { macro.feasible = false; macro.warnings.push(`${LABEL[k]}: ${act}% oltre il max ${max}%.`); }
      }
    }

    return json({ settimane: settimaneOut, catalogo: pool.length, macro });
  } catch (e) {
    console.error('genera-piano', e);
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

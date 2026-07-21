// Edge Function per l'area team: le chiavi (Replicate, Anthropic) restano qui,
// mai nella pagina pubblica. Ogni chiamata verifica che chi chiama sia
// nutritionist o admin.
//
// POST { action: "foto",   ... } -> genera la foto del piatto e la carica su Storage
// POST { action: "assist", ... } -> struttura la ricetta (dosi + passi con dosi + nutrizione)

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const REPLICATE_TOKEN = Deno.env.get('REPLICATE_API_TOKEN')!;
const ANTHROPIC_KEY = Deno.env.get('ANTHROPIC_API_KEY')!;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });

// ---------------------------------------------------------------- prompt foto
// Stesso template usato per le 149 foto del catalogo: le nuove ricette devono
// avere esattamente la stessa resa, altrimenti la libreria non e' omogenea.

const STOVIGLIA: Record<string, string> = {
  'Antipasti e contorni': 'on a simple white ceramic plate',
  'Primi di pasta': 'in a shallow pasta bowl',
  'Zuppe e minestre': 'in a plain bowl',
  'Riso e cereali': 'in a shallow bowl',
  'Legumi e secondi vegetali': 'on a simple white ceramic plate',
  'Lievitati, pane e pizza': 'on a wooden board or plate',
  'Dolci': 'on a simple dessert plate',
  'Medio Oriente e Nord Africa': 'on a simple plate, mezze style',
  'India e subcontinente': 'in a small bowl with a side of rice',
  'Asia orientale e Sud Est': 'in an asian style bowl',
  'Americhe': 'on a simple plate',
  'Europa': 'on a simple plate',
  'Africa subsahariana': 'served on injera flatbread',
};
const NAZ: Record<string, string> = {
  'Medio Oriente e Nord Africa': 'Middle Eastern',
  'India e subcontinente': 'Indian',
  'Asia orientale e Sud Est': 'Asian',
  'Americhe': 'Latin American',
  'Europa': 'European',
  'Africa subsahariana': 'East African',
};

function promptFoto(
  titolo: string,
  categoria: string,
  zona: string,
  ingredientiEn: string,
): string {
  const naz = NAZ[categoria] || 'Italian';
  const stov = STOVIGLIA[categoria] || 'on a simple plate';
  const da = zona ? ` from ${zona}` : '';
  return (
    `Professional food photography of a single plated vegan dish: ${titolo}, ` +
    `a classic traditional ${naz} recipe${da}, presented in its authentic classic ` +
    `plating exactly as this well-known dish is really served in real ${naz} food photos, ` +
    `${stov}. Made with ${ingredientiEn}, all fully cooked and combined into the ` +
    `finished dish; no raw or whole ingredients placed on top, no whole garlic cloves, ` +
    `no large raw vegetable chunks, no raw vegetable garnish. The dish is the only ` +
    `subject, centered, filling most of the frame. Only the single plated dish in the ` +
    `frame on a plain seamless studio background, nothing else behind or beside the ` +
    `plate, soft natural daylight from the side, realistic textures, shallow depth of ` +
    `field, appetizing but true to how the dish is really served. Strictly 100 percent ` +
    `plant based and vegan: absolutely no cheese, no grated cheese, no parmesan, no ` +
    `mozzarella, no cream, no butter, no egg, no meat, no fish, no seafood, no anchovies, ` +
    `no honey, no dairy. No cutlery, no salt shaker, no oil bottle, no jars, no bottles, ` +
    `no packaging, no labels, no napkin, no scattered ingredients around the plate, no ` +
    `hands, no people, no text anywhere, no logo, no watermark, no props, no objects in ` +
    `the background. Photorealistic, not illustration, not 3d render, no plastic look. ` +
    `Horizontal 4:3 composition.`
  );
}

// nano-banana-2 non ha negative_prompt: i divieti stanno gia' nel prompt sopra.
// image_search/google_search sono la messa a terra sul piatto reale: senza,
// i piatti regionali poco noti vengono inventati.
async function replicateImage(prompt: string): Promise<string> {
  const start = await fetch(
    'https://api.replicate.com/v1/models/google/nano-banana-2/predictions',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${REPLICATE_TOKEN}`,
        'Content-Type': 'application/json',
        Prefer: 'wait=60',
      },
      body: JSON.stringify({
        input: {
          prompt,
          aspect_ratio: '4:3',
          resolution: '2K',
          image_search: true,
          google_search: true,
          output_format: 'jpg',
        },
      }),
    },
  );
  if (!start.ok) throw new Error(`Replicate ${start.status}: ${await start.text()}`);
  let pred = await start.json();

  // Prefer:wait copre i casi normali; se scade si continua a interrogare.
  for (let i = 0; i < 40 && pred.status !== 'succeeded' && pred.status !== 'failed'; i++) {
    await new Promise((r) => setTimeout(r, 2000));
    const p = await fetch(pred.urls.get, {
      headers: { Authorization: `Bearer ${REPLICATE_TOKEN}` },
    });
    pred = await p.json();
  }
  if (pred.status !== 'succeeded') {
    throw new Error(`Generazione fallita: ${pred.error || pred.status}`);
  }
  const out = pred.output;
  const url = Array.isArray(out) ? out[0] : out;
  if (!url) throw new Error('Replicate non ha restituito immagini.');
  return String(url);
}

// -------------------------------------------------------------- assist ricetta
const SCHEMA_HINT = `{
  "titolo": "...",
  "categoria": "una di: Antipasti e contorni | Primi di pasta | Zuppe e minestre | Riso e cereali | Legumi e secondi vegetali | Lievitati, pane e pizza | Dolci | Medio Oriente e Nord Africa | India e subcontinente | Asia orientale e Sud Est | Americhe | Europa | Africa subsahariana",
  "zona": "regione o paese di origine",
  "porzioni": 4,
  "prep_min": 20,
  "cottura_min": 30,
  "difficolta": "Facile | Media | Difficile",
  "ingredienti": [{"testo": "800 g di melanzane", "nome": "melanzane"}],
  "passi": ["..."],
  "nutrizione": {"kcal": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0, "fiber_g": 0},
  "ingredienti_en": "i 5 ingredienti principali VISIBILI nel piatto finito, in inglese, separati da virgola"
}`;

async function assistRicetta(input: Record<string, unknown>) {
  const prompt =
    `Sei il nutrizionista che compila il database ricette base di Beet It! (100% vegetale).\n\n` +
    `Ricetta da strutturare:\n${JSON.stringify(input, null, 1)}\n\n` +
    `Regole NON negoziabili:\n` +
    `1. La ricetta e' VEGANA: mai uovo, latte, burro, formaggio, panna, miele, carne, pesce.\n` +
    `2. Ogni ingrediente ha la DOSE esplicita per il numero di porzioni indicato ` +
    `(es. "800 g di melanzane", "3 spicchi di aglio", "60 ml di olio evo").\n` +
    `3. In OGNI passo del procedimento va ripetuta la dose dell'ingrediente quando viene ` +
    `usato (es. "Friggi le 800 g di melanzane...", "Unisci i 400 g di pomodori pelati...").\n` +
    `4. "nome" di ogni ingrediente e' il sostantivo pulito, senza dose ne' preparazione ` +
    `(es. "melanzane", "olio extravergine di oliva").\n` +
    `5. La nutrizione e' PER PORZIONE, realistica per gli ingredienti e le dosi indicate.\n\n` +
    `Rispondi SOLO con JSON valido in questa forma:\n${SCHEMA_HINT}`;

  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-5',
      max_tokens: 3000,
      messages: [{ role: 'user', content: prompt }],
    }),
  });
  if (!r.ok) throw new Error(`Anthropic ${r.status}: ${await r.text()}`);
  const d = await r.json();
  // content[0] puo' essere un blocco "thinking": va preso il primo blocco di testo.
  const block = (d.content || []).find((b: { type: string }) => b.type === 'text');
  if (!block) throw new Error('Risposta AI senza testo');
  const txt = block.text as string;
  const a = txt.indexOf('{'), b = txt.lastIndexOf('}');
  if (a < 0 || b < a) throw new Error(`Risposta AI non in JSON: ${txt.slice(0, 200)}`);
  return JSON.parse(txt.slice(a, b + 1));
}

// ------------------------------------------------------------------- handler
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Solo POST' }, 405);

  const admin = createClient(SUPABASE_URL, SERVICE_KEY);

  // Chi chiama deve essere del team: la chiave Replicate non si presta a nessun altro.
  const jwt = (req.headers.get('Authorization') || '').replace('Bearer ', '');
  const { data: u } = await admin.auth.getUser(jwt);
  if (!u?.user) return json({ error: 'Non autenticato' }, 401);
  const { data: prof } = await admin
    .from('profiles').select('role').eq('id', u.user.id).single();
  if (!prof || (prof.role !== 'nutritionist' && prof.role !== 'admin')) {
    return json({ error: 'Account senza permessi team' }, 403);
  }

  let body: Record<string, any>;
  try { body = await req.json(); } catch { return json({ error: 'JSON non valido' }, 400); }

  try {
    if (body.action === 'assist') {
      return json({ ricetta: await assistRicetta(body.ricetta || {}) });
    }

    if (body.action === 'foto') {
      const titolo = String(body.titolo || '').trim();
      if (!titolo) return json({ error: 'Manca il titolo' }, 400);
      const prompt = promptFoto(
        titolo,
        String(body.categoria || ''),
        String(body.zona || ''),
        String(body.ingredienti_en || 'vegetables'),
      );
      const url = await replicateImage(prompt);

      const img = await fetch(url);
      if (!img.ok) throw new Error('Immagine non scaricabile da Replicate');
      const bytes = new Uint8Array(await img.arrayBuffer());

      const code = String(body.base_code || 'NEW').replace(/[^A-Za-z0-9_-]/g, '');
      const path = `${code}.jpg`;
      const up = await admin.storage.from('recipe-photos')
        .upload(path, bytes, { contentType: 'image/jpeg', upsert: true });
      if (up.error) throw new Error(`Storage: ${up.error.message}`);

      const pub = admin.storage.from('recipe-photos').getPublicUrl(path);
      // cache-buster: rigenerando la foto lo stesso path servirebbe la vecchia
      return json({ image_url: `${pub.data.publicUrl}?t=${Date.now()}`, prompt });
    }

    return json({ error: 'action sconosciuta' }, 400);
  } catch (e) {
    return json({ error: String((e as Error).message || e) }, 500);
  }
});

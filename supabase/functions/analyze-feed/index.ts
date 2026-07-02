// Edge Function: analyze-feed
// Analizza una sorgente (pagina web o account social) salvata dall'utente,
// trova le ricette e importa SOLO quelle conformi ai regimi alimentari attivi.
//
// In questo scheletro:
//  - per le sorgenti 'web' prova a estrarre le ricette linkate dalla pagina e
//    riusa la logica di import-recipe (JSON-LD) per ciascuna;
//  - la classificazione per regime (vegan, glutenFree, …) e i social richiedono
//    un passo AI/servizi dedicati: qui è predisposto il punto d'innesto.
//
// Deploy:  supabase functions deploy analyze-feed
// Body:    { source_id: string, diets: string[] }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { source_id, diets = [] } = await req.json();
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: source } = await supabase
      .from("feed_sources")
      .select("*")
      .eq("id", source_id)
      .single();
    if (!source) return json({ error: "Sorgente non trovata" }, 404);

    // 1) Trova le ricette candidate della sorgente.
    const candidates = await discoverRecipes(source);

    // 2) Filtra per regime e importa quelle nuove.
    const imported: unknown[] = [];
    for (const cand of candidates) {
      if (!matchesDiets(cand.diet_tags ?? [], diets)) continue;
      const { data: inserted } = await supabase
        .from("recipes")
        .insert({
          user_id: source.user_id,
          title: cand.title,
          source_url: cand.source_url,
          source_type: "web",
          diet_tags: cand.diet_tags ?? [],
        })
        .select()
        .single();
      if (inserted) imported.push(inserted);
    }

    await supabase
      .from("feed_sources")
      .update({ last_checked_at: new Date().toISOString() })
      .eq("id", source_id);

    return json({ imported }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

interface Candidate {
  title: string;
  source_url: string;
  diet_tags?: string[];
}

/** Una ricetta è conforme se soddisfa TUTTI i regimi attivi. */
function matchesDiets(recipeDiets: string[], active: string[]): boolean {
  return active.every((d) => recipeDiets.includes(d));
}

/**
 * Scopre le ricette di una sorgente.
 * TODO: implementazione reale —
 *  - web/blog: fetch pagina, estrai i link a ricette, per ognuna riusa
 *    import-recipe (JSON-LD) + classificazione regime via AI;
 *  - social (instagram/tiktok/youtube): API/oEmbed + structuring AI.
 * Qui restituisce lista vuota finché non colleghiamo i servizi.
 */
// deno-lint-ignore no-unused-vars
async function discoverRecipes(source: {
  type: string;
  reference: string;
}): Promise<Candidate[]> {
  return [];
}

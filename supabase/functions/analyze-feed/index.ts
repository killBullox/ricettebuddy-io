// Edge Function: analyze-feed
// Naviga il listato vegane di GialloZafferano e importa per l'utente le ricette
// conformi ai regimi attivi (complete di foto passi e video), evitando i
// duplicati. In produzione può girare anche in automatico (cron).
//
// Deploy:  supabase functions deploy analyze-feed
// Body:    { diets: string[], limit?: number, pages?: number }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { listVeganUrls, matchesDiets, parseRecipe } from "../_shared/gz.ts";
import { saveRecipe } from "../import-recipe/index.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { diets = [], limit = 30, pages = 15 } = await req.json().catch(() => ({}));
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );
    const { data: userData } = await supabase.auth.getUser();
    if (!userData?.user) return json({ error: "Non autenticato" }, 401);
    const userId = userData.user.id;

    // Ricette già presenti (per il dedup).
    const { data: existing } = await supabase
      .from("recipes")
      .select("source_url")
      .eq("user_id", userId);
    const seen = new Set((existing ?? []).map((r: { source_url: string }) => r.source_url));

    const urls = await listVeganUrls(pages);
    const imported: unknown[] = [];
    for (const u of urls) {
      if (imported.length >= limit) break;
      if (seen.has(u)) continue;
      let r;
      try {
        r = await parseRecipe(u);
      } catch {
        continue;
      }
      if (!r || !matchesDiets(r.diet_tags, diets)) continue;
      try {
        const saved = await saveRecipe(supabase, userId, r);
        imported.push(saved);
        seen.add(u);
      } catch { /* salta la singola ricetta in errore */ }
    }
    return json({ imported }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

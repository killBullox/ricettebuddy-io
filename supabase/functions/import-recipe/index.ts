// Edge Function: import-recipe
// Importa una singola ricetta da un URL (GialloZafferano e simili con JSON-LD),
// la salva per l'utente autenticato e la restituisce.
//
// Deploy:  supabase functions deploy import-recipe
// Body:    { url: string }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { parseRecipe, type ParsedRecipe } from "../_shared/gz.ts";

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

// deno-lint-ignore no-explicit-any
export async function saveRecipe(supabase: any, userId: string, r: ParsedRecipe) {
  const { data: inserted, error } = await supabase
    .from("recipes")
    .insert({
      user_id: userId,
      title: r.title,
      image_url: r.image_url,
      source_url: r.source_url,
      source_type: "web",
      cook_minutes: r.cook_minutes,
      diet_tags: r.diet_tags,
      video_url: r.video_url,
      video_id: r.video_id,
      video_mp4: r.video_mp4,
    })
    .select("*")
    .single();
  if (error) throw error;
  const id = inserted.id;
  if (r.ingredients.length) {
    await supabase.from("ingredients").insert(
      r.ingredients.map((ing, i) => ({
        recipe_id: id, user_id: userId, position: i, raw_text: ing.raw_text,
      })),
    );
  }
  if (r.steps.length) {
    await supabase.from("steps").insert(
      r.steps.map((s) => ({
        recipe_id: id, user_id: userId, position: s.position,
        text: s.text, image: s.image,
      })),
    );
  }
  return inserted;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { url } = await req.json();
    if (!url || !/^https?:\/\//.test(url)) {
      return json({ error: "Link non valido." }, 400);
    }
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );
    const { data: userData } = await supabase.auth.getUser();
    if (!userData?.user) return json({ error: "Non autenticato" }, 401);

    const recipe = await parseRecipe(url);
    if (!recipe) return json({ error: "Ricetta non riconosciuta" }, 422);
    const saved = await saveRecipe(supabase, userData.user.id, recipe);
    return json(saved, 201);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

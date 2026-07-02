// Edge Function: creative-generate  (lo "Chef creativo" — idee nuove)
// Legge dispensa + profilo gusti dell'utente e chiede a un LLM di inventare
// ricette strutturate che privilegiano gli ingredienti disponibili.
// Le API key restano lato server.
//
// Env richieste:  ANTHROPIC_API_KEY  (opzionale in dev: senza, ritorna un mock)
// Deploy:  supabase functions deploy creative-generate

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const MODEL = "claude-sonnet-5";

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { count = 3, max_minutes, diet = [], exclude_allergens = [] } =
      await req.json().catch(() => ({}));

    // Client con il JWT del chiamante → RLS applica i dati del solo utente.
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: pantry } = await supabase
      .from("pantry_items")
      .select("raw_text, normalized_name");
    const { data: tastes } = await supabase.rpc("taste_top_ingredients", {
      max_rows: 20,
    });

    const pantryList = (pantry ?? []).map((p) => p.raw_text);
    const tasteList = (tastes ?? []).map((t: { normalized_name: string }) =>
      t.normalized_name
    );

    const recipes = await generate({
      count,
      maxMinutes: max_minutes,
      diet,
      excludeAllergens: exclude_allergens,
      pantry: pantryList,
      tastes: tasteList,
    });

    return json({ recipes }, 200);
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

interface GenArgs {
  count: number;
  maxMinutes?: number;
  diet: string[];
  excludeAllergens: string[];
  pantry: string[];
  tastes: string[];
}

async function generate(args: GenArgs) {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return mock(args); // dev senza chiave → funziona end-to-end

  const system =
    "Sei uno chef che inventa ricette realistiche e gustose. " +
    "Privilegia gli ingredienti disponibili in dispensa e i gusti dell'utente. " +
    "Rispondi SOLO con JSON valido conforme allo schema richiesto, in italiano.";

  const prompt = [
    `Genera ${args.count} idee di ricetta.`,
    args.pantry.length
      ? `Dispensa disponibile: ${args.pantry.join(", ")}.`
      : "Dispensa non specificata: proponi ricette con ingredienti comuni.",
    args.tastes.length
      ? `Ingredienti graditi all'utente (ordine di preferenza): ${args.tastes.join(", ")}.`
      : "",
    args.maxMinutes ? `Tempo massimo: ${args.maxMinutes} minuti.` : "",
    args.diet.length ? `Vincoli dietetici: ${args.diet.join(", ")}.` : "",
    args.excludeAllergens.length
      ? `Escludi allergeni: ${args.excludeAllergens.join(", ")}.`
      : "",
    "",
    'Schema JSON: {"recipes":[{"title":string,"prep_minutes":number,',
    '"cook_minutes":number,"servings":number,',
    '"ingredients":[{"raw_text":string}],',
    '"steps":[{"position":number,"text":string}]}]}',
  ].filter(Boolean).join("\n");

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 2000,
      system,
      messages: [{ role: "user", content: prompt }],
    }),
  });

  const data = await res.json();
  const text: string = data?.content?.[0]?.text ?? "{}";
  const parsed = JSON.parse(extractJson(text));
  return parsed.recipes ?? [];
}

/** Estrae il primo blocco JSON dal testo del modello. */
function extractJson(text: string): string {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  return start >= 0 && end > start ? text.slice(start, end + 1) : "{}";
}

/** Fallback deterministico senza LLM: usa i primi ingredienti disponibili. */
function mock(args: GenArgs) {
  const base = args.pantry.length ? args.pantry : ["pasta", "pomodoro", "aglio"];
  return Array.from({ length: args.count }, (_, i) => ({
    title: `Idea ${i + 1} con ${base[0]}`,
    prep_minutes: 10,
    cook_minutes: 20,
    servings: 2,
    ingredients: base.slice(0, 5).map((raw_text) => ({ raw_text })),
    steps: [
      { position: 0, text: "Prepara gli ingredienti." },
      { position: 1, text: `Cuoci con ${base.join(", ")}.` },
      { position: 2, text: "Impiatta e servi." },
    ],
  }));
}

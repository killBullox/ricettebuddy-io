# Backend Supabase

Schema, policy e funzioni server-side di RicetteBuddy.

```
migrations/   schema SQL (recipes, ingredienti, piano, spesa, dispensa, gusti, RLS)
functions/    Edge Functions (Deno/TypeScript)
  import-recipe/      F1/F2 — estrae schema.org/Recipe (JSON-LD) da un URL
  creative-generate/  Chef creativo — genera ricette da dispensa + gusti (LLM)
```

## Avvio locale

```bash
supabase init          # se non già inizializzato (genera config.toml)
supabase start         # stack locale via Docker
supabase db reset      # applica le migrations/
supabase functions serve import-recipe
supabase functions serve creative-generate
```

## Deploy

```bash
supabase link --project-ref <ref>
supabase db push                       # migrations sul progetto remoto
supabase functions deploy import-recipe
supabase functions deploy creative-generate
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...   # per la generazione AI
```

## Note

- Tutte le tabelle hanno **RLS**: ogni utente vede solo i propri dati
  (`user_id = auth.uid()`), vedi `migrations/*_rls.sql`.
- Lo "Chef creativo" usa due RPC Postgres (`recipes_doable_from_pantry`,
  `taste_top_ingredients`) + la Edge Function `creative-generate`.
- Senza `ANTHROPIC_API_KEY`, `creative-generate` ritorna un mock deterministico
  (utile in sviluppo).
- La dimensione del vettore in `recipe_embeddings` (1536) va allineata al modello
  di embedding scelto.

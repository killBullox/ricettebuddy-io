-- Stagionalità: mesi (1-12) in cui la ricetta è "di stagione", ricavati dai suoi
-- ingredienti tramite il calendario ortofrutta italiano (tools gen_stagione.py).
-- Usato dal generatore piano (preferenza) e dall'app (badge/filtro "Di stagione").
alter table public.recipes add column if not exists season_months smallint[];

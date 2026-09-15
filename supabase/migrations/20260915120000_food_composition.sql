-- Composizione alimenti (micronutrienti set critico vegano) per ingrediente.
create table if not exists public.food_composition (
  ing_id text primary key,
  nome_it text, nome_en text, categoria text,
  fdc_id bigint,
  per_100g jsonb not null default '{}'::jsonb,
  fonte text,
  updated_at timestamptz not null default now()
);
alter table public.food_composition enable row level security;
drop policy if exists food_comp_team on public.food_composition;
create policy food_comp_team on public.food_composition for all using (is_team()) with check (is_team());
drop policy if exists food_comp_read on public.food_composition;
create policy food_comp_read on public.food_composition for select using (true);

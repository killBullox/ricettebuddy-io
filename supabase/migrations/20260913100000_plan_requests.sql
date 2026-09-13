-- Richieste di piano alimentare dal cliente: con o senza videoconsulto.
-- Senza videoconsulto il cliente compila i dati antropometrici (usati dal team);
-- con videoconsulto i dati li raccoglie il team durante/dopo la chiamata.
create table if not exists public.plan_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  wants_video boolean not null default false,
  birth_date date,
  sex text,
  height_cm numeric,
  weight_kg numeric,
  target_weight_kg numeric,
  weight_history text,
  pathologies text,
  activity text,
  preferences text,
  goal text,                 -- dimagrimento | massa | abitudini
  status text not null default 'pending',  -- pending | in_progress | done
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists plan_requests_user_idx on public.plan_requests(user_id, created_at desc);

alter table public.plan_requests enable row level security;
-- il cliente gestisce le proprie richieste
drop policy if exists plan_requests_owner on public.plan_requests;
create policy plan_requests_owner on public.plan_requests
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
-- il team (nutritionist/admin) vede e modifica tutte
drop policy if exists plan_requests_team on public.plan_requests;
create policy plan_requests_team on public.plan_requests
  for all using (is_team()) with check (is_team());

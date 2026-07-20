-- Beet-It — ruoli utente, catalogo base, push nutrizionista -> cliente.

-- 1) Ruolo utente (cliente | nutrizionista | admin del team)
alter table profiles add column if not exists role text not null default 'client'
  check (role in ('client', 'nutritionist', 'admin'));
alter table profiles add column if not exists full_name text;

-- 2) Codice ricetta base (IT001, WW001, …) sulle ricette del catalogo pubblico
alter table recipes add column if not exists base_code text;
create unique index if not exists recipes_base_code_uidx
  on recipes (base_code) where base_code is not null;

-- 3) Profilo automatico alla registrazione (ruolo cliente di default)
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- 4) Tracciamento dei push di piano dal nutrizionista al cliente
create table if not exists plan_pushes (
  id              uuid primary key default gen_random_uuid(),
  nutritionist_id uuid not null references auth.users (id) on delete cascade,
  client_id       uuid not null references auth.users (id) on delete cascade,
  week_start      date,
  n_recipes       int  not null default 0,
  note            text,
  created_at      timestamptz not null default now()
);
alter table plan_pushes enable row level security;
drop policy if exists plan_pushes_nutri on plan_pushes;
create policy plan_pushes_nutri on plan_pushes
  for select using (nutritionist_id = auth.uid());
drop policy if exists plan_pushes_client on plan_pushes;
create policy plan_pushes_client on plan_pushes
  for select using (client_id = auth.uid());

-- 5) Il team (nutritionist/admin) puo leggere i profili per cercare i clienti via email.
--    (helper: ruolo dell'utente corrente)
create or replace function current_role_is(target text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = target);
$$;
drop policy if exists profiles_team_read on profiles;
create policy profiles_team_read on profiles
  for select using (id = auth.uid() or current_role_is('nutritionist') or current_role_is('admin'));

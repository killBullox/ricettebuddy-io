-- Piano alimentare settimanale che il nutrizionista compone nell'area team e
-- "pusha" al cliente. Il contenuto referenzia le ricette BASE per base_code;
-- all'import (lato app) le ricette base vengono copiate nella collezione del
-- cliente e diventano meal_plan_entries (la tabella che l'app gia' legge).
--
-- plan_pushes (vecchia, solo riassunto n_recipes) e' superata da queste due
-- tabelle: la lasciamo perche' non fa danno, ma non la usa piu' nessuno.

-- Un pasto puo' avere piu' piatti (primo + secondo + dolce): e' cosi' che l'app
-- gia' inserisce le voci, e cosi' un piano del nutrizionista compone il pranzo.
-- Il vecchio unique(user_id,date,slot) lo impediva -> lo togliamo.
alter table public.meal_plan_entries
  drop constraint if exists meal_plan_entries_user_id_date_slot_key;

create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references auth.users(id) on delete cascade,
  nutritionist_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  note text,
  status text not null default 'pending' check (status in ('pending','imported')),
  created_at timestamptz not null default now()
);
create index if not exists meal_plans_client_idx on public.meal_plans(client_id, status);

create table if not exists public.meal_plan_items (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.meal_plans(id) on delete cascade,
  day_index int not null check (day_index between 0 and 6),  -- 0 = lunedi'
  slot meal_slot not null,                                   -- breakfast/lunch/snack/dinner
  base_code text not null,
  title text not null default '',
  position int not null default 0
);
create index if not exists meal_plan_items_plan_idx on public.meal_plan_items(plan_id);

alter table public.meal_plans enable row level security;
alter table public.meal_plan_items enable row level security;

-- Il team gestisce i piani che ha creato lui; il cliente li legge soltanto.
-- Lo stato "imported" lo scrive la Edge Function (service role), non il client:
-- cosi' il cliente non puo' toccare la testata del proprio piano.
create policy meal_plans_team on public.meal_plans for all to authenticated
  using (nutritionist_id = auth.uid() and public.is_team())
  with check (nutritionist_id = auth.uid() and public.is_team());
create policy meal_plans_client_read on public.meal_plans for select to authenticated
  using (client_id = auth.uid());

create policy items_team on public.meal_plan_items for all to authenticated
  using (public.is_team() and exists (
    select 1 from public.meal_plans p where p.id = plan_id and p.nutritionist_id = auth.uid()))
  with check (public.is_team() and exists (
    select 1 from public.meal_plans p where p.id = plan_id and p.nutritionist_id = auth.uid()));
create policy items_client_read on public.meal_plan_items for select to authenticated
  using (exists (
    select 1 from public.meal_plans p where p.id = plan_id and p.client_id = auth.uid()));

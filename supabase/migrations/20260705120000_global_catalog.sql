-- BeetIt — catalogo ricette GLOBALE (riempito dal worker) + preferiti utente.
-- Le ricette del catalogo hanno user_id NULL e sono leggibili da tutti; le
-- ricette personali (create dall'utente) restano con user_id = proprietario.

-- Ricette globali: user_id opzionale + campi di arricchimento.
alter table recipes alter column user_id drop not null;
alter table recipes add column if not exists category   text;
alter table recipes add column if not exists cuisine    text;
alter table recipes add column if not exists difficulty text;
alter table recipes add column if not exists allergens  text[] not null default '{}';
alter table recipes add column if not exists nutrition  jsonb;   -- per porzione
alter table recipes add column if not exists creator    text;    -- handle/nome creator
alter table recipes add column if not exists platform   text;    -- instagram|web|pinterest
create index if not exists recipes_catalog_idx on recipes (created_at desc) where user_id is null;

alter table ingredients alter column user_id drop not null;
alter table steps       alter column user_id drop not null;

-- Lettura pubblica del catalogo (righe con user_id NULL).
drop policy if exists "recipes_catalog_read" on recipes;
create policy "recipes_catalog_read" on recipes for select using (user_id is null);
drop policy if exists "ingredients_catalog_read" on ingredients;
create policy "ingredients_catalog_read" on ingredients for select using (user_id is null);
drop policy if exists "steps_catalog_read" on steps;
create policy "steps_catalog_read" on steps for select using (user_id is null);

-- Preferiti utente sul catalogo.
create table if not exists user_favorites (
  user_id    uuid not null references auth.users (id) on delete cascade,
  recipe_id  uuid not null references recipes (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);
alter table user_favorites enable row level security;
drop policy if exists "user_favorites_owner" on user_favorites;
create policy "user_favorites_owner" on user_favorites
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Creator monitorati dal worker (sorgenti del catalogo).
create table if not exists creators (
  id              uuid primary key default gen_random_uuid(),
  platform        text not null default 'instagram',
  handle          text not null,
  name            text,
  active          boolean not null default true,
  last_checked_at timestamptz,
  created_at      timestamptz not null default now(),
  unique (platform, handle)
);

-- RicetteBuddy — sorgenti/feed + regimi alimentari

-- Regimi soddisfatti da una ricetta (nomi enum lato client: vegan, vegetarian,
-- glutenFree, lactoseFree, pescetarian).
alter table recipes add column if not exists diet_tags text[] not null default '{}';
create index if not exists recipes_diet_tags_idx on recipes using gin (diet_tags);

-- Regimi preferiti dall'utente (filtro import).
alter table profiles add column if not exists diets text[] not null default '{}';

-- Sorgenti/feed da cui importare automaticamente.
create type source_type as enum ('web', 'instagram', 'tiktok', 'youtube', 'pinterest');

create table feed_sources (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users (id) on delete cascade,
    type            source_type not null default 'web',
    reference       text not null,          -- URL pagina o handle social
    name            text not null,
    auto_import     boolean not null default true,
    last_checked_at timestamptz,
    created_at      timestamptz not null default now()
);
create index feed_sources_user_idx on feed_sources (user_id);

alter table feed_sources enable row level security;
create policy "feed_sources_owner" on feed_sources
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

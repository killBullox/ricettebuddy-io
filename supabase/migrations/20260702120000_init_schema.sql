-- RicetteBuddy — schema iniziale
-- Postgres / Supabase. Tutti i dati sono per-utente e protetti da RLS (vedi
-- 20260702120200_rls.sql). Le colonne monetarie/AI stanno lato server.

-- ---------------------------------------------------------------------------
-- Estensioni
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "vector";      -- pgvector: embedding gusti/ricette

-- ---------------------------------------------------------------------------
-- Tipi enumerati
-- ---------------------------------------------------------------------------
create type recipe_source as enum ('manual', 'web', 'social', 'photo', 'generated');
create type meal_slot     as enum ('breakfast', 'lunch', 'snack', 'dinner');

-- ---------------------------------------------------------------------------
-- Profilo utente (preferenze) — 1:1 con auth.users
-- ---------------------------------------------------------------------------
create table profiles (
    id                 uuid primary key references auth.users (id) on delete cascade,
    preferred_language text        not null default 'it',
    measurement_system text        not null default 'metric'
        check (measurement_system in ('metric', 'imperial')),
    subscription_tier  text        not null default 'free'
        check (subscription_tier in ('free', 'premium')),
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Ricette + ingredienti + passi
-- ---------------------------------------------------------------------------
create table recipes (
    id                uuid primary key default gen_random_uuid(),
    user_id           uuid not null references auth.users (id) on delete cascade,
    title             text not null,
    image_url         text,
    source_url        text,
    source_type       recipe_source not null default 'manual',
    original_language text,
    prep_minutes      int,
    cook_minutes      int,
    servings          int  not null default 2 check (servings > 0),
    tags              text[] not null default '{}',
    is_favorite       boolean not null default false,
    -- Segnali di gusto per lo "Chef creativo":
    cooked_count      int not null default 0,      -- quante volte usata nel piano/segnata cucinata
    last_cooked_at    timestamptz,
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now()
);
create index recipes_user_idx      on recipes (user_id);
create index recipes_favorite_idx  on recipes (user_id, is_favorite);
create index recipes_updated_idx   on recipes (user_id, updated_at desc);
create index recipes_tags_idx      on recipes using gin (tags);

create table ingredients (
    id              uuid primary key default gen_random_uuid(),
    recipe_id       uuid not null references recipes (id) on delete cascade,
    user_id         uuid not null references auth.users (id) on delete cascade,
    position        int  not null default 0,
    raw_text        text not null,               -- "200 g di farina 00"
    quantity        numeric,                     -- 200
    unit            text,                        -- "g"
    normalized_name text,                        -- "farina" (per aggregazione e gusti)
    aisle_category  text                         -- corsia supermercato
);
create index ingredients_recipe_idx     on ingredients (recipe_id);
create index ingredients_user_idx       on ingredients (user_id);
create index ingredients_normname_idx   on ingredients (user_id, normalized_name);

create table steps (
    id        uuid primary key default gen_random_uuid(),
    recipe_id uuid not null references recipes (id) on delete cascade,
    user_id   uuid not null references auth.users (id) on delete cascade,
    position  int  not null default 0,
    text      text not null
);
create index steps_recipe_idx on steps (recipe_id);

-- ---------------------------------------------------------------------------
-- Piano pasti
-- ---------------------------------------------------------------------------
create table meal_plan_entries (
    id        uuid primary key default gen_random_uuid(),
    user_id   uuid not null references auth.users (id) on delete cascade,
    date      date not null,
    slot      meal_slot not null,
    recipe_id uuid references recipes (id) on delete set null,
    servings  int not null default 2 check (servings > 0),
    created_at timestamptz not null default now(),
    unique (user_id, date, slot)                 -- uno slot per giorno per utente
);
create index meal_plan_user_date_idx on meal_plan_entries (user_id, date);

-- ---------------------------------------------------------------------------
-- Lista della spesa
-- ---------------------------------------------------------------------------
create table shopping_items (
    id               uuid primary key default gen_random_uuid(),
    user_id          uuid not null references auth.users (id) on delete cascade,
    name             text not null,
    quantity         numeric,
    unit             text,
    aisle_category   text,
    is_checked       boolean not null default false,
    source_recipe_id uuid references recipes (id) on delete set null,
    created_at       timestamptz not null default now()
);
create index shopping_user_idx on shopping_items (user_id);

-- ---------------------------------------------------------------------------
-- Dispensa (per lo "Chef creativo" e gli avvisi "usa prima che scada")
-- ---------------------------------------------------------------------------
create table pantry_items (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users (id) on delete cascade,
    raw_text        text not null,
    normalized_name text not null,               -- chiave di match con gli ingredienti
    quantity        numeric,
    unit            text,
    aisle_category  text,
    expiry_date     date,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);
create index pantry_user_idx       on pantry_items (user_id);
create index pantry_normname_idx   on pantry_items (user_id, normalized_name);

-- ---------------------------------------------------------------------------
-- Traduzioni (F9) — testo originale mantenuto sulla ricetta, traduzioni a parte
-- ---------------------------------------------------------------------------
create table recipe_translations (
    id         uuid primary key default gen_random_uuid(),
    recipe_id  uuid not null references recipes (id) on delete cascade,
    user_id    uuid not null references auth.users (id) on delete cascade,
    language   text not null,
    -- { "title": ..., "ingredients": [...], "steps": [...] }
    content    jsonb not null,
    created_at timestamptz not null default now(),
    unique (recipe_id, language)
);
create index recipe_translations_recipe_idx on recipe_translations (recipe_id);

-- ---------------------------------------------------------------------------
-- Embedding ricette (pgvector) — similarità per lo "Chef creativo"
-- dimensione 1536 = OpenAI text-embedding-3-small (adattare al modello scelto)
-- ---------------------------------------------------------------------------
create table recipe_embeddings (
    recipe_id  uuid primary key references recipes (id) on delete cascade,
    user_id    uuid not null references auth.users (id) on delete cascade,
    embedding  vector(1536) not null,
    created_at timestamptz not null default now()
);
create index recipe_embeddings_ivf_idx
    on recipe_embeddings using ivfflat (embedding vector_cosine_ops) with (lists = 100);

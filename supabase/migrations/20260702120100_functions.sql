-- RicetteBuddy — trigger e funzioni server-side

-- ---------------------------------------------------------------------------
-- updated_at automatico
-- ---------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger recipes_set_updated_at
    before update on recipes
    for each row execute function set_updated_at();

create trigger profiles_set_updated_at
    before update on profiles
    for each row execute function set_updated_at();

create trigger pantry_set_updated_at
    before update on pantry_items
    for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- Crea automaticamente un profilo quando nasce un utente
-- ---------------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id) values (new.id)
    on conflict (id) do nothing;
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_user();

-- ---------------------------------------------------------------------------
-- CHEF CREATIVO — "Puoi già farle": ricette del ricettario fattibili con la
-- dispensa attuale. Restituisce copertura ingredienti e ciò che manca.
-- Match sul normalized_name (case-insensitive). Ignora ingredienti senza nome
-- normalizzato (non ancora processati).
-- ---------------------------------------------------------------------------
create or replace function recipes_doable_from_pantry(min_coverage numeric default 0.6)
returns table (
    recipe_id        uuid,
    title            text,
    total_named      int,
    have_count       int,
    coverage         numeric,
    missing_names    text[]
)
language sql
stable
security invoker
as $$
    with pantry as (
        select distinct lower(normalized_name) as name
        from pantry_items
        where user_id = auth.uid()
    ),
    named as (
        select i.recipe_id, lower(i.normalized_name) as name
        from ingredients i
        where i.user_id = auth.uid()
          and i.normalized_name is not null
          and length(trim(i.normalized_name)) > 0
    ),
    per_recipe as (
        select
            n.recipe_id,
            count(*)                                        as total_named,
            count(*) filter (where p.name is not null)      as have_count,
            array_agg(distinct n.name) filter (where p.name is null) as missing_names
        from named n
        left join pantry p on p.name = n.name
        group by n.recipe_id
    )
    select
        r.id,
        r.title,
        pr.total_named,
        pr.have_count,
        round(pr.have_count::numeric / nullif(pr.total_named, 0), 2) as coverage,
        coalesce(pr.missing_names, '{}')
    from per_recipe pr
    join recipes r on r.id = pr.recipe_id
    where pr.total_named > 0
      and (pr.have_count::numeric / pr.total_named) >= min_coverage
    order by coverage desc, r.is_favorite desc, r.cooked_count desc;
$$;

-- ---------------------------------------------------------------------------
-- CHEF CREATIVO — profilo gusti: ingredienti più ricorrenti nelle ricette
-- preferite / più cucinate. Alimenta il prompt di generazione AI.
-- Peso = 3 se preferita + numero di volte cucinata + 1.
-- ---------------------------------------------------------------------------
create or replace function taste_top_ingredients(max_rows int default 25)
returns table (normalized_name text, score numeric)
language sql
stable
security invoker
as $$
    select
        lower(i.normalized_name) as normalized_name,
        sum((case when r.is_favorite then 3 else 0 end) + r.cooked_count + 1)::numeric as score
    from ingredients i
    join recipes r on r.id = i.recipe_id
    where i.user_id = auth.uid()
      and i.normalized_name is not null
      and length(trim(i.normalized_name)) > 0
    group by lower(i.normalized_name)
    order by score desc
    limit max_rows;
$$;

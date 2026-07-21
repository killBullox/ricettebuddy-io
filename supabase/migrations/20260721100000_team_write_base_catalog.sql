-- Il team nutrizione (nutritionist/admin) puo' SCRIVERE il catalogo base
-- (le righe con user_id IS NULL). Restano invariate:
--   *_catalog_read  -> tutti leggono il catalogo base
--   *_owner         -> ognuno gestisce solo le proprie ricette
--
-- Il catalogo base non appartiene a nessun utente: e' la libreria condivisa da
-- cui il cliente importa e su cui il nutrizionista costruisce i piani.

create or replace function public.is_team()
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and role in ('nutritionist','admin')
  );
$$;

create policy recipes_team_write on public.recipes
  for all to authenticated
  using (user_id is null and public.is_team())
  with check (user_id is null and public.is_team());

create policy ingredients_team_write on public.ingredients
  for all to authenticated
  using (user_id is null and public.is_team())
  with check (user_id is null and public.is_team());

create policy steps_team_write on public.steps
  for all to authenticated
  using (user_id is null and public.is_team())
  with check (user_id is null and public.is_team());

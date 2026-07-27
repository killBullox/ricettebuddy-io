-- Gestione del catalogo cibi pronti da parte del team (nutritionist/admin):
-- consultare, modificare, eliminare, aggiungere (via Edge Function off-product).
alter table public.packaged_foods add column if not exists updated_at timestamptz default now();
drop policy if exists packaged_foods_team_write on public.packaged_foods;
create policy packaged_foods_team_write on public.packaged_foods for all to authenticated
  using (public.is_team()) with check (public.is_team());

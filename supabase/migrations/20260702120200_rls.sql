-- RicetteBuddy — Row Level Security: ogni utente vede/modifica solo i propri dati.

alter table profiles            enable row level security;
alter table recipes             enable row level security;
alter table ingredients         enable row level security;
alter table steps               enable row level security;
alter table meal_plan_entries   enable row level security;
alter table shopping_items      enable row level security;
alter table pantry_items        enable row level security;
alter table recipe_translations enable row level security;
alter table recipe_embeddings   enable row level security;

-- profiles: la riga è l'utente stesso (id = auth.uid())
create policy "profiles_owner" on profiles
    for all using (id = auth.uid()) with check (id = auth.uid());

-- Helper: tutte le altre tabelle hanno user_id.
-- (Una policy per tabella, azione ALL, ownership su user_id.)
create policy "recipes_owner" on recipes
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "ingredients_owner" on ingredients
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "steps_owner" on steps
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "meal_plan_owner" on meal_plan_entries
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "shopping_owner" on shopping_items
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "pantry_owner" on pantry_items
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "recipe_translations_owner" on recipe_translations
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "recipe_embeddings_owner" on recipe_embeddings
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

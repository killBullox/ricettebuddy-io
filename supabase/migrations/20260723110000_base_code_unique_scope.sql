-- base_code identifica una ricetta del CATALOGO BASE (IT001, WW051...).
-- Quando il cliente importa un piano, la ricetta base viene COPIATA nella sua
-- collezione mantenendo lo stesso base_code (serve per il dedup all'import).
-- Percio' l'unicita' di base_code deve valere solo per il catalogo (user_id IS
-- NULL), non globalmente: altrimenti la copia del cliente collide con la base.

drop index if exists public.recipes_base_code_uidx;
create unique index recipes_base_code_uidx
  on public.recipes (base_code)
  where base_code is not null and user_id is null;

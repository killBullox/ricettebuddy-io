-- Catalogo cibi vegani pronti (Open Food Facts) + sync settimanale.
-- La tabella packaged_foods è creata a parte (import iniziale).
-- Sync: Edge Function `sync-off` (deploy con --no-verify-jwt; protetta da
-- SYNC_SECRET) invocata ogni lunedì 05:00 UTC via pg_cron + pg_net.
create extension if not exists pg_cron;
create extension if not exists pg_net;
-- Lo scheduling con il segreto viene creato via SQL fuori dal versionamento
-- (cron.schedule('sync-off-weekly', '0 5 * * 1', ...)) per non committare il segreto.

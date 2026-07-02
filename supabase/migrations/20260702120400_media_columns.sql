-- RicetteBuddy — colonne per media reali importati (foto dei passaggi, video)

-- Foto per singolo passaggio.
alter table steps add column if not exists image text;

-- Video associato alla ricetta e galleria del procedimento.
alter table recipes add column if not exists video_url  text;   -- poster
alter table recipes add column if not exists video_id   text;
alter table recipes add column if not exists video_mp4  text;   -- MP4 diretto
alter table recipes add column if not exists step_gallery text[] not null default '{}';

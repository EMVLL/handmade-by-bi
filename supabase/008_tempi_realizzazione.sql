-- =====================================================================
--  Handmade by Bi — 008: tempi di realizzazione dei pezzi
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase, PRIMA di installare
--  sito v2.5 e app v2.9: entrambi leggono e scrivono queste colonne.
--  Per ogni pezzo: un testo libero (es. "7–10 giorni") e un interruttore
--  per mostrarlo sul sito. All'inizio è spento su tutti i pezzi, quindi
--  il sito non cambia finché Benedetta non lo accende.
--  Si può rieseguire senza danni.
-- =====================================================================

begin;

alter table public.products add column if not exists lead_time text;
alter table public.products add column if not exists show_lead_time boolean not null default false;

alter table public.products drop constraint if exists products_lead_time_check;
alter table public.products add constraint products_lead_time_check
  check (char_length(lead_time) between 1 and 80);

commit;

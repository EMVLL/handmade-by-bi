-- =====================================================================
--  Handmade by Bi — 010: centro delle foto nei riquadri
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase, PRIMA di installare
--  sito v2.9 e app v3.1: entrambi leggono e scrivono questa colonna.
--  Per ogni foto di un pezzo, il punto da tenere al centro quando la foto
--  viene ritagliata in un quadrato (griglie, nastro, miniature):
--    photo_focus = { "<percorso della foto>": { "x": 0-100, "y": 0-100 } }
--  Foto senza voce = centro della foto, come oggi. Nessun pezzo cambia
--  aspetto finché Benedetta non sceglie un centro.
--  Si può rieseguire senza danni.
-- =====================================================================

begin;

alter table public.products add column if not exists photo_focus jsonb not null default '{}';

-- Controllo dei valori (come per foto e opzioni, con un trigger)
create or replace function private.validate_photo_focus()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if jsonb_typeof(new.photo_focus) <> 'object'
     or (select count(*) from jsonb_object_keys(new.photo_focus)) > 24
     or exists (
       select 1 from jsonb_each(new.photo_focus) e
       -- (Postgres non accetta {1,300} nelle espressioni regolari: lunghezza a parte)
       where char_length(e.key) > 300
          or e.key !~ '^[a-zA-Z0-9/_.-]+$'
          or jsonb_typeof(e.value) <> 'object'
          or jsonb_typeof(e.value->'x') is distinct from 'number'
          or jsonb_typeof(e.value->'y') is distinct from 'number'
          or (e.value->>'x')::numeric not between 0 and 100
          or (e.value->>'y')::numeric not between 0 and 100)
  then
    raise exception 'Centro delle foto non valido'
      using errcode = 'check_violation';
  end if;
  return new;
end $$;
revoke all on function private.validate_photo_focus() from public;

drop trigger if exists products_photo_focus on public.products;
create trigger products_photo_focus before insert or update on public.products
  for each row execute function private.validate_photo_focus();

commit;

-- =====================================================================
--  Handmade by Bi — 003: "Il mio negozio"
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase.
--  1. Copertina per ogni categoria
--  2. "Aspetto" per ogni sezione: sfondo, carattere e grandezza del titolo
--  3. Più forme di visualizzazione per categorie e griglia dei lavori
--  4. Ordine dei campi nei moduli dell'app (x-order)
--  5. Aggiornamento IMMEDIATO del sito quando Benedetta salva
--  Nessun contenuto esistente viene modificato: gli schemi si allargano,
--  quindi tutto ciò che era valido resta valido.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Copertina delle categorie
-- ---------------------------------------------------------------------
alter table public.collections add column if not exists cover_path text;
alter table public.collections drop constraint if exists collections_cover_path_check;
alter table public.collections add constraint collections_cover_path_check
  check (char_length(cover_path) <= 300 and cover_path ~ '^[a-zA-Z0-9/_.-]+$');

-- Correzione di due vincoli dello script 001: Postgres non accetta
-- ripetizioni oltre 255 nelle espressioni regolari ({1,300}), quindi
-- impostare un logo o un link nel menu avrebbe dato errore.
alter table public.site_settings drop constraint if exists site_settings_logo_path_check;
alter table public.site_settings add constraint site_settings_logo_path_check
  check (char_length(logo_path) <= 300 and logo_path ~ '^[a-zA-Z0-9/_.-]+$');
alter table public.menu_items drop constraint if exists menu_items_url_check;
alter table public.menu_items add constraint menu_items_url_check
  check (char_length(url) <= 300 and url ~ '^(https://|/)[^\s]*$');

-- ---------------------------------------------------------------------
-- 2. Aspetto comune alle sezioni con un titolo
-- ---------------------------------------------------------------------
update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none",
                 "x-label": "Sfondo della sezione", "x-group": "style",
                 "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]},
  "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display",
                          "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme",
                 "x-label": "Carattere del titolo", "x-group": "style", "x-widget": "font",
                 "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora",
                                   "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]},
  "title_size": {"enum": ["s", "m", "l"], "default": "m",
                 "x-label": "Grandezza del titolo", "x-group": "style",
                 "x-enum-labels": ["Piccolo", "Medio", "Grande"]}
}$j$::jsonb)
where type not in ('banner', 'spacer');

-- ---------------------------------------------------------------------
-- 3. Più forme di visualizzazione
-- ---------------------------------------------------------------------
update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "style":       {"enum": ["tiles", "circles", "carousel", "buttons"], "default": "tiles", "x-label": "Aspetto",
                  "x-enum-labels": ["Riquadri con foto", "Cerchi con foto", "Riquadri a scorrimento", "Pulsanti"]},
  "columns":     {"enum": [2, 3, 4], "default": 4, "x-label": "Riquadri per riga (su computer)"},
  "tile_shape":  {"enum": ["square", "landscape", "portrait"], "default": "landscape", "x-label": "Forma dei riquadri",
                  "x-enum-labels": ["Quadrati", "Orizzontali", "Verticali"]},
  "ready_cover": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Foto per i pezzi pronti",
                  "x-widget": "image"},
  "other_cover": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Foto per i pezzi senza categoria",
                  "x-widget": "image"}
}$j$::jsonb)
where type = 'category_menu';

update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "style": {"enum": ["grid", "carousel"], "default": "grid", "x-label": "Aspetto",
            "x-enum-labels": ["Griglia", "A scorrimento"]}
}$j$::jsonb)
where type = 'product_grid';

-- ---------------------------------------------------------------------
-- 4. Ordine dei campi nei moduli (il database non conserva l'ordine delle chiavi)
-- ---------------------------------------------------------------------
update public.block_types b set schema = b.schema || jsonb_build_object('x-order', o.fields)
from (values
  ('hero',             '["title","subtitle","image","layout","button_text","button_link"]'::jsonb),
  ('text',             '["title","body","align"]'),
  ('gallery',          '["title","images","style","columns"]'),
  ('category_menu',    '["title","style","columns","tile_shape","show_ready","ready_label","ready_cover","show_other","other_label","other_cover","hide_empty"]'),
  ('product_grid',     '["title","collection_id","style","columns","limit","sort","show_price","show_sold"]'),
  ('featured_product', '["product_id","text","layout"]'),
  ('testimonials',     '["title","items"]'),
  ('faq',              '["title","items"]'),
  ('contact',          '["title","text","show_whatsapp","show_email","show_vinted","show_instagram"]'),
  ('banner',           '["text","link","style"]'),
  ('spacer',           '["size","divider"]')
) as o(type, fields)
where b.type = o.type;

-- Sotto-campi delle liste (recensioni, domande)
update public.block_types
set schema = jsonb_set(schema, '{properties,items,items,x-order}', '["name","text"]')
where type = 'testimonials';
update public.block_types
set schema = jsonb_set(schema, '{properties,items,items,x-order}', '["question","answer"]')
where type = 'faq';

-- ---------------------------------------------------------------------
-- 5. Aggiornamento immediato del sito
--    Ad ogni pubblicazione o modifica del catalogo il database avvisa il
--    sito (pg_net). Se l'avviso fallisce non succede nulla di grave: il
--    sito si aggiorna comunque da solo entro un minuto.
-- ---------------------------------------------------------------------
create extension if not exists pg_net;

create table if not exists private.app_config (
  id                smallint primary key default 1 check (id = 1),
  site_url          text not null,
  revalidate_secret text not null
);
alter table private.app_config enable row level security;

insert into private.app_config (site_url, revalidate_secret)
values ('https://handmade-by-bi.netlify.app', encode(extensions.gen_random_bytes(24), 'hex'))
on conflict (id) do nothing;

create or replace function private.notify_site()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  c record;
begin
  select site_url, revalidate_secret into c from private.app_config where id = 1;
  if c.site_url is not null then
    perform net.http_post(
      url     := c.site_url || '/api/revalidate',
      body    := '{}'::jsonb,
      headers := jsonb_build_object('Content-Type', 'application/json',
                                    'x-revalidate-secret', c.revalidate_secret)
    );
  end if;
  return null;
exception when others then
  -- un avviso non riuscito non deve mai bloccare un salvataggio
  return null;
end $$;

drop trigger if exists site_versions_notify on public.site_versions;
create trigger site_versions_notify after insert on public.site_versions
  for each statement execute function private.notify_site();

drop trigger if exists products_notify on public.products;
create trigger products_notify after insert or update or delete on public.products
  for each statement execute function private.notify_site();

drop trigger if exists collections_notify on public.collections;
create trigger collections_notify after insert or update or delete on public.collections
  for each statement execute function private.notify_site();

drop trigger if exists product_collections_notify on public.product_collections;
create trigger product_collections_notify after insert or update or delete on public.product_collections
  for each statement execute function private.notify_site();

commit;

-- ---------------------------------------------------------------------
-- DOPO il commit: copia questo valore in Netlify, variabile REVALIDATE_SECRET
-- ---------------------------------------------------------------------
select revalidate_secret as "Copia in Netlify come REVALIDATE_SECRET" from private.app_config;

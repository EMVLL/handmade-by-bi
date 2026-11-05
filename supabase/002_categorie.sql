-- =====================================================================
--  Handmade by Bi — 002: categorie
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase.
--  - crea le categorie iniziali
--  - aggiunge il blocco "Menu categorie" e lo mette in homepage
--    subito dopo la copertina, poi pubblica il sito
--  "Disponibili in pronta consegna" e "Altro" NON sono categorie da
--  creare: il sito le calcola da solo (stato Disponibile / pezzi senza
--  categoria), così Benedetta non deve tenerle aggiornate a mano.
-- =====================================================================

begin;

-- Gli indirizzi delle due categorie automatiche sono riservati
alter table public.collections
  drop constraint if exists collections_reserved_slug;
alter table public.collections
  add constraint collections_reserved_slug
  check (slug not in ('altro', 'pronta-consegna'));

-- Categorie iniziali
insert into public.collections (slug, name, position) values
  ('borse', 'Borse', 0),
  ('portachiavi', 'Portachiavi', 1),
  ('baby', 'Baby', 2),
  ('cappelli', 'Cappelli', 3),
  ('costumi', 'Costumi', 4)
on conflict (slug) do nothing;

-- Nuovo tipo di blocco
insert into public.block_types (type, label, position, schema) values
('category_menu', 'Menu categorie', 35, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title":       {"type": "string", "maxLength": 80, "default": "Scegli una categoria", "x-label": "Titolo"},
    "style":       {"enum": ["tiles", "buttons"], "default": "tiles", "x-label": "Aspetto",
                    "x-enum-labels": ["Riquadri con foto", "Pulsanti"]},
    "show_ready":  {"type": "boolean", "default": true, "x-label": "Mostra i pezzi pronti"},
    "ready_label": {"type": "string", "minLength": 1, "maxLength": 40, "default": "Disponibili in pronta consegna",
                    "x-label": "Nome per i pezzi pronti"},
    "show_other":  {"type": "boolean", "default": true, "x-label": "Mostra i pezzi senza categoria"},
    "other_label": {"type": "string", "minLength": 1, "maxLength": 40, "default": "Altro",
                    "x-label": "Nome per i pezzi senza categoria"},
    "hide_empty":  {"type": "boolean", "default": true, "x-label": "Nascondi le categorie vuote"}
  }
}$j$)
on conflict (type) do nothing;

-- In homepage, subito dopo la copertina (solo se non c'è già)
do $$
declare
  v_home uuid;
begin
  select id into v_home from public.pages where is_home;
  if v_home is null then
    raise exception 'Homepage non trovata';
  end if;
  if not exists (select 1 from public.blocks where page_id = v_home and type = 'category_menu') then
    update public.blocks set position = position + 1
    where page_id = v_home and position >= 1;
    insert into public.blocks (page_id, type, position, props)
    values (v_home, 'category_menu', 1, public.block_defaults('category_menu'));
  end if;
end $$;

-- Pubblica, così il menu compare subito sul sito
select private.do_publish('Menu categorie in homepage');

commit;

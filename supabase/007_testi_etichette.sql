-- =====================================================================
--  Handmade by Bi — 007: stile dei testi, nastro, etichette dei pezzi
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase.
--  1. Corsivo / stampatello per titoli e testi di ogni sezione
--     (e per il nome del negozio nell'intestazione)
--  2. Nastro dei lavori: nomi dei pezzi sì/no
--  3. Etichette dei pezzi (Disponibile, Su ordinazione, Venduto):
--     sì/no una per una, testo e colori, carattere e stile in comune
--  L'aspetto del sito non cambia finché Benedetta non sceglie.
-- =====================================================================

begin;

create temp table _pending on commit drop as
select private.build_snapshot() is distinct from
       (select snapshot from public.site_versions where is_live) as pending;

-- ---------------------------------------------------------------------
-- 1. Stile dei testi nelle sezioni
-- ---------------------------------------------------------------------
update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal",
                  "x-label": "Stile del titolo", "x-group": "style",
                  "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]},
  "text_style":  {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal",
                  "x-label": "Stile dei testi", "x-group": "style",
                  "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}
}$j$::jsonb)
where type not in ('spacer', 'banner');

update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal",
                 "x-label": "Stile del testo", "x-group": "style",
                 "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}
}$j$::jsonb)
where type = 'banner';

update public.setting_schemas
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "name_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal",
                 "x-label": "Stile del nome",
                 "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}
}$j$::jsonb)
|| jsonb_build_object('x-order',
     '["show_logo","logo_size","show_name","name_size","name_font","name_style","align","arrangement"]'::jsonb)
where key = 'header';

-- ---------------------------------------------------------------------
-- 2. Nastro: nomi dei pezzi sì/no
-- ---------------------------------------------------------------------
update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "ribbon_names": {"type": "boolean", "default": true, "x-label": "Nel nastro, mostra i nomi dei lavori"}
}$j$::jsonb)
|| jsonb_build_object('x-order',
     '["title","collection_id","style","ribbon_links","ribbon_names","columns","limit","sort","show_price","show_sold"]'::jsonb)
where type = 'product_grid';

-- ---------------------------------------------------------------------
-- 3. Etichette dei pezzi
-- ---------------------------------------------------------------------
insert into public.setting_schemas (key, label, schema) values
('badges', 'Etichette dei pezzi', $j${
  "type": "object", "additionalProperties": false,
  "x-groups": {
    "all":   {"label": "Per tutte le etichette"},
    "ready": {"label": "Disponibile"},
    "order": {"label": "Su ordinazione"},
    "sold":  {"label": "Venduto"}
  },
  "x-order": ["show", "font", "text_style", "position",
              "ready_show", "ready_text", "ready_bg", "ready_color",
              "order_show", "order_text", "order_bg", "order_color",
              "sold_show", "sold_text", "sold_bg", "sold_color"],
  "properties": {
    "show":        {"type": "boolean", "default": true, "x-label": "Mostra le etichette sui pezzi", "x-group": "all"},
    "font":        {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display",
                             "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme",
                    "x-label": "Carattere", "x-widget": "font", "x-group": "all",
                    "x-enum-labels": ["Come i testi del sito", "Fraunces", "Playfair Display", "Lora",
                                      "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]},
    "text_style":  {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal",
                    "x-label": "Stile", "x-group": "all",
                    "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]},
    "position":    {"enum": ["top_left", "top_right", "bottom_left", "bottom_right"], "default": "top_left",
                    "x-label": "Posizione sulla foto", "x-group": "all",
                    "x-enum-labels": ["In alto a sinistra", "In alto a destra", "In basso a sinistra", "In basso a destra"]},

    "ready_show":  {"type": "boolean", "default": false, "x-label": "Mostra", "x-group": "ready"},
    "ready_text":  {"type": "string", "minLength": 1, "maxLength": 30, "default": "Disponibile",
                    "x-label": "Testo", "x-group": "ready"},
    "ready_bg":    {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore di sfondo",
                    "x-widget": "color", "x-group": "ready"},
    "ready_color": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore del testo",
                    "x-widget": "color", "x-group": "ready"},

    "order_show":  {"type": "boolean", "default": true, "x-label": "Mostra", "x-group": "order"},
    "order_text":  {"type": "string", "minLength": 1, "maxLength": 30, "default": "Su ordinazione",
                    "x-label": "Testo", "x-group": "order"},
    "order_bg":    {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore di sfondo",
                    "x-widget": "color", "x-group": "order"},
    "order_color": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore del testo",
                    "x-widget": "color", "x-group": "order"},

    "sold_show":   {"type": "boolean", "default": true, "x-label": "Mostra", "x-group": "sold"},
    "sold_text":   {"type": "string", "minLength": 1, "maxLength": 30, "default": "Venduto",
                    "x-label": "Testo", "x-group": "sold"},
    "sold_bg":     {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore di sfondo",
                    "x-widget": "color", "x-group": "sold"},
    "sold_color":  {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore del testo",
                    "x-widget": "color", "x-group": "sold"}
  }
}$j$)
on conflict (key) do update set schema = excluded.schema, label = excluded.label;

alter table public.site_settings add column if not exists badges jsonb not null default '{}';

create or replace function private.validate_settings()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  r record;
begin
  for r in select key, label, schema from public.setting_schemas
           where key in ('theme', 'contacts', 'seo', 'header', 'badges') loop
    if not extensions.jsonb_matches_schema(
         r.schema::json,
         case r.key when 'theme'    then new.theme
                    when 'contacts' then new.contacts
                    when 'header'   then new.header
                    when 'badges'   then new.badges
                    else new.seo end) then
      raise exception 'Impostazioni non valide: %', r.label
        using errcode = 'check_violation';
    end if;
  end loop;
  return new;
end $$;

create or replace function private.build_snapshot()
returns jsonb language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'settings', (
      select jsonb_build_object('site_name', s.site_name, 'logo_path', s.logo_path,
                                'theme', s.theme, 'contacts', s.contacts, 'seo', s.seo,
                                'header', s.header, 'badges', s.badges)
      from public.site_settings s where s.id = 1),
    'pages', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', p.id, 'slug', p.slug, 'title', p.title, 'seo', p.seo,
               'is_home', p.is_home, 'position', p.position,
               'blocks', coalesce((
                  select jsonb_agg(jsonb_build_object(
                           'id', b.id, 'type', b.type, 'position', b.position,
                           'visible', b.visible, 'props', b.props)
                         order by b.position, b.id)
                  from public.blocks b where b.page_id = p.id), '[]'::jsonb))
             order by p.position, p.slug)
      from public.pages p), '[]'::jsonb),
    'menu', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', m.id, 'label', m.label, 'page_id', m.page_id,
               'url', m.url, 'position', m.position)
             order by m.position, m.id)
      from public.menu_items m), '[]'::jsonb)
  );
$$;

create or replace function private.load_snapshot(v jsonb)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if v is null then
    raise exception 'Versione non trovata';
  end if;

  update public.pages set is_home = false where is_home;
  delete from public.menu_items where true;
  delete from public.pages where true;

  insert into public.pages (id, slug, title, seo, is_home, position)
  select (p->>'id')::uuid, p->>'slug', p->>'title', coalesce(p->'seo', '{}'::jsonb),
         (p->>'is_home')::boolean, (p->>'position')::int
  from jsonb_array_elements(v->'pages') p;

  insert into public.blocks (id, page_id, type, position, visible, props)
  select (b->>'id')::uuid, (p->>'id')::uuid, b->>'type', (b->>'position')::int,
         (b->>'visible')::boolean, b->'props'
  from jsonb_array_elements(v->'pages') p
  cross join lateral jsonb_array_elements(p->'blocks') b;

  insert into public.menu_items (id, label, page_id, url, position)
  select (m->>'id')::uuid, m->>'label', (m->>'page_id')::uuid, m->>'url', (m->>'position')::int
  from jsonb_array_elements(v->'menu') m;

  update public.site_settings set
    site_name = v->'settings'->>'site_name',
    logo_path = v->'settings'->>'logo_path',
    theme     = v->'settings'->'theme',
    contacts  = v->'settings'->'contacts',
    seo       = v->'settings'->'seo',
    header    = coalesce(v->'settings'->'header', '{}'::jsonb),
    badges    = coalesce(v->'settings'->'badges', '{}'::jsonb)
  where id = 1;
end $$;
revoke execute on function private.load_snapshot(jsonb) from public;

do $$
begin
  if not (select pending from _pending) then
    perform private.do_publish('Nuove opzioni: stile dei testi ed etichette');
  end if;
end $$;

commit;

-- =====================================================================
--  Handmade by Bi — 006: intestazione, avvisi animati, nastro cliccabile
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase.
--  1. Intestazione (in alto): logo e nome sì/no, posizione, grandezze
--  2. Avvisi: più messaggi, 4 effetti (fisso, scorre, dissolvenza, dal basso)
--  3. Nastro dei lavori: interruttore per aprire la scheda del pezzo
--  Il sito online non cambia aspetto: valgono i valori di oggi finché
--  Benedetta non sceglie diversamente.
-- =====================================================================

begin;

-- C'erano modifiche in sospeso prima di iniziare?
create temp table _pending on commit drop as
select private.build_snapshot() is distinct from
       (select snapshot from public.site_versions where is_live) as pending;

-- ---------------------------------------------------------------------
-- 1. Intestazione
-- ---------------------------------------------------------------------
insert into public.setting_schemas (key, label, schema) values
('header', 'Intestazione', $j${
  "type": "object", "additionalProperties": false,
  "x-order": ["show_logo", "logo_size", "show_name", "name_size", "name_font", "align", "arrangement"],
  "properties": {
    "show_logo":   {"type": "boolean", "default": true, "x-label": "Mostra il logo"},
    "logo_size":   {"enum": ["s", "m", "l", "xl"], "default": "m", "x-label": "Grandezza del logo",
                    "x-enum-labels": ["Piccolo", "Medio", "Grande", "Molto grande"]},
    "show_name":   {"type": "boolean", "default": true, "x-label": "Mostra il nome del negozio"},
    "name_size":   {"enum": ["s", "m", "l"], "default": "m", "x-label": "Grandezza del nome",
                    "x-enum-labels": ["Piccolo", "Medio", "Grande"]},
    "name_font":   {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display",
                             "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme",
                    "x-label": "Carattere del nome", "x-widget": "font",
                    "x-enum-labels": ["Come i titoli del sito", "Fraunces", "Playfair Display", "Lora",
                                      "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]},
    "align":       {"enum": ["left", "center", "right"], "default": "left", "x-label": "Posizione",
                    "x-enum-labels": ["A sinistra", "Al centro", "A destra"]},
    "arrangement": {"enum": ["row", "stack"], "default": "row", "x-label": "Logo e nome",
                    "x-enum-labels": ["Uno accanto all'altro", "Logo sopra il nome"]}
  }
}$j$)
on conflict (key) do update set schema = excluded.schema, label = excluded.label;

alter table public.site_settings add column if not exists header jsonb not null default '{}';

create or replace function private.validate_settings()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  r record;
begin
  for r in select key, label, schema from public.setting_schemas
           where key in ('theme', 'contacts', 'seo', 'header') loop
    if not extensions.jsonb_matches_schema(
         r.schema::json,
         case r.key when 'theme'    then new.theme
                    when 'contacts' then new.contacts
                    when 'header'   then new.header
                    else new.seo end) then
      raise exception 'Impostazioni non valide: %', r.label
        using errcode = 'check_violation';
    end if;
  end loop;
  return new;
end $$;

-- L'intestazione fa parte del sito pubblicato (bozza, anteprima, cronologia)
create or replace function private.build_snapshot()
returns jsonb language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'settings', (
      select jsonb_build_object('site_name', s.site_name, 'logo_path', s.logo_path,
                                'theme', s.theme, 'contacts', s.contacts, 'seo', s.seo,
                                'header', s.header)
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
    header    = coalesce(v->'settings'->'header', '{}'::jsonb)  -- versioni vecchie: valori di sempre
  where id = 1;
end $$;
revoke execute on function private.load_snapshot(jsonb) from public;

-- ---------------------------------------------------------------------
-- 2. Avvisi con più messaggi ed effetti
-- ---------------------------------------------------------------------
update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "messages": {"type": "array", "maxItems": 6, "default": [],
               "x-label": "Altri messaggi (si alternano con il primo)",
               "items": {"type": "object", "additionalProperties": false, "required": ["text"],
                         "x-order": ["text", "link"],
                         "properties": {
                           "text": {"type": "string", "minLength": 1, "maxLength": 140, "x-label": "Messaggio"},
                           "link": {"type": "string", "pattern": "^(https://|/)[^\\s]{0,299}$",
                                    "x-label": "Link (facoltativo)", "x-widget": "link"}
                         }}},
  "effect":   {"enum": ["static", "marquee", "fade", "slide"], "default": "static", "x-label": "Effetto",
               "x-enum-labels": ["Fisso", "Scorre da destra a sinistra", "Cambia in dissolvenza", "Cambia salendo dal basso"]},
  "speed":    {"enum": ["slow", "normal", "fast"], "default": "normal", "x-label": "Velocità",
               "x-enum-labels": ["Lenta", "Normale", "Veloce"]}
}$j$::jsonb)
|| jsonb_build_object('x-order', '["text","link","messages","effect","speed","style"]'::jsonb)
where type = 'banner';

update public.block_types
set schema = jsonb_set(schema, '{properties,text,x-label}', '"Messaggio"')
where type = 'banner';

-- ---------------------------------------------------------------------
-- 3. Nastro dei lavori cliccabile (spento: resta solo vetrina)
-- ---------------------------------------------------------------------
update public.block_types
set schema = jsonb_set(schema, '{properties}', (schema->'properties') || $j${
  "ribbon_links": {"type": "boolean", "default": false,
                   "x-label": "Nel nastro, toccando un lavoro si apre la sua scheda"}
}$j$::jsonb)
|| jsonb_build_object('x-order',
     '["title","collection_id","style","ribbon_links","columns","limit","sort","show_price","show_sold"]'::jsonb)
where type = 'product_grid';

-- ---------------------------------------------------------------------
-- Se non c'erano modifiche in sospeso, si ripubblica (aspetto identico),
-- così l'anteprima non segnala modifiche che Benedetta non ha fatto.
-- ---------------------------------------------------------------------
do $$
begin
  if not (select pending from _pending) then
    perform private.do_publish('Nuove opzioni: intestazione e avvisi');
  end if;
end $$;

commit;

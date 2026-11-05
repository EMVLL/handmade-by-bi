-- =====================================================================
--  Handmade by Bi — schema iniziale Supabase
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor, su progetto appena creato.
--  PRIMA di lanciarlo:
--    1. Authentication → Users → crea l'utente di Benedetta e il tuo
--    2. Sostituisci le due email nella sezione 11 (in fondo)
--  È tutto in una transazione: se qualcosa fallisce non resta nulla
--  a metà.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Estensioni e schema privato (mai esposto via API)
-- ---------------------------------------------------------------------
create extension if not exists pg_jsonschema with schema extensions;

create schema if not exists private;
revoke all on schema private from public;

-- ---------------------------------------------------------------------
-- 2. Amministratori
-- ---------------------------------------------------------------------
create table private.admins (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table private.admins enable row level security;

create function public.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from private.admins where user_id = auth.uid());
$$;

create function private.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- 3. Registro degli schemi (la stessa definizione genera i form
--    nell'app admin e valida i dati nel database)
-- ---------------------------------------------------------------------
create table public.setting_schemas (
  key    text primary key,
  label  text not null,
  schema jsonb not null
);

create table public.block_types (
  type     text primary key check (type ~ '^[a-z][a-z0-9_]{1,39}$'),
  label    text not null,
  schema   jsonb not null,
  position int not null default 0,
  active   boolean not null default true
);

-- ---------------------------------------------------------------------
-- 4. Impostazioni del sito (una sola riga)
-- ---------------------------------------------------------------------
create table public.site_settings (
  id         smallint primary key default 1 check (id = 1),
  site_name  text not null check (char_length(site_name) between 1 and 60),
  logo_path  text check (logo_path ~ '^[a-zA-Z0-9/_.-]{1,300}$'),
  theme      jsonb not null,
  contacts   jsonb not null,
  seo        jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

create function private.validate_settings()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  r record;
begin
  for r in select key, label, schema from public.setting_schemas
           where key in ('theme', 'contacts', 'seo') loop
    if not extensions.jsonb_matches_schema(
         r.schema::json,
         case r.key when 'theme'    then new.theme
                    when 'contacts' then new.contacts
                    else new.seo end) then
      raise exception 'Impostazioni non valide: %', r.label
        using errcode = 'check_violation';
    end if;
  end loop;
  return new;
end $$;

create trigger site_settings_validate before insert or update on public.site_settings
  for each row execute function private.validate_settings();
create trigger site_settings_updated before update on public.site_settings
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- 5. Pagine, blocchi, menu  (= la BOZZA su cui lavora l'admin)
-- ---------------------------------------------------------------------
create table public.pages (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique
             check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'
                    and char_length(slug) <= 60
                    and slug not in ('admin', 'api', 'login', 'prodotti',
                                     'collezioni', 'cerca', 'sitemap')),
  title      text not null check (char_length(title) between 1 and 80),
  seo        jsonb not null default '{}',
  is_home    boolean not null default false,
  position   int not null default 0,
  updated_at timestamptz not null default now()
);
create unique index pages_single_home on public.pages (is_home) where is_home;

create function private.validate_page()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if not coalesce(extensions.jsonb_matches_schema(
       (select schema from public.setting_schemas where key = 'seo')::json,
       new.seo), true) then
    raise exception 'Dati SEO della pagina "%" non validi', new.title
      using errcode = 'check_violation';
  end if;
  return new;
end $$;

create function private.protect_home()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if old.is_home then
    raise exception 'La homepage non si può eliminare: prima imposta un''altra pagina come home'
      using errcode = 'check_violation';
  end if;
  return old;
end $$;

create trigger pages_validate before insert or update on public.pages
  for each row execute function private.validate_page();
create trigger pages_protect_home before delete on public.pages
  for each row execute function private.protect_home();
create trigger pages_updated before update on public.pages
  for each row execute function private.set_updated_at();

create table public.blocks (
  id         uuid primary key default gen_random_uuid(),
  page_id    uuid not null references public.pages (id) on delete cascade,
  type       text not null references public.block_types (type),
  position   int not null default 0,
  visible    boolean not null default true,
  props      jsonb not null default '{}',
  updated_at timestamptz not null default now()
);
create index blocks_page_idx on public.blocks (page_id, position);

create function private.validate_block()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_schema jsonb;
  v_label  text;
begin
  select schema, label into v_schema, v_label
  from public.block_types where type = new.type and active;

  if v_schema is null then
    raise exception 'Tipo di blocco non disponibile: %', new.type
      using errcode = 'check_violation';
  end if;
  if not extensions.jsonb_matches_schema(v_schema::json, new.props) then
    raise exception 'Contenuto non valido nel blocco "%"', v_label
      using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger blocks_validate before insert or update on public.blocks
  for each row execute function private.validate_block();
create trigger blocks_updated before update on public.blocks
  for each row execute function private.set_updated_at();

create table public.menu_items (
  id       uuid primary key default gen_random_uuid(),
  label    text not null check (char_length(label) between 1 and 30),
  page_id  uuid references public.pages (id) on delete cascade,
  url      text check (url ~ '^(https://|/)[^\s]{0,299}$'),
  position int not null default 0,
  constraint menu_target check ((page_id is null) <> (url is null))
);

-- ---------------------------------------------------------------------
-- 6. Catalogo (LIVE: le modifiche si vedono subito)
-- ---------------------------------------------------------------------
create table public.products (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique
                   check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 80),
  title            text not null check (char_length(title) between 1 and 120),
  description      text not null default '' check (char_length(description) <= 5000),
  price            numeric(10,2) check (price between 0 and 100000),  -- null = prezzo su richiesta
  compare_at_price numeric(10,2),                                     -- prezzo barrato
  status           text not null default 'disponibile'
                   check (status in ('disponibile', 'su_ordinazione', 'venduto', 'nascosto')),
  photos           jsonb not null default '[]',
  options          jsonb not null default '[]',
  vinted_url       text check (vinted_url ~* '^https://(www\.)?vinted\.[a-z.]+/'),
  position         int not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz,                                       -- cestino
  constraint compare_price_valid
    check (compare_at_price is null or (price is not null and compare_at_price > price))
);

create function private.validate_product()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if not coalesce(extensions.jsonb_matches_schema(
       (select schema from public.setting_schemas where key = 'product_photos')::json,
       new.photos), true) then
    raise exception 'Foto del prodotto non valide (massimo 12)'
      using errcode = 'check_violation';
  end if;
  if not coalesce(extensions.jsonb_matches_schema(
       (select schema from public.setting_schemas where key = 'product_options')::json,
       new.options), true) then
    raise exception 'Opzioni del prodotto non valide'
      using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger products_validate before insert or update on public.products
  for each row execute function private.validate_product();
create trigger products_updated before update on public.products
  for each row execute function private.set_updated_at();

create table public.collections (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique
              check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 60),
  name        text not null check (char_length(name) between 1 and 60),
  description text not null default '' check (char_length(description) <= 1000),
  position    int not null default 0
);

create table public.product_collections (
  product_id    uuid not null references public.products (id) on delete cascade,
  collection_id uuid not null references public.collections (id) on delete cascade,
  position      int not null default 0,
  primary key (product_id, collection_id)
);
create index product_collections_coll_idx on public.product_collections (collection_id, position);

-- ---------------------------------------------------------------------
-- 7. Versioni pubblicate + funzioni di pubblicazione
--    Il sito pubblico legge SOLO la versione live (get_live_site).
-- ---------------------------------------------------------------------
create table public.site_versions (
  id           bigint generated always as identity primary key,
  snapshot     jsonb not null,
  note         text check (char_length(note) <= 200),
  is_live      boolean not null default false,
  published_at timestamptz not null default now(),
  published_by uuid
);
create unique index site_versions_single_live on public.site_versions (is_live) where is_live;

create function private.build_snapshot()
returns jsonb language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'settings', (
      select jsonb_build_object('site_name', s.site_name, 'logo_path', s.logo_path,
                                'theme', s.theme, 'contacts', s.contacts, 'seo', s.seo)
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

-- Controlli + pubblicazione (senza verifica utente: la fa publish_site)
create function private.do_publish(p_note text)
returns bigint language plpgsql security definer set search_path = ''
as $$
declare
  v_id  bigint;
  v_bad record;
begin
  if (select count(*) from public.pages where is_home) <> 1 then
    raise exception 'Serve esattamente una homepage per pubblicare'
      using errcode = 'check_violation';
  end if;

  -- ricontrolla tutti i blocchi: gli schemi potrebbero essere cambiati
  select bt.label, p.title as page_title into v_bad
  from public.blocks b
  join public.pages p        on p.id = b.page_id
  join public.block_types bt on bt.type = b.type
  where not bt.active
     or not extensions.jsonb_matches_schema(bt.schema::json, b.props)
  limit 1;
  if found then
    raise exception 'Il blocco "%" nella pagina "%" non è valido: correggilo prima di pubblicare',
      v_bad.label, v_bad.page_title using errcode = 'check_violation';
  end if;

  update public.site_versions set is_live = false where is_live;

  insert into public.site_versions (snapshot, note, is_live, published_by)
  values (private.build_snapshot(), p_note, true, auth.uid())
  returning id into v_id;

  -- tiene le ultime 50 versioni
  delete from public.site_versions
  where id not in (select id from public.site_versions order by id desc limit 50);

  return v_id;
end $$;

create function public.publish_site(p_note text default null)
returns bigint language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  return private.do_publish(p_note);
end $$;

create function public.get_live_site()
returns jsonb language sql stable security definer set search_path = ''
as $$
  select snapshot from public.site_versions where is_live;
$$;

-- Riporta la bozza a una versione passata e la ripubblica
create function public.restore_version(p_version_id bigint)
returns bigint language plpgsql security definer set search_path = ''
as $$
declare
  v jsonb;
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;

  select snapshot into v from public.site_versions where id = p_version_id;
  if v is null then
    raise exception 'Versione % non trovata', p_version_id;
  end if;

  update public.pages set is_home = false where is_home;  -- sblocca la protezione home
  delete from public.menu_items where true;
  delete from public.pages where true;                    -- i blocchi spariscono a cascata

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
    seo       = v->'settings'->'seo'
  where id = 1;

  return private.do_publish(format('Ripristino della versione %s', p_version_id));
end $$;

create function public.set_home_page(p_page_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  if not exists (select 1 from public.pages where id = p_page_id) then
    raise exception 'Pagina non trovata';
  end if;
  update public.pages set is_home = false where is_home and id <> p_page_id;
  update public.pages set is_home = true  where id = p_page_id;
end $$;

-- Props iniziali di un blocco nuovo, presi dai "default" dello schema
create function public.block_defaults(p_type text)
returns jsonb language sql stable security definer set search_path = ''
as $$
  select coalesce(jsonb_object_agg(e.key, e.value->'default'), '{}'::jsonb)
  from public.block_types bt
  cross join lateral jsonb_each(bt.schema->'properties') e
  where bt.type = p_type and e.value ? 'default';
$$;

-- ---------------------------------------------------------------------
-- 8. Sicurezza: RLS e permessi espliciti
-- ---------------------------------------------------------------------
alter table public.setting_schemas     enable row level security;
alter table public.block_types         enable row level security;
alter table public.site_settings       enable row level security;
alter table public.pages               enable row level security;
alter table public.blocks              enable row level security;
alter table public.menu_items          enable row level security;
alter table public.products            enable row level security;
alter table public.collections         enable row level security;
alter table public.product_collections enable row level security;
alter table public.site_versions       enable row level security;

-- Visitatori: vedono solo il catalogo (il resto arriva da get_live_site)
create policy "catalogo pubblico" on public.products
  for select to anon, authenticated
  using (deleted_at is null and status <> 'nascosto');
create policy "collezioni pubbliche" on public.collections
  for select to anon, authenticated using (true);
create policy "associazioni pubbliche" on public.product_collections
  for select to anon, authenticated using (true);

-- Admin
do $$
declare
  t text;
begin
  foreach t in array array['products', 'collections', 'product_collections',
                           'pages', 'blocks', 'menu_items', 'site_settings'] loop
    execute format(
      'create policy "admin gestisce" on public.%I for all to authenticated
         using ((select public.is_admin())) with check ((select public.is_admin()))', t);
  end loop;
  foreach t in array array['setting_schemas', 'block_types', 'site_versions'] loop
    execute format(
      'create policy "admin legge" on public.%I for select to authenticated
         using ((select public.is_admin()))', t);
  end loop;
end $$;

grant usage on schema public to anon, authenticated, service_role;

grant select on public.products, public.collections, public.product_collections to anon;
grant select, insert, update, delete
  on public.products, public.collections, public.product_collections,
     public.pages, public.blocks, public.menu_items
  to authenticated;
grant select, update on public.site_settings to authenticated;   -- niente insert/delete
grant select on public.setting_schemas, public.block_types, public.site_versions to authenticated;
grant all on all tables in schema public to service_role;

revoke execute on function
  public.is_admin(), public.publish_site(text), public.get_live_site(),
  public.restore_version(bigint), public.set_home_page(uuid), public.block_defaults(text)
  from public, anon, authenticated;
revoke execute on all functions in schema private from public;

grant execute on function public.get_live_site() to anon, authenticated;
grant execute on function
  public.is_admin(), public.publish_site(text), public.restore_version(bigint),
  public.set_home_page(uuid), public.block_defaults(text)
  to authenticated;

-- ---------------------------------------------------------------------
-- 9. Storage foto: lettura pubblica, scrittura solo admin
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "media admin select" on storage.objects for select to authenticated
  using (bucket_id = 'media' and (select public.is_admin()));
create policy "media admin insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and (select public.is_admin()));
create policy "media admin update" on storage.objects for update to authenticated
  using (bucket_id = 'media' and (select public.is_admin()));
create policy "media admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and (select public.is_admin()));

-- ---------------------------------------------------------------------
-- 10. Dati iniziali
-- ---------------------------------------------------------------------
insert into public.setting_schemas (key, label, schema) values
('theme', 'Tema', $j${
  "type": "object", "additionalProperties": false,
  "required": ["primary", "background", "text", "accent", "font_heading", "font_body", "radius"],
  "properties": {
    "primary":      {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore principale", "x-widget": "color"},
    "background":   {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Sfondo", "x-widget": "color"},
    "text":         {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore del testo", "x-widget": "color"},
    "accent":       {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore secondario", "x-widget": "color"},
    "font_heading": {"enum": ["Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand"], "x-label": "Font dei titoli"},
    "font_body":    {"enum": ["Nunito", "Quicksand", "DM Sans", "Lato", "Lora"], "x-label": "Font del testo"},
    "radius":       {"enum": ["none", "small", "medium", "large"], "x-label": "Angoli",
                     "x-enum-labels": ["Squadrati", "Poco arrotondati", "Arrotondati", "Molto arrotondati"]}
  }
}$j$),
('contacts', 'Contatti e canali d''ordine', $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "whatsapp": {
      "type": "object", "additionalProperties": false, "x-label": "WhatsApp",
      "properties": {
        "enabled":  {"type": "boolean", "x-label": "Attivo"},
        "number":   {"type": "string", "pattern": "^[1-9][0-9]{7,14}$", "x-label": "Numero con prefisso, senza + (es. 393331234567)"},
        "template": {"type": "string", "maxLength": 500, "pattern": "^([^{}]|\\{(prodotto|prezzo|opzione|link)\\})*$",
                     "x-label": "Messaggio precompilato", "x-widget": "template"}
      },
      "if": {"properties": {"enabled": {"const": true}}, "required": ["enabled"]},
      "then": {"required": ["number"]}
    },
    "email": {
      "type": "object", "additionalProperties": false, "x-label": "Email",
      "properties": {
        "enabled":          {"type": "boolean", "x-label": "Attiva"},
        "address":          {"type": "string", "maxLength": 200, "pattern": "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", "x-label": "Indirizzo"},
        "subject_template": {"type": "string", "maxLength": 150, "pattern": "^([^{}]|\\{(prodotto|prezzo|opzione|link)\\})*$",
                             "x-label": "Oggetto precompilato", "x-widget": "template"},
        "body_template":    {"type": "string", "maxLength": 1000, "pattern": "^([^{}]|\\{(prodotto|prezzo|opzione|link)\\})*$",
                             "x-label": "Testo precompilato", "x-widget": "template"}
      },
      "if": {"properties": {"enabled": {"const": true}}, "required": ["enabled"]},
      "then": {"required": ["address"]}
    },
    "vinted": {
      "type": "object", "additionalProperties": false, "x-label": "Vinted",
      "properties": {
        "enabled":     {"type": "boolean", "x-label": "Attivo"},
        "profile_url": {"type": "string", "maxLength": 300, "pattern": "^https://(www\\.)?vinted\\.[a-z.]+/", "x-label": "Link al profilo Vinted"}
      },
      "if": {"properties": {"enabled": {"const": true}}, "required": ["enabled"]},
      "then": {"required": ["profile_url"]}
    },
    "instagram": {
      "type": "object", "additionalProperties": false, "x-label": "Instagram",
      "properties": {
        "enabled":     {"type": "boolean", "x-label": "Attivo"},
        "profile_url": {"type": "string", "maxLength": 300, "pattern": "^https://(www\\.)?instagram\\.com/", "x-label": "Link al profilo Instagram"}
      },
      "if": {"properties": {"enabled": {"const": true}}, "required": ["enabled"]},
      "then": {"required": ["profile_url"]}
    }
  }
}$j$),
('seo', 'SEO', $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title":       {"type": "string", "maxLength": 70,  "x-label": "Titolo per Google"},
    "description": {"type": "string", "maxLength": 160, "x-label": "Descrizione per Google", "x-widget": "textarea"},
    "image":       {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Immagine di anteprima", "x-widget": "image"}
  }
}$j$),
('product_photos', 'Foto prodotto', $j${
  "type": "array", "maxItems": 12,
  "items": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$"}
}$j$),
('product_options', 'Opzioni prodotto', $j${
  "type": "array", "maxItems": 5,
  "items": {
    "type": "object", "additionalProperties": false, "required": ["name", "values"],
    "properties": {
      "name":   {"type": "string", "minLength": 1, "maxLength": 30, "x-label": "Nome opzione (es. Colore)"},
      "values": {"type": "array", "minItems": 1, "maxItems": 20, "x-label": "Valori",
                 "items": {"type": "string", "minLength": 1, "maxLength": 30}}
    }
  }
}$j$);

insert into public.block_types (type, label, position, schema) values
('hero', 'Copertina', 10, $j${
  "type": "object", "additionalProperties": false, "required": ["title"],
  "properties": {
    "title":       {"type": "string", "minLength": 1, "maxLength": 80, "default": "Fatto a mano, con amore", "x-label": "Titolo"},
    "subtitle":    {"type": "string", "maxLength": 200, "x-label": "Sottotitolo", "x-widget": "textarea"},
    "image":       {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Immagine", "x-widget": "image"},
    "button_text": {"type": "string", "maxLength": 30, "x-label": "Testo del bottone"},
    "button_link": {"type": "string", "pattern": "^(https://|/)[^\\s]{0,299}$", "x-label": "Link del bottone", "x-widget": "link"},
    "layout":      {"enum": ["center", "left", "full_image"], "default": "center", "x-label": "Disposizione",
                    "x-enum-labels": ["Centrata", "A sinistra", "Immagine a tutto schermo"]}
  }
}$j$),
('text', 'Testo', 20, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title": {"type": "string", "maxLength": 80, "x-label": "Titolo"},
    "body":  {"type": "string", "maxLength": 5000, "default": "", "x-label": "Testo", "x-widget": "textarea"},
    "align": {"enum": ["left", "center"], "default": "left", "x-label": "Allineamento", "x-enum-labels": ["A sinistra", "Centrato"]}
  }
}$j$),
('gallery', 'Galleria foto', 30, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title":   {"type": "string", "maxLength": 80, "x-label": "Titolo"},
    "images":  {"type": "array", "maxItems": 24, "default": [], "x-label": "Foto", "x-widget": "images",
                "items": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$"}},
    "columns": {"enum": [2, 3, 4], "default": 3, "x-label": "Colonne"},
    "style":   {"enum": ["grid", "carousel"], "default": "grid", "x-label": "Stile", "x-enum-labels": ["Griglia", "Scorrimento"]}
  }
}$j$),
('product_grid', 'Griglia prodotti', 40, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title":         {"type": "string", "maxLength": 80, "default": "I miei lavori", "x-label": "Titolo"},
    "collection_id": {"type": "string", "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
                      "x-label": "Collezione (vuoto = tutti i prodotti)", "x-widget": "collection"},
    "columns":       {"enum": [2, 3, 4], "default": 3, "x-label": "Colonne"},
    "limit":         {"type": "integer", "minimum": 1, "maximum": 48, "default": 12, "x-label": "Quanti prodotti mostrare"},
    "sort":          {"enum": ["manual", "newest", "price_asc", "price_desc"], "default": "newest", "x-label": "Ordine",
                      "x-enum-labels": ["Manuale", "Più recenti", "Prezzo crescente", "Prezzo decrescente"]},
    "show_price":    {"type": "boolean", "default": true, "x-label": "Mostra prezzi"},
    "show_sold":     {"type": "boolean", "default": true, "x-label": "Mostra anche i venduti"}
  }
}$j$),
('featured_product', 'Prodotto in evidenza', 50, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "product_id": {"type": "string", "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
                   "x-label": "Prodotto", "x-widget": "product"},
    "text":       {"type": "string", "maxLength": 300, "x-label": "Testo aggiuntivo", "x-widget": "textarea"},
    "layout":     {"enum": ["image_left", "image_right"], "default": "image_left", "x-label": "Disposizione",
                   "x-enum-labels": ["Foto a sinistra", "Foto a destra"]}
  }
}$j$),
('testimonials', 'Recensioni', 60, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title": {"type": "string", "maxLength": 80, "default": "Dicono di me", "x-label": "Titolo"},
    "items": {"type": "array", "maxItems": 12, "default": [], "x-label": "Recensioni",
              "items": {"type": "object", "additionalProperties": false, "required": ["name", "text"],
                        "properties": {
                          "name": {"type": "string", "minLength": 1, "maxLength": 40,  "x-label": "Nome"},
                          "text": {"type": "string", "minLength": 1, "maxLength": 400, "x-label": "Recensione", "x-widget": "textarea"}
                        }}}
  }
}$j$),
('faq', 'Domande frequenti', 70, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title": {"type": "string", "maxLength": 80, "default": "Domande frequenti", "x-label": "Titolo"},
    "items": {"type": "array", "maxItems": 20, "default": [], "x-label": "Domande",
              "items": {"type": "object", "additionalProperties": false, "required": ["question", "answer"],
                        "properties": {
                          "question": {"type": "string", "minLength": 1, "maxLength": 150,  "x-label": "Domanda"},
                          "answer":   {"type": "string", "minLength": 1, "maxLength": 1000, "x-label": "Risposta", "x-widget": "textarea"}
                        }}}
  }
}$j$),
('contact', 'Contatti', 80, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "title":          {"type": "string", "maxLength": 80, "default": "Scrivimi", "x-label": "Titolo"},
    "text":           {"type": "string", "maxLength": 500, "x-label": "Testo", "x-widget": "textarea"},
    "show_whatsapp":  {"type": "boolean", "default": true, "x-label": "Mostra WhatsApp"},
    "show_email":     {"type": "boolean", "default": true, "x-label": "Mostra email"},
    "show_vinted":    {"type": "boolean", "default": true, "x-label": "Mostra Vinted"},
    "show_instagram": {"type": "boolean", "default": true, "x-label": "Mostra Instagram"}
  }
}$j$),
('banner', 'Avviso', 90, $j${
  "type": "object", "additionalProperties": false, "required": ["text"],
  "properties": {
    "text":  {"type": "string", "minLength": 1, "maxLength": 140, "default": "Spedizioni in tutta Italia", "x-label": "Testo"},
    "link":  {"type": "string", "pattern": "^(https://|/)[^\\s]{0,299}$", "x-label": "Link (facoltativo)", "x-widget": "link"},
    "style": {"enum": ["info", "highlight", "sale"], "default": "info", "x-label": "Stile",
              "x-enum-labels": ["Informazione", "In evidenza", "Saldi"]}
  }
}$j$),
('spacer', 'Spazio', 100, $j${
  "type": "object", "additionalProperties": false,
  "properties": {
    "size":    {"enum": ["small", "medium", "large"], "default": "medium", "x-label": "Altezza",
                "x-enum-labels": ["Piccolo", "Medio", "Grande"]},
    "divider": {"type": "boolean", "default": false, "x-label": "Mostra una linea"}
  }
}$j$);

insert into public.site_settings (id, site_name, theme, contacts, seo) values (
  1,
  'Handmade by Bi',
  '{"primary": "#B5838D", "background": "#FFF8F3", "text": "#3D3033", "accent": "#6D9773",
    "font_heading": "Fraunces", "font_body": "Nunito", "radius": "medium"}',
  '{"whatsapp":  {"enabled": false, "template": "Ciao! Vorrei ordinare {prodotto} ({prezzo}). {opzione} {link}"},
    "email":     {"enabled": false, "subject_template": "Ordine: {prodotto}",
                  "body_template": "Ciao! Vorrei ordinare {prodotto} ({prezzo}). {opzione} {link}"},
    "vinted":    {"enabled": false},
    "instagram": {"enabled": false}}',
  '{"title": "Handmade by Bi", "description": "Creazioni all''uncinetto fatte a mano."}'
);

with home as (
  insert into public.pages (slug, title, is_home, position)
  values ('home', 'Home', true, 0)
  returning id
), seed_blocks as (
  insert into public.blocks (page_id, type, position, props)
  select home.id, b.type, b.position, b.props
  from home, (values
    ('hero', 0, '{"title": "Fatto a mano, con amore", "subtitle": "Pezzi unici all''uncinetto, creati uno alla volta.",
                  "button_text": "Guarda i lavori", "button_link": "/prodotti", "layout": "center"}'::jsonb),
    ('product_grid', 1, '{"title": "I miei lavori", "columns": 3, "limit": 12, "sort": "newest",
                          "show_price": true, "show_sold": true}'::jsonb),
    ('contact', 2, '{"title": "Vuoi un pezzo su misura?", "text": "Scrivimi e ne parliamo.",
                     "show_whatsapp": true, "show_email": true, "show_vinted": true, "show_instagram": true}'::jsonb)
  ) as b(type, position, props)
  returning 1
)
insert into public.menu_items (label, page_id, position)
select 'Home', home.id, 0 from home;

-- ---------------------------------------------------------------------
-- 11. Admin  ← SOSTITUISCI LE DUE EMAIL
-- ---------------------------------------------------------------------
insert into private.admins (user_id)
select id from auth.users
where lower(email) in (lower('EMAIL_BENEDETTA'), lower('EMAIL_EMILIANO'));

do $$
begin
  if (select count(*) from private.admins) = 0 then
    raise exception 'Nessun admin trovato: crea prima gli utenti in Authentication e controlla le email nella sezione 11';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 12. Prima pubblicazione
-- ---------------------------------------------------------------------
select private.do_publish('Versione iniziale');

commit;

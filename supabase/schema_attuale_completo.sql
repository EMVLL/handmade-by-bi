-- =====================================================================
--  Handmade by Bi — FOTOGRAFIA dello schema attuale del database
-- ---------------------------------------------------------------------
--  Stato dopo gli script 001 → 007 (generato con pg_dump da un database
--  di prova su cui sono stati eseguiti tutti, nello stesso ordine).
--
--  SOLO DA CONSULTARE (per capire tabelle, funzioni, regole, permessi).
--  NON eseguirlo sul database di produzione: lì valgono gli script
--  numerati, già applicati. Per un progetto Supabase NUOVO si eseguono
--  gli script 001 → 007 in ordine, non questo file.
--
--  Contiene: schemi public e private (tabelle, vincoli, funzioni,
--  trigger, RLS, permessi) + i dati di block_types e setting_schemas
--  (gli schemi JSON che validano le sezioni e le impostazioni).
--  Non contiene: pezzi, categorie, foto, impostazioni del negozio,
--  segreti (revalidate_secret) né utenti.
-- =====================================================================

-- PostgreSQL database dump

\restrict 6ARrdNmTkn1X1TkvNE0cWPBq9zuzQAPlbMbcG8ylTIgNeRGl53gM36CTAng7f17

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

-- Name: private; Type: SCHEMA; Schema: -; Owner: -

CREATE SCHEMA private;

-- Name: public; Type: SCHEMA; Schema: -; Owner: -

CREATE SCHEMA public;

-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -

COMMENT ON SCHEMA public IS 'standard public schema';

-- Name: build_snapshot(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.build_snapshot() RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: do_publish(text); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.do_publish(p_note text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: load_snapshot(jsonb); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.load_snapshot(v jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: notify_site(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.notify_site() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: protect_home(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.protect_home() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  if old.is_home then
    raise exception 'La homepage non si può eliminare: prima imposta un''altra pagina come home'
      using errcode = 'check_violation';
  end if;
  return old;
end $$;

-- Name: set_updated_at(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
  new.updated_at := now();
  return new;
end $$;

-- Name: validate_block(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.validate_block() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: validate_page(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.validate_page() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not coalesce(extensions.jsonb_matches_schema(
       (select schema from public.setting_schemas where key = 'seo')::json,
       new.seo), true) then
    raise exception 'Dati SEO della pagina "%" non validi', new.title
      using errcode = 'check_violation';
  end if;
  return new;
end $$;

-- Name: validate_product(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.validate_product() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: validate_settings(); Type: FUNCTION; Schema: private; Owner: -

CREATE FUNCTION private.validate_settings() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: block_defaults(text); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.block_defaults(p_type text) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select coalesce(jsonb_object_agg(e.key, e.value->'default'), '{}'::jsonb)
  from public.block_types bt
  cross join lateral jsonb_each(bt.schema->'properties') e
  where bt.type = p_type and e.value ? 'default';
$$;

-- Name: discard_draft(); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.discard_draft() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  perform private.load_snapshot((select snapshot from public.site_versions where is_live));
end $$;

-- Name: draft_status(); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.draft_status() RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  return private.build_snapshot() is distinct from
         (select snapshot from public.site_versions where is_live);
end $$;

-- Name: get_draft_site(text); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.get_draft_site(p_token text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if p_token is null
     or p_token is distinct from (select preview_token from private.app_config where id = 1) then
    return null;
  end if;
  return private.build_snapshot();
end $$;

-- Name: get_live_site(); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.get_live_site() RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select snapshot from public.site_versions where is_live;
$$;

-- Name: get_preview_token(); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.get_preview_token() RETURNS text
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  return (select preview_token from private.app_config where id = 1);
end $$;

-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  select exists (select 1 from private.admins where user_id = auth.uid());
$$;

-- Name: load_version_to_draft(bigint); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.load_version_to_draft(p_version_id bigint) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  perform private.load_snapshot((select snapshot from public.site_versions where id = p_version_id));
end $$;

-- Name: publish_site(text); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.publish_site(p_note text DEFAULT NULL::text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  return private.do_publish(p_note);
end $$;

-- Name: restore_version(bigint); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.restore_version(p_version_id bigint) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  perform private.load_snapshot((select snapshot from public.site_versions where id = p_version_id));
  return private.do_publish(format('Ripristino della versione %s', p_version_id));
end $$;

-- Name: set_home_page(uuid); Type: FUNCTION; Schema: public; Owner: -

CREATE FUNCTION public.set_home_page(p_page_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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

-- Name: admins; Type: TABLE; Schema: private; Owner: -

CREATE TABLE private.admins (
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Name: app_config; Type: TABLE; Schema: private; Owner: -

CREATE TABLE private.app_config (
    id smallint DEFAULT 1 NOT NULL,
    site_url text NOT NULL,
    revalidate_secret text NOT NULL,
    preview_token text,
    CONSTRAINT app_config_id_check CHECK ((id = 1))
);

-- Name: block_types; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.block_types (
    type text NOT NULL,
    label text NOT NULL,
    schema jsonb NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT block_types_type_check CHECK ((type ~ '^[a-z][a-z0-9_]{1,39}$'::text))
);

-- Name: blocks; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.blocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    page_id uuid NOT NULL,
    type text NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Name: collections; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.collections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    cover_path text,
    CONSTRAINT collections_cover_path_check CHECK (((char_length(cover_path) <= 300) AND (cover_path ~ '^[a-zA-Z0-9/_.-]+$'::text))),
    CONSTRAINT collections_description_check CHECK ((char_length(description) <= 1000)),
    CONSTRAINT collections_name_check CHECK (((char_length(name) >= 1) AND (char_length(name) <= 60))),
    CONSTRAINT collections_reserved_slug CHECK ((slug <> ALL (ARRAY['altro'::text, 'pronta-consegna'::text]))),
    CONSTRAINT collections_slug_check CHECK (((slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text) AND (char_length(slug) <= 60)))
);

-- Name: menu_items; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.menu_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    label text NOT NULL,
    page_id uuid,
    url text,
    "position" integer DEFAULT 0 NOT NULL,
    CONSTRAINT menu_items_label_check CHECK (((char_length(label) >= 1) AND (char_length(label) <= 30))),
    CONSTRAINT menu_items_url_check CHECK (((char_length(url) <= 300) AND (url ~ '^(https://|/)[^\s]*$'::text))),
    CONSTRAINT menu_target CHECK (((page_id IS NULL) <> (url IS NULL)))
);

-- Name: pages; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.pages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug text NOT NULL,
    title text NOT NULL,
    seo jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_home boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pages_slug_check CHECK (((slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text) AND (char_length(slug) <= 60) AND (slug <> ALL (ARRAY['admin'::text, 'api'::text, 'login'::text, 'prodotti'::text, 'collezioni'::text, 'cerca'::text, 'sitemap'::text])))),
    CONSTRAINT pages_title_check CHECK (((char_length(title) >= 1) AND (char_length(title) <= 80)))
);

-- Name: product_collections; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.product_collections (
    product_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);

-- Name: products; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug text NOT NULL,
    title text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    price numeric(10,2),
    compare_at_price numeric(10,2),
    status text DEFAULT 'disponibile'::text NOT NULL,
    photos jsonb DEFAULT '[]'::jsonb NOT NULL,
    options jsonb DEFAULT '[]'::jsonb NOT NULL,
    vinted_url text,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    lead_time text,
    show_lead_time boolean DEFAULT false NOT NULL,
    CONSTRAINT compare_price_valid CHECK (((compare_at_price IS NULL) OR ((price IS NOT NULL) AND (compare_at_price > price)))),
    CONSTRAINT products_description_check CHECK ((char_length(description) <= 5000)),
    CONSTRAINT products_lead_time_check CHECK (((char_length(lead_time) >= 1) AND (char_length(lead_time) <= 80))),
    CONSTRAINT products_price_check CHECK (((price >= (0)::numeric) AND (price <= (100000)::numeric))),
    CONSTRAINT products_slug_check CHECK (((slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text) AND (char_length(slug) <= 80))),
    CONSTRAINT products_status_check CHECK ((status = ANY (ARRAY['disponibile'::text, 'su_ordinazione'::text, 'venduto'::text, 'nascosto'::text]))),
    CONSTRAINT products_title_check CHECK (((char_length(title) >= 1) AND (char_length(title) <= 120))),
    CONSTRAINT products_vinted_url_check CHECK ((vinted_url ~* '^https://(www\.)?vinted\.[a-z.]+/'::text))
);

-- Name: setting_schemas; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.setting_schemas (
    key text NOT NULL,
    label text NOT NULL,
    schema jsonb NOT NULL
);

-- Name: site_settings; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.site_settings (
    id smallint DEFAULT 1 NOT NULL,
    site_name text NOT NULL,
    logo_path text,
    theme jsonb NOT NULL,
    contacts jsonb NOT NULL,
    seo jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    header jsonb DEFAULT '{}'::jsonb NOT NULL,
    badges jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT site_settings_id_check CHECK ((id = 1)),
    CONSTRAINT site_settings_logo_path_check CHECK (((char_length(logo_path) <= 300) AND (logo_path ~ '^[a-zA-Z0-9/_.-]+$'::text))),
    CONSTRAINT site_settings_site_name_check CHECK (((char_length(site_name) >= 1) AND (char_length(site_name) <= 60)))
);

-- Name: site_versions; Type: TABLE; Schema: public; Owner: -

CREATE TABLE public.site_versions (
    id bigint NOT NULL,
    snapshot jsonb NOT NULL,
    note text,
    is_live boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone DEFAULT now() NOT NULL,
    published_by uuid,
    CONSTRAINT site_versions_note_check CHECK ((char_length(note) <= 200))
);

-- Name: site_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -

ALTER TABLE public.site_versions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.site_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: private; Owner: -

ALTER TABLE ONLY private.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (user_id);

-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: private; Owner: -

ALTER TABLE ONLY private.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (id);

-- Name: block_types block_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.block_types
    ADD CONSTRAINT block_types_pkey PRIMARY KEY (type);

-- Name: blocks blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_pkey PRIMARY KEY (id);

-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);

-- Name: collections collections_slug_key; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_slug_key UNIQUE (slug);

-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);

-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);

-- Name: pages pages_slug_key; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_slug_key UNIQUE (slug);

-- Name: product_collections product_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.product_collections
    ADD CONSTRAINT product_collections_pkey PRIMARY KEY (product_id, collection_id);

-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);

-- Name: products products_slug_key; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_slug_key UNIQUE (slug);

-- Name: setting_schemas setting_schemas_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.setting_schemas
    ADD CONSTRAINT setting_schemas_pkey PRIMARY KEY (key);

-- Name: site_settings site_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);

-- Name: site_versions site_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.site_versions
    ADD CONSTRAINT site_versions_pkey PRIMARY KEY (id);

-- Name: blocks_page_idx; Type: INDEX; Schema: public; Owner: -

CREATE INDEX blocks_page_idx ON public.blocks USING btree (page_id, "position");

-- Name: pages_single_home; Type: INDEX; Schema: public; Owner: -

CREATE UNIQUE INDEX pages_single_home ON public.pages USING btree (is_home) WHERE is_home;

-- Name: product_collections_coll_idx; Type: INDEX; Schema: public; Owner: -

CREATE INDEX product_collections_coll_idx ON public.product_collections USING btree (collection_id, "position");

-- Name: site_versions_single_live; Type: INDEX; Schema: public; Owner: -

CREATE UNIQUE INDEX site_versions_single_live ON public.site_versions USING btree (is_live) WHERE is_live;

-- Name: blocks blocks_updated; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER blocks_updated BEFORE UPDATE ON public.blocks FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

-- Name: blocks blocks_validate; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER blocks_validate BEFORE INSERT OR UPDATE ON public.blocks FOR EACH ROW EXECUTE FUNCTION private.validate_block();

-- Name: collections collections_notify; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER collections_notify AFTER INSERT OR DELETE OR UPDATE ON public.collections FOR EACH STATEMENT EXECUTE FUNCTION private.notify_site();

-- Name: pages pages_protect_home; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER pages_protect_home BEFORE DELETE ON public.pages FOR EACH ROW EXECUTE FUNCTION private.protect_home();

-- Name: pages pages_updated; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER pages_updated BEFORE UPDATE ON public.pages FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

-- Name: pages pages_validate; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER pages_validate BEFORE INSERT OR UPDATE ON public.pages FOR EACH ROW EXECUTE FUNCTION private.validate_page();

-- Name: product_collections product_collections_notify; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER product_collections_notify AFTER INSERT OR DELETE OR UPDATE ON public.product_collections FOR EACH STATEMENT EXECUTE FUNCTION private.notify_site();

-- Name: products products_notify; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER products_notify AFTER INSERT OR DELETE OR UPDATE ON public.products FOR EACH STATEMENT EXECUTE FUNCTION private.notify_site();

-- Name: products products_updated; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER products_updated BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

-- Name: products products_validate; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER products_validate BEFORE INSERT OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION private.validate_product();

-- Name: site_settings site_settings_updated; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER site_settings_updated BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

-- Name: site_settings site_settings_validate; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER site_settings_validate BEFORE INSERT OR UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION private.validate_settings();

-- Name: site_versions site_versions_notify; Type: TRIGGER; Schema: public; Owner: -

CREATE TRIGGER site_versions_notify AFTER INSERT ON public.site_versions FOR EACH STATEMENT EXECUTE FUNCTION private.notify_site();

-- Name: admins admins_user_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: -

ALTER TABLE ONLY private.admins
    ADD CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Name: blocks blocks_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_page_id_fkey FOREIGN KEY (page_id) REFERENCES public.pages(id) ON DELETE CASCADE;

-- Name: blocks blocks_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_type_fkey FOREIGN KEY (type) REFERENCES public.block_types(type);

-- Name: menu_items menu_items_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_page_id_fkey FOREIGN KEY (page_id) REFERENCES public.pages(id) ON DELETE CASCADE;

-- Name: product_collections product_collections_collection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.product_collections
    ADD CONSTRAINT product_collections_collection_id_fkey FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;

-- Name: product_collections product_collections_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -

ALTER TABLE ONLY public.product_collections
    ADD CONSTRAINT product_collections_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

-- Name: admins; Type: ROW SECURITY; Schema: private; Owner: -

ALTER TABLE private.admins ENABLE ROW LEVEL SECURITY;

-- Name: app_config; Type: ROW SECURITY; Schema: private; Owner: -

ALTER TABLE private.app_config ENABLE ROW LEVEL SECURITY;

-- Name: blocks admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.blocks TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: collections admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.collections TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: menu_items admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.menu_items TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: pages admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.pages TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: product_collections admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.product_collections TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: products admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.products TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: site_settings admin gestisce; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin gestisce" ON public.site_settings TO authenticated USING (( SELECT public.is_admin() AS is_admin)) WITH CHECK (( SELECT public.is_admin() AS is_admin));

-- Name: block_types admin legge; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin legge" ON public.block_types FOR SELECT TO authenticated USING (( SELECT public.is_admin() AS is_admin));

-- Name: setting_schemas admin legge; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin legge" ON public.setting_schemas FOR SELECT TO authenticated USING (( SELECT public.is_admin() AS is_admin));

-- Name: site_versions admin legge; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "admin legge" ON public.site_versions FOR SELECT TO authenticated USING (( SELECT public.is_admin() AS is_admin));

-- Name: product_collections associazioni pubbliche; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "associazioni pubbliche" ON public.product_collections FOR SELECT TO anon, authenticated USING (true);

-- Name: block_types; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.block_types ENABLE ROW LEVEL SECURITY;

-- Name: blocks; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

-- Name: products catalogo pubblico; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "catalogo pubblico" ON public.products FOR SELECT TO anon, authenticated USING (((deleted_at IS NULL) AND (status <> 'nascosto'::text)));

-- Name: collections; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;

-- Name: collections collezioni pubbliche; Type: POLICY; Schema: public; Owner: -

CREATE POLICY "collezioni pubbliche" ON public.collections FOR SELECT TO anon, authenticated USING (true);

-- Name: menu_items; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;

-- Name: pages; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;

-- Name: product_collections; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.product_collections ENABLE ROW LEVEL SECURITY;

-- Name: products; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Name: setting_schemas; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.setting_schemas ENABLE ROW LEVEL SECURITY;

-- Name: site_settings; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

-- Name: site_versions; Type: ROW SECURITY; Schema: public; Owner: -

ALTER TABLE public.site_versions ENABLE ROW LEVEL SECURITY;

-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -

GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;

-- Name: FUNCTION build_snapshot(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.build_snapshot() FROM PUBLIC;

-- Name: FUNCTION do_publish(p_note text); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.do_publish(p_note text) FROM PUBLIC;

-- Name: FUNCTION load_snapshot(v jsonb); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.load_snapshot(v jsonb) FROM PUBLIC;

-- Name: FUNCTION protect_home(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.protect_home() FROM PUBLIC;

-- Name: FUNCTION set_updated_at(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.set_updated_at() FROM PUBLIC;

-- Name: FUNCTION validate_block(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.validate_block() FROM PUBLIC;

-- Name: FUNCTION validate_page(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.validate_page() FROM PUBLIC;

-- Name: FUNCTION validate_product(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.validate_product() FROM PUBLIC;

-- Name: FUNCTION validate_settings(); Type: ACL; Schema: private; Owner: -

REVOKE ALL ON FUNCTION private.validate_settings() FROM PUBLIC;

-- Name: FUNCTION block_defaults(p_type text); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.block_defaults(p_type text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_defaults(p_type text) TO authenticated;

-- Name: FUNCTION discard_draft(); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.discard_draft() FROM PUBLIC;
GRANT ALL ON FUNCTION public.discard_draft() TO authenticated;

-- Name: FUNCTION draft_status(); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.draft_status() FROM PUBLIC;
GRANT ALL ON FUNCTION public.draft_status() TO authenticated;

-- Name: FUNCTION get_draft_site(p_token text); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.get_draft_site(p_token text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_draft_site(p_token text) TO anon;
GRANT ALL ON FUNCTION public.get_draft_site(p_token text) TO authenticated;

-- Name: FUNCTION get_live_site(); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.get_live_site() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_live_site() TO anon;
GRANT ALL ON FUNCTION public.get_live_site() TO authenticated;

-- Name: FUNCTION get_preview_token(); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.get_preview_token() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_preview_token() TO authenticated;

-- Name: FUNCTION is_admin(); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT ALL ON FUNCTION public.is_admin() TO authenticated;

-- Name: FUNCTION load_version_to_draft(p_version_id bigint); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.load_version_to_draft(p_version_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.load_version_to_draft(p_version_id bigint) TO authenticated;

-- Name: FUNCTION publish_site(p_note text); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.publish_site(p_note text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.publish_site(p_note text) TO authenticated;

-- Name: FUNCTION restore_version(p_version_id bigint); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.restore_version(p_version_id bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.restore_version(p_version_id bigint) TO authenticated;

-- Name: FUNCTION set_home_page(p_page_id uuid); Type: ACL; Schema: public; Owner: -

REVOKE ALL ON FUNCTION public.set_home_page(p_page_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_home_page(p_page_id uuid) TO authenticated;

-- Name: TABLE block_types; Type: ACL; Schema: public; Owner: -

GRANT SELECT ON TABLE public.block_types TO authenticated;
GRANT ALL ON TABLE public.block_types TO service_role;

-- Name: TABLE blocks; Type: ACL; Schema: public; Owner: -

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.blocks TO authenticated;
GRANT ALL ON TABLE public.blocks TO service_role;

-- Name: TABLE collections; Type: ACL; Schema: public; Owner: -

GRANT SELECT ON TABLE public.collections TO anon;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.collections TO authenticated;
GRANT ALL ON TABLE public.collections TO service_role;

-- Name: TABLE menu_items; Type: ACL; Schema: public; Owner: -

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.menu_items TO authenticated;
GRANT ALL ON TABLE public.menu_items TO service_role;

-- Name: TABLE pages; Type: ACL; Schema: public; Owner: -

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pages TO authenticated;
GRANT ALL ON TABLE public.pages TO service_role;

-- Name: TABLE product_collections; Type: ACL; Schema: public; Owner: -

GRANT SELECT ON TABLE public.product_collections TO anon;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.product_collections TO authenticated;
GRANT ALL ON TABLE public.product_collections TO service_role;

-- Name: TABLE products; Type: ACL; Schema: public; Owner: -

GRANT SELECT ON TABLE public.products TO anon;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.products TO authenticated;
GRANT ALL ON TABLE public.products TO service_role;

-- Name: TABLE setting_schemas; Type: ACL; Schema: public; Owner: -

GRANT SELECT ON TABLE public.setting_schemas TO authenticated;
GRANT ALL ON TABLE public.setting_schemas TO service_role;

-- Name: TABLE site_settings; Type: ACL; Schema: public; Owner: -

GRANT SELECT,UPDATE ON TABLE public.site_settings TO authenticated;
GRANT ALL ON TABLE public.site_settings TO service_role;

-- Name: TABLE site_versions; Type: ACL; Schema: public; Owner: -

GRANT SELECT ON TABLE public.site_versions TO authenticated;
GRANT ALL ON TABLE public.site_versions TO service_role;

-- PostgreSQL database dump complete

\unrestrict 6ARrdNmTkn1X1TkvNE0cWPBq9zuzQAPlbMbcG8ylTIgNeRGl53gM36CTAng7f17


-- =====================================================================
--  Dati: tipi di sezione (block_types) e schemi delle impostazioni
-- =====================================================================
-- PostgreSQL database dump

\restrict 5mQn5qbefz83SSgJwXHJFVmx9NubFQ4Yd5Rrd8WPnJ8xhJSg6e5RUn24FyNDCWg

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

-- Data for Name: block_types; Type: TABLE DATA; Schema: public; Owner: -

INSERT INTO public.block_types VALUES ('banner', 'Avviso', '{"type": "object", "x-order": ["text", "link", "messages", "effect", "speed", "style"], "required": ["text"], "properties": {"link": {"type": "string", "pattern": "^(https://|/)[^\\s]{0,299}$", "x-label": "Link (facoltativo)", "x-widget": "link"}, "text": {"type": "string", "default": "Spedizioni in tutta Italia", "x-label": "Messaggio", "maxLength": 140, "minLength": 1}, "speed": {"enum": ["slow", "normal", "fast"], "default": "normal", "x-label": "Velocità", "x-enum-labels": ["Lenta", "Normale", "Veloce"]}, "style": {"enum": ["info", "highlight", "sale"], "default": "info", "x-label": "Stile", "x-enum-labels": ["Informazione", "In evidenza", "Saldi"]}, "effect": {"enum": ["static", "marquee", "fade", "slide"], "default": "static", "x-label": "Effetto", "x-enum-labels": ["Fisso", "Scorre da destra a sinistra", "Cambia in dissolvenza", "Cambia salendo dal basso"]}, "messages": {"type": "array", "items": {"type": "object", "x-order": ["text", "link"], "required": ["text"], "properties": {"link": {"type": "string", "pattern": "^(https://|/)[^\\s]{0,299}$", "x-label": "Link (facoltativo)", "x-widget": "link"}, "text": {"type": "string", "x-label": "Messaggio", "maxLength": 140, "minLength": 1}}, "additionalProperties": false}, "default": [], "x-label": "Altri messaggi (si alternano con il primo)", "maxItems": 6}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del testo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 90, true);
INSERT INTO public.block_types VALUES ('category_menu', 'Menu categorie', '{"type": "object", "x-order": ["title", "style", "columns", "tile_shape", "show_ready", "ready_label", "ready_cover", "show_other", "other_label", "other_cover", "hide_empty"], "properties": {"style": {"enum": ["tiles", "circles", "carousel", "buttons"], "default": "tiles", "x-label": "Aspetto", "x-enum-labels": ["Riquadri con foto", "Cerchi con foto", "Riquadri a scorrimento", "Pulsanti"]}, "title": {"type": "string", "default": "Scegli una categoria", "x-label": "Titolo", "maxLength": 80}, "columns": {"enum": [2, 3, 4], "default": 4, "x-label": "Riquadri per riga (su computer)"}, "hide_empty": {"type": "boolean", "default": true, "x-label": "Nascondi le categorie vuote"}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "show_other": {"type": "boolean", "default": true, "x-label": "Mostra i pezzi senza categoria"}, "show_ready": {"type": "boolean", "default": true, "x-label": "Mostra i pezzi pronti"}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "tile_shape": {"enum": ["square", "landscape", "portrait"], "default": "landscape", "x-label": "Forma dei riquadri", "x-enum-labels": ["Quadrati", "Orizzontali", "Verticali"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "other_cover": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Foto per i pezzi senza categoria", "x-widget": "image"}, "other_label": {"type": "string", "default": "Altro", "x-label": "Nome per i pezzi senza categoria", "maxLength": 40, "minLength": 1}, "ready_cover": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Foto per i pezzi pronti", "x-widget": "image"}, "ready_label": {"type": "string", "default": "Disponibili in pronta consegna", "x-label": "Nome per i pezzi pronti", "maxLength": 40, "minLength": 1}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 35, true);
INSERT INTO public.block_types VALUES ('faq', 'Domande frequenti', '{"type": "object", "x-order": ["title", "items"], "properties": {"items": {"type": "array", "items": {"type": "object", "x-order": ["question", "answer"], "required": ["question", "answer"], "properties": {"answer": {"type": "string", "x-label": "Risposta", "x-widget": "textarea", "maxLength": 1000, "minLength": 1}, "question": {"type": "string", "x-label": "Domanda", "maxLength": 150, "minLength": 1}}, "additionalProperties": false}, "default": [], "x-label": "Domande", "maxItems": 20}, "title": {"type": "string", "default": "Domande frequenti", "x-label": "Titolo", "maxLength": 80}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 70, true);
INSERT INTO public.block_types VALUES ('spacer', 'Spazio', '{"type": "object", "x-order": ["size", "divider"], "properties": {"size": {"enum": ["small", "medium", "large"], "default": "medium", "x-label": "Altezza", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "divider": {"type": "boolean", "default": false, "x-label": "Mostra una linea"}}, "additionalProperties": false}', 100, true);
INSERT INTO public.block_types VALUES ('hero', 'Copertina', '{"type": "object", "x-order": ["title", "subtitle", "image", "layout", "button_text", "button_link"], "required": ["title"], "properties": {"image": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Immagine", "x-widget": "image"}, "title": {"type": "string", "default": "Fatto a mano, con amore", "x-label": "Titolo", "maxLength": 80, "minLength": 1}, "layout": {"enum": ["center", "left", "full_image"], "default": "center", "x-label": "Disposizione", "x-enum-labels": ["Centrata", "A sinistra", "Immagine a tutto schermo"]}, "subtitle": {"type": "string", "x-label": "Sottotitolo", "x-widget": "textarea", "maxLength": 200}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "button_link": {"type": "string", "pattern": "^(https://|/)[^\\s]{0,299}$", "x-label": "Link del bottone", "x-widget": "link"}, "button_text": {"type": "string", "x-label": "Testo del bottone", "maxLength": 30}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 10, true);
INSERT INTO public.block_types VALUES ('contact', 'Contatti', '{"type": "object", "x-order": ["title", "text", "show_whatsapp", "show_email", "show_vinted", "show_instagram"], "properties": {"text": {"type": "string", "x-label": "Testo", "x-widget": "textarea", "maxLength": 500}, "title": {"type": "string", "default": "Scrivimi", "x-label": "Titolo", "maxLength": 80}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "show_email": {"type": "boolean", "default": true, "x-label": "Mostra email"}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "show_vinted": {"type": "boolean", "default": true, "x-label": "Mostra Vinted"}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "show_whatsapp": {"type": "boolean", "default": true, "x-label": "Mostra WhatsApp"}, "show_instagram": {"type": "boolean", "default": true, "x-label": "Mostra Instagram"}}, "additionalProperties": false}', 80, true);
INSERT INTO public.block_types VALUES ('text', 'Testo', '{"type": "object", "x-order": ["title", "body", "align"], "properties": {"body": {"type": "string", "default": "", "x-label": "Testo", "x-widget": "textarea", "maxLength": 5000}, "align": {"enum": ["left", "center"], "default": "left", "x-label": "Allineamento", "x-enum-labels": ["A sinistra", "Centrato"]}, "title": {"type": "string", "x-label": "Titolo", "maxLength": 80}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 20, true);
INSERT INTO public.block_types VALUES ('gallery', 'Galleria foto', '{"type": "object", "x-order": ["title", "images", "style", "columns"], "properties": {"style": {"enum": ["grid", "carousel"], "default": "grid", "x-label": "Stile", "x-enum-labels": ["Griglia", "Scorrimento"]}, "title": {"type": "string", "x-label": "Titolo", "maxLength": 80}, "images": {"type": "array", "items": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$"}, "default": [], "x-label": "Foto", "maxItems": 24, "x-widget": "images"}, "columns": {"enum": [2, 3, 4], "default": 3, "x-label": "Colonne"}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 30, true);
INSERT INTO public.block_types VALUES ('featured_product', 'Prodotto in evidenza', '{"type": "object", "x-order": ["product_id", "text", "layout"], "properties": {"text": {"type": "string", "x-label": "Testo aggiuntivo", "x-widget": "textarea", "maxLength": 300}, "layout": {"enum": ["image_left", "image_right"], "default": "image_left", "x-label": "Disposizione", "x-enum-labels": ["Foto a sinistra", "Foto a destra"]}, "product_id": {"type": "string", "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", "x-label": "Prodotto", "x-widget": "product"}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 50, true);
INSERT INTO public.block_types VALUES ('testimonials', 'Recensioni', '{"type": "object", "x-order": ["title", "items"], "properties": {"items": {"type": "array", "items": {"type": "object", "x-order": ["name", "text"], "required": ["name", "text"], "properties": {"name": {"type": "string", "x-label": "Nome", "maxLength": 40, "minLength": 1}, "text": {"type": "string", "x-label": "Recensione", "x-widget": "textarea", "maxLength": 400, "minLength": 1}}, "additionalProperties": false}, "default": [], "x-label": "Recensioni", "maxItems": 12}, "title": {"type": "string", "default": "Dicono di me", "x-label": "Titolo", "maxLength": 80}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}}, "additionalProperties": false}', 60, true);
INSERT INTO public.block_types VALUES ('product_grid', 'Griglia prodotti', '{"type": "object", "x-order": ["title", "collection_id", "style", "ribbon_links", "ribbon_names", "columns", "limit", "sort", "show_price", "show_sold"], "properties": {"sort": {"enum": ["manual", "newest", "price_asc", "price_desc"], "default": "newest", "x-label": "Ordine", "x-enum-labels": ["Manuale", "Più recenti", "Prezzo crescente", "Prezzo decrescente"]}, "limit": {"type": "integer", "default": 12, "maximum": 48, "minimum": 1, "x-label": "Quanti prodotti mostrare"}, "style": {"enum": ["ribbon", "grid", "carousel"], "default": "ribbon", "x-label": "Aspetto", "x-enum-labels": ["Nastro che scorre (solo vetrina)", "Griglia", "A scorrimento"]}, "title": {"type": "string", "default": "I miei lavori", "x-label": "Titolo", "maxLength": 80}, "columns": {"enum": [2, 3, 4], "default": 3, "x-label": "Colonne"}, "show_sold": {"type": "boolean", "default": true, "x-label": "Mostra anche i venduti"}, "section_bg": {"enum": ["none", "soft", "primary", "accent"], "default": "none", "x-group": "style", "x-label": "Sfondo della sezione", "x-enum-labels": ["Nessuno", "Leggero", "Colore principale", "Colore secondario"]}, "show_price": {"type": "boolean", "default": true, "x-label": "Mostra prezzi"}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile dei testi", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "title_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "style", "x-label": "Carattere del titolo", "x-widget": "font", "x-enum-labels": ["Come il resto del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "title_size": {"enum": ["s", "m", "l"], "default": "m", "x-group": "style", "x-label": "Grandezza del titolo", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "title_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "style", "x-label": "Stile del titolo", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "ribbon_links": {"type": "boolean", "default": false, "x-label": "Nel nastro, toccando un lavoro si apre la sua scheda"}, "ribbon_names": {"type": "boolean", "default": true, "x-label": "Nel nastro, mostra i nomi dei lavori"}, "collection_id": {"type": "string", "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", "x-label": "Collezione (vuoto = tutti i prodotti)", "x-widget": "collection"}}, "additionalProperties": false}', 40, true);

-- Data for Name: setting_schemas; Type: TABLE DATA; Schema: public; Owner: -

INSERT INTO public.setting_schemas VALUES ('theme', 'Tema', '{"type": "object", "required": ["primary", "background", "text", "accent", "font_heading", "font_body", "radius"], "properties": {"text": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore del testo", "x-widget": "color"}, "accent": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore secondario", "x-widget": "color"}, "radius": {"enum": ["none", "small", "medium", "large"], "x-label": "Angoli", "x-enum-labels": ["Squadrati", "Poco arrotondati", "Arrotondati", "Molto arrotondati"]}, "primary": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Colore principale", "x-widget": "color"}, "font_body": {"enum": ["Nunito", "Quicksand", "DM Sans", "Lato", "Lora"], "x-label": "Font del testo"}, "background": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-label": "Sfondo", "x-widget": "color"}, "font_heading": {"enum": ["Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand"], "x-label": "Font dei titoli"}}, "additionalProperties": false}');
INSERT INTO public.setting_schemas VALUES ('contacts', 'Contatti e canali d''ordine', '{"type": "object", "properties": {"email": {"if": {"required": ["enabled"], "properties": {"enabled": {"const": true}}}, "then": {"required": ["address"]}, "type": "object", "x-label": "Email", "properties": {"address": {"type": "string", "pattern": "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", "x-label": "Indirizzo", "maxLength": 200}, "enabled": {"type": "boolean", "x-label": "Attiva"}, "body_template": {"type": "string", "pattern": "^([^{}]|\\{(prodotto|prezzo|opzione|link)\\})*$", "x-label": "Testo precompilato", "x-widget": "template", "maxLength": 1000}, "subject_template": {"type": "string", "pattern": "^([^{}]|\\{(prodotto|prezzo|opzione|link)\\})*$", "x-label": "Oggetto precompilato", "x-widget": "template", "maxLength": 150}}, "additionalProperties": false}, "vinted": {"if": {"required": ["enabled"], "properties": {"enabled": {"const": true}}}, "then": {"required": ["profile_url"]}, "type": "object", "x-label": "Vinted", "properties": {"enabled": {"type": "boolean", "x-label": "Attivo"}, "profile_url": {"type": "string", "pattern": "^https://(www\\.)?vinted\\.[a-z.]+/", "x-label": "Link al profilo Vinted", "maxLength": 300}}, "additionalProperties": false}, "whatsapp": {"if": {"required": ["enabled"], "properties": {"enabled": {"const": true}}}, "then": {"required": ["number"]}, "type": "object", "x-label": "WhatsApp", "properties": {"number": {"type": "string", "pattern": "^[1-9][0-9]{7,14}$", "x-label": "Numero con prefisso, senza + (es. 393331234567)"}, "enabled": {"type": "boolean", "x-label": "Attivo"}, "template": {"type": "string", "pattern": "^([^{}]|\\{(prodotto|prezzo|opzione|link)\\})*$", "x-label": "Messaggio precompilato", "x-widget": "template", "maxLength": 500}}, "additionalProperties": false}, "instagram": {"if": {"required": ["enabled"], "properties": {"enabled": {"const": true}}}, "then": {"required": ["profile_url"]}, "type": "object", "x-label": "Instagram", "properties": {"enabled": {"type": "boolean", "x-label": "Attivo"}, "profile_url": {"type": "string", "pattern": "^https://(www\\.)?instagram\\.com/", "x-label": "Link al profilo Instagram", "maxLength": 300}}, "additionalProperties": false}}, "additionalProperties": false}');
INSERT INTO public.setting_schemas VALUES ('seo', 'SEO', '{"type": "object", "properties": {"image": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$", "x-label": "Immagine di anteprima", "x-widget": "image"}, "title": {"type": "string", "x-label": "Titolo per Google", "maxLength": 70}, "description": {"type": "string", "x-label": "Descrizione per Google", "x-widget": "textarea", "maxLength": 160}}, "additionalProperties": false}');
INSERT INTO public.setting_schemas VALUES ('product_photos', 'Foto prodotto', '{"type": "array", "items": {"type": "string", "pattern": "^[a-zA-Z0-9/_.-]{1,300}$"}, "maxItems": 12}');
INSERT INTO public.setting_schemas VALUES ('product_options', 'Opzioni prodotto', '{"type": "array", "items": {"type": "object", "required": ["name", "values"], "properties": {"name": {"type": "string", "x-label": "Nome opzione (es. Colore)", "maxLength": 30, "minLength": 1}, "values": {"type": "array", "items": {"type": "string", "maxLength": 30, "minLength": 1}, "x-label": "Valori", "maxItems": 20, "minItems": 1}}, "additionalProperties": false}, "maxItems": 5}');
INSERT INTO public.setting_schemas VALUES ('header', 'Intestazione', '{"type": "object", "x-order": ["show_logo", "logo_size", "show_name", "name_size", "name_font", "name_style", "align", "arrangement"], "properties": {"align": {"enum": ["left", "center", "right"], "default": "left", "x-label": "Posizione", "x-enum-labels": ["A sinistra", "Al centro", "A destra"]}, "logo_size": {"enum": ["s", "m", "l", "xl"], "default": "m", "x-label": "Grandezza del logo", "x-enum-labels": ["Piccolo", "Medio", "Grande", "Molto grande"]}, "name_font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-label": "Carattere del nome", "x-widget": "font", "x-enum-labels": ["Come i titoli del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "name_size": {"enum": ["s", "m", "l"], "default": "m", "x-label": "Grandezza del nome", "x-enum-labels": ["Piccolo", "Medio", "Grande"]}, "show_logo": {"type": "boolean", "default": true, "x-label": "Mostra il logo"}, "show_name": {"type": "boolean", "default": true, "x-label": "Mostra il nome del negozio"}, "name_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-label": "Stile del nome", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "arrangement": {"enum": ["row", "stack"], "default": "row", "x-label": "Logo e nome", "x-enum-labels": ["Uno accanto all''altro", "Logo sopra il nome"]}}, "additionalProperties": false}');
INSERT INTO public.setting_schemas VALUES ('badges', 'Etichette dei pezzi', '{"type": "object", "x-order": ["show", "font", "text_style", "position", "ready_show", "ready_text", "ready_bg", "ready_color", "order_show", "order_text", "order_bg", "order_color", "sold_show", "sold_text", "sold_bg", "sold_color"], "x-groups": {"all": {"label": "Per tutte le etichette"}, "sold": {"label": "Venduto"}, "order": {"label": "Su ordinazione"}, "ready": {"label": "Disponibile"}}, "properties": {"font": {"enum": ["theme", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"], "default": "theme", "x-group": "all", "x-label": "Carattere", "x-widget": "font", "x-enum-labels": ["Come i testi del sito", "Fraunces", "Playfair Display", "Lora", "DM Serif Display", "Nunito", "Quicksand", "DM Sans", "Lato"]}, "show": {"type": "boolean", "default": true, "x-group": "all", "x-label": "Mostra le etichette sui pezzi"}, "sold_bg": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-group": "sold", "x-label": "Colore di sfondo", "x-widget": "color"}, "order_bg": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-group": "order", "x-label": "Colore di sfondo", "x-widget": "color"}, "position": {"enum": ["top_left", "top_right", "bottom_left", "bottom_right"], "default": "top_left", "x-group": "all", "x-label": "Posizione sulla foto", "x-enum-labels": ["In alto a sinistra", "In alto a destra", "In basso a sinistra", "In basso a destra"]}, "ready_bg": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-group": "ready", "x-label": "Colore di sfondo", "x-widget": "color"}, "sold_show": {"type": "boolean", "default": true, "x-group": "sold", "x-label": "Mostra"}, "sold_text": {"type": "string", "default": "Venduto", "x-group": "sold", "x-label": "Testo", "maxLength": 30, "minLength": 1}, "order_show": {"type": "boolean", "default": true, "x-group": "order", "x-label": "Mostra"}, "order_text": {"type": "string", "default": "Su ordinazione", "x-group": "order", "x-label": "Testo", "maxLength": 30, "minLength": 1}, "ready_show": {"type": "boolean", "default": false, "x-group": "ready", "x-label": "Mostra"}, "ready_text": {"type": "string", "default": "Disponibile", "x-group": "ready", "x-label": "Testo", "maxLength": 30, "minLength": 1}, "sold_color": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-group": "sold", "x-label": "Colore del testo", "x-widget": "color"}, "text_style": {"enum": ["normal", "italic", "uppercase", "italic_uppercase"], "default": "normal", "x-group": "all", "x-label": "Stile", "x-enum-labels": ["Normale", "Corsivo", "Stampatello", "Corsivo stampatello"]}, "order_color": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-group": "order", "x-label": "Colore del testo", "x-widget": "color"}, "ready_color": {"type": "string", "pattern": "^#[0-9a-fA-F]{6}$", "x-group": "ready", "x-label": "Colore del testo", "x-widget": "color"}}, "additionalProperties": false}');

-- PostgreSQL database dump complete

\unrestrict 5mQn5qbefz83SSgJwXHJFVmx9NubFQ4Yd5Rrd8WPnJ8xhJSg6e5RUn24FyNDCWg


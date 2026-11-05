-- =====================================================================
--  Handmade by Bi — 004: anteprima prima di pubblicare
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase.
--  Le modifiche all'aspetto del sito (sezioni, stile, nome, contatti)
--  restano in BOZZA: si vedono nell'anteprima e vanno online solo con
--  "Pubblica". Pezzi e categorie restano immediati come prima.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Chiave dell'anteprima (chi ha il link vede la bozza, nient'altro)
-- ---------------------------------------------------------------------
alter table private.app_config add column if not exists preview_token text;
update private.app_config
set preview_token = encode(extensions.gen_random_bytes(24), 'hex')
where preview_token is null;

-- ---------------------------------------------------------------------
-- 2. Carica una versione nella bozza (senza pubblicare)
--    È la parte centrale di restore_version, ora riutilizzabile.
-- ---------------------------------------------------------------------
create or replace function private.load_snapshot(v jsonb)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if v is null then
    raise exception 'Versione non trovata';
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
end $$;

-- Ripristino immediato (resta disponibile, ora usa load_snapshot)
create or replace function public.restore_version(p_version_id bigint)
returns bigint language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  perform private.load_snapshot((select snapshot from public.site_versions where id = p_version_id));
  return private.do_publish(format('Ripristino della versione %s', p_version_id));
end $$;

-- Cronologia: riporta una versione nella bozza, da controllare in anteprima
create or replace function public.load_version_to_draft(p_version_id bigint)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  perform private.load_snapshot((select snapshot from public.site_versions where id = p_version_id));
end $$;

-- "Annulla modifiche": la bozza torna uguale al sito online
create or replace function public.discard_draft()
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  perform private.load_snapshot((select snapshot from public.site_versions where is_live));
end $$;

-- Ci sono modifiche non ancora pubblicate?
create or replace function public.draft_status()
returns boolean language plpgsql stable security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  return private.build_snapshot() is distinct from
         (select snapshot from public.site_versions where is_live);
end $$;

-- Chiave dell'anteprima, solo per l'app admin
create or replace function public.get_preview_token()
returns text language plpgsql stable security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Non autorizzato' using errcode = 'insufficient_privilege';
  end if;
  return (select preview_token from private.app_config where id = 1);
end $$;

-- La bozza, per la pagina /anteprima del sito (serve la chiave giusta)
create or replace function public.get_draft_site(p_token text)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
begin
  if p_token is null
     or p_token is distinct from (select preview_token from private.app_config where id = 1) then
    return null;
  end if;
  return private.build_snapshot();
end $$;

-- ---------------------------------------------------------------------
-- 3. Permessi
-- ---------------------------------------------------------------------
revoke execute on function private.load_snapshot(jsonb) from public;
revoke execute on function
  public.load_version_to_draft(bigint), public.discard_draft(), public.draft_status(),
  public.get_preview_token(), public.get_draft_site(text)
  from public, anon, authenticated;

grant execute on function public.get_draft_site(text) to anon, authenticated;
grant execute on function
  public.load_version_to_draft(bigint), public.discard_draft(), public.draft_status(),
  public.get_preview_token()
  to authenticated;

commit;

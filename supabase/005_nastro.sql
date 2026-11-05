-- =====================================================================
--  Handmade by Bi — 005: lavori in home come "nastro che scorre"
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase.
--  - nuovo aspetto "Nastro che scorre" per la sezione dei lavori
--    (solo vetrina: le foto scorrono e non si cliccano)
--  - le sezioni dei lavori già presenti passano al nastro
--  - se non c'erano modifiche in sospeso, il sito viene pubblicato;
--    altrimenti la novità resta in anteprima insieme alle altre
-- =====================================================================

begin;

update public.block_types
set schema = jsonb_set(schema, '{properties,style}', $j${
  "enum": ["ribbon", "grid", "carousel"], "default": "ribbon", "x-label": "Aspetto",
  "x-enum-labels": ["Nastro che scorre (solo vetrina)", "Griglia", "A scorrimento"]
}$j$::jsonb)
where type = 'product_grid';

do $$
declare
  pending boolean;
begin
  pending := private.build_snapshot() is distinct from
             (select snapshot from public.site_versions where is_live);

  update public.blocks
  set props = props || '{"style": "ribbon"}'::jsonb
  where type = 'product_grid';

  if not pending then
    perform private.do_publish('Lavori in home: nastro che scorre');
  end if;
end $$;

commit;

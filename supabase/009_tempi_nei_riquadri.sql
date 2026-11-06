-- =====================================================================
--  Handmade by Bi — 009: tempi di realizzazione anche nei riquadri
-- ---------------------------------------------------------------------
--  Da eseguire UNA volta nel SQL Editor di Supabase (dopo lo 008).
--  In "Etichette dei pezzi" compare il riquadro "Tempi di realizzazione"
--  con l'interruttore per mostrarli anche nelle griglie dei lavori,
--  sotto il prezzo. È spento: il sito non cambia finché Benedetta non
--  lo accende (e preme Pubblica, come per il resto dell'aspetto).
--  Cambia solo lo schema, non i valori salvati: niente da ripubblicare.
--  Si può rieseguire senza danni.
-- =====================================================================

begin;

update public.setting_schemas
set schema = jsonb_set(
      jsonb_set(schema, '{properties}', (schema->'properties') || $j${
        "lead_time_cards": {"type": "boolean", "default": false, "x-group": "lead",
                            "x-label": "Mostra i tempi nei riquadri dei pezzi"}
      }$j$::jsonb),
      '{x-groups}', coalesce(schema->'x-groups', '{}'::jsonb) || $j${
        "lead": {"label": "Tempi di realizzazione",
                 "hint": "Sotto il prezzo, nelle griglie dei lavori. Solo per i pezzi con «Mostra sul sito» acceso."}
      }$j$::jsonb)
    || jsonb_build_object('x-order', '["show", "font", "text_style", "position",
                                       "ready_show", "ready_text", "ready_bg", "ready_color",
                                       "order_show", "order_text", "order_bg", "order_color",
                                       "sold_show", "sold_text", "sold_bg", "sold_color",
                                       "lead_time_cards"]'::jsonb)
where key = 'badges';

commit;

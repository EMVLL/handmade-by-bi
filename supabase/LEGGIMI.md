# Handmade by Bi — Database (Supabase)

## Cosa c'è in questa cartella

| File | A cosa serve |
|---|---|
| `001_schema_iniziale.sql` … `008_tempi_realizzazione.sql` | Gli script numerati, nell'ordine in cui vanno eseguiti nel SQL Editor di Supabase |
| `schema_attuale_completo.sql` | Fotografia dello schema DOPO tutti gli script (tabelle, vincoli, funzioni, trigger, RLS, permessi + tipi di sezione e schemi delle impostazioni). **Solo da consultare, non da eseguire** |
| `schemi_json.json` | Gli schemi JSON attuali di ogni tipo di sezione e di ogni impostazione, leggibili |

## Script, in ordine

| Script | Cosa fa | Stato in produzione |
|---|---|---|
| 001_schema_iniziale | Schema base: tabelle, RLS, admin, 10 tipi di sezione, dati iniziali, prima pubblicazione | Eseguito |
| 002_categorie | 5 categorie, sezione "menu categorie", slug riservati (`altro`, `pronta-consegna`) | Eseguito |
| 003_negozio | Copertine categorie, aspetto delle sezioni, 4 forme del menu, carosello, avviso immediato al sito con `pg_net` (genera `revalidate_secret` da copiare su Netlify) | Eseguito |
| 004_anteprima | Token di anteprima e funzioni per bozza, cronologia e annullamento | Eseguito |
| 005_nastro | Lavori in home come nastro che scorre | Eseguito |
| 006_intestazione_avvisi | Intestazione personalizzabile, avvisi con più messaggi ed effetti, nastro cliccabile | Eseguito |
| 007_testi_etichette | Corsivo/stampatello, nomi nel nastro, etichette dei pezzi personalizzabili | Eseguito |
| 008_tempi_realizzazione | Tempi di realizzazione per pezzo (`lead_time`) con interruttore per mostrarli (`show_lead_time`) | Da eseguire prima di sito v2.5 e app v2.9 |

Dal 005 in poi gli script si possono rieseguire senza danni. Se non ci sono modifiche in sospeso ripubblicano il sito con aspetto identico, altrimenti lasciano la novità in bozza.

**Progetto Supabase nuovo da zero:** prima creare gli utenti in Authentication, poi mettere le loro email nella sezione 11 dello script 001, poi eseguire 001 → 008 in ordine. Alla fine del 003 copiare il `revalidate_secret` mostrato nella variabile `REVALIDATE_SECRET` di Netlify.

## Tabelle

**Schema `public`** (esposto via API, protetto da RLS: leggono tutti i dati pubblici, scrive solo chi è admin):

| Tabella | Contenuto |
|---|---|
| `products` | Pezzi: titolo, descrizione, prezzo e prezzo barrato, stato (`disponibile`, `su_ordinazione`, `venduto`, `nascosto`), foto, opzioni, link Vinted, tempi di realizzazione (`lead_time`, `show_lead_time`), cestino (`deleted_at`) |
| `collections` | Categorie: nome, slug, descrizione, copertina, ordine |
| `product_collections` | Collegamento pezzo ↔ categoria |
| `pages` | Pagine del sito (home + pagine extra), SEO |
| `blocks` | Sezioni di ogni pagina: tipo, ordine, visibile, contenuto (`props`, validato dallo schema del tipo) — BOZZA |
| `block_types` | Tipi di sezione e loro schema JSON |
| `menu_items` | Voci del menu in alto |
| `site_settings` | Nome, logo, stile (`theme`), contatti, SEO, intestazione (`header`), etichette (`badges`) — BOZZA |
| `setting_schemas` | Schemi JSON delle impostazioni (theme, contacts, seo, header, badges, product_options, product_photos) |
| `site_versions` | Versioni pubblicate: fotografia completa del sito (`snapshot`), quella online ha `is_live` |

**Schema `private`** (mai esposto):

| Tabella | Contenuto |
|---|---|
| `admins` | Utenti che possono modificare (Benedetta ed Emiliano) |
| `app_config` | Indirizzo del sito, segreto per l'aggiornamento immediato, token dell'anteprima |

## Bozza e pubblicazione

- Pezzi e categorie: si modificano direttamente e vanno online subito, perché il database avvisa il sito.
- Aspetto (`blocks`, `pages`, `menu_items`, `site_settings`): si modifica la bozza. **Pubblica** (`publish_site`) crea una riga in `site_versions` con la fotografia completa. Il sito legge solo quella online (`get_live_site`).
- Anteprima: `get_draft_site(token)` restituisce la bozza al sito, nella pagina `/anteprima?t=TOKEN`.
- Cronologia: `load_version_to_draft` riporta una versione vecchia in bozza; `discard_draft` annulla le modifiche non pubblicate; `draft_status` dice se ce ne sono.

import type { Collection, Product } from "./types";

// Tipo di un pezzo (Borse, Portachiavi, Cappelli…) per il filtro Categoria, ricavato in
// automatico quando il pezzo non ha un'altra categoria vera. Serve in pagine come
// "Disponibili", dove Benedetta mette tutto il pronto senza spuntare anche Borse ecc.
// (le pagine Borse ecc. restano solo per i modelli su ordinazione).
//
// Il tipo si legge dal NOME del pezzo; solo se il nome non dice nulla, dalla descrizione.
// Una categoria è riconosciuta dal suo nome (singolare o plurale: Borse ↔ borsa) e dalle
// parole tipiche qui sotto. Una categoria nuova creata da Benedetta funziona già con il
// suo nome; per altre parole basta aggiungerle a WORDS.

const normalize = (s: string) =>
  s
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();

/** Radice di una parola: senza la vocale finale (borsa/borse -> bors, cappello/cappelli -> cappell). */
const stem = (w: string) => (w.length > 4 ? w.replace(/[aeiou]$/, "") : w);

const words = (text: string) => normalize(text).split(/[^a-z0-9]+/).filter(Boolean);

/** Parole tipiche per categoria, indicate con la radice del nome della categoria. */
const WORDS: Record<string, string[]> = {
  bors: [
    "borsa", "borsetta", "borsello", "clutch", "pochette", "bag", "tracolla", "shopper", "tote",
    "zaino", "zainetto", "marsupio", "sacchetto", "secchiello", "bauletto", "baguette", "beauty",
    "astuccio", "portamonete", "portafoglio", "minibag", "handbag",
  ],
  portachiav: ["portachiavi", "keychain", "keyring", "ciondolo"],
  cappell: [
    "cappello", "berretto", "cuffia", "basco", "beanie", "bucket", "pescatore", "cloche",
    "colbacco", "passamontagna", "paraorecchie", "fascia", "fasce", "turbante",
  ],
  baby: [
    "baby", "neonato", "neonata", "neonati", "bimbo", "bimba", "bimbi", "bambino", "bambina",
    "scarpine", "scarpette", "bavaglino", "copertina", "sonaglio", "tutina", "cuffietta",
    "doudou", "carillon", "nascita", "battesimo",
  ],
  costum: ["costume", "bikini", "copricostume", "pareo", "slip", "trikini"],
};

/** Per ogni categoria, le radici che la riconoscono. */
function matchers(collections: Collection[]): { id: string; stems: Set<string> }[] {
  return collections.map((c) => {
    const own = [...words(c.name), ...words(c.slug.replace(/-/g, " "))].map(stem);
    const extra = own.flatMap((s) => WORDS[s] ?? []).map(stem);
    return { id: c.id, stems: new Set([...own, ...extra]) };
  });
}

function find(text: string, list: { id: string; stems: Set<string> }[]): string[] {
  const s = new Set(words(text).map(stem));
  return list.filter((m) => [...m.stems].some((x) => s.has(x))).map((m) => m.id);
}

/**
 * Categorie con cui filtrare un pezzo nella pagina `currentId`:
 * le sue altre categorie vere, altrimenti quelle ricavate da nome o descrizione.
 */
export function kindsFor(
  product: Product,
  collections: Collection[],
  currentId: string | undefined,
): string[] {
  const real = (product.product_collections ?? [])
    .map((pc) => pc.collection_id)
    .filter((id) => id !== currentId);
  if (real.length) return real;
  const list = matchers(collections.filter((c) => c.id !== currentId));
  const fromTitle = find(product.title, list);
  return fromTitle.length ? fromTitle : find(product.description ?? "", list);
}

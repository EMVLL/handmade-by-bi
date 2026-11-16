import { FAMILIES, colorFamilies, familiesInText, isColorOption, type ColorFamily } from "./colors";
import type { Product } from "./types";

// Filtri della pagina di una categoria, calcolati dai pezzi:
// - Categoria e Colore (sempre, se servono);
// - un gruppo per ogni altra opzione che Benedetta usa nei pezzi (Taglia, Materiale…);
// - Prezzo, con un cursore "fino a quanto spendere".
// Dentro un gruppo le scelte si sommano (Borse O Cappelli); tra gruppi diversi devono
// valere tutte (Borse E rosso E taglia M E fino a 30 €).

export interface FacetOption {
  value: string;
  label: string;
  /** Pezzi che rientrano in questa scelta */
  ids: string[];
  /** Solo per i colori: sfondo del pallino */
  swatch?: string | null;
}

export interface Facet {
  /** "category", "color" oppure "opt:<nome dell'opzione>" */
  key: string;
  label: string;
  options: FacetOption[];
}

/** Cursore del prezzo: dal pezzo più economico al più caro della pagina. */
export interface PriceRange {
  min: number;
  max: number;
  step: number;
}

export interface Selection {
  /** Scelte spuntate, per gruppo */
  choices?: Record<string, string[]>;
  /** Prezzo massimo scelto; assente = qualsiasi prezzo */
  maxPrice?: number;
}

export interface Filters {
  facets: Facet[];
  price: PriceRange | null;
}

/** Il cursore arriva al massimo a 999 €. */
export const PRICE_CEILING = 999;

const key = (s: string) =>
  s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim().replace(/\s+/g, " ");
const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

// ------------------------------------------------------------------ colore

/**
 * Colori per il filtro, raggruppati per famiglia (Verde, Rosa…).
 * Si leggono dall'opzione "Colore" del pezzo; se il pezzo non ce l'ha, dai colori scritti
 * nel titolo o nella descrizione ("Verde militare, Rosa"). Un nome che non è un colore
 * conosciuto compare com'è, senza pallino.
 */
function colorOptions(items: Product[]): FacetOption[] {
  const byKey = new Map<string, FacetOption>();
  const add = (k: string, label: string, swatch: string | null, id: string) => {
    const entry = byKey.get(k) ?? { value: k, label, ids: [], swatch };
    if (!entry.ids.includes(id)) entry.ids.push(id);
    byKey.set(k, entry);
  };
  const family = (f: ColorFamily) => FAMILIES.find((x) => x.key === f)!;

  for (const p of items) {
    const values = (p.options ?? []).filter((o) => isColorOption(o.name)).flatMap((o) => o.values ?? []);
    if (values.length) {
      for (const v of values) {
        const found = colorFamilies(v);
        for (const f of found) add(f, family(f).label, family(f).swatch, p.id);
        if (!found.length && key(v)) add(`altro:${key(v)}`, capitalize(v.trim()), null, p.id);
      }
    } else {
      for (const f of familiesInText(`${p.title} ${p.description ?? ""}`)) add(f, family(f).label, family(f).swatch, p.id);
    }
  }
  // Prima le famiglie nell'ordine dell'arcobaleno, poi i nomi non riconosciuti
  const order = (o: FacetOption) => {
    const i = FAMILIES.findIndex((f) => f.key === o.value);
    return i === -1 ? FAMILIES.length : i;
  };
  return [...byKey.values()].sort((a, b) => order(a) - order(b) || a.label.localeCompare(b.label, "it"));
}

// ------------------------------------------------------------------ altre opzioni

/** Nomi diversi per la stessa opzione: finiscono nello stesso gruppo. */
const SYNONYMS: Record<string, { key: string; label: string }> = {
  taglia: { key: "taglia", label: "Taglia" },
  taglie: { key: "taglia", label: "Taglia" },
  misura: { key: "taglia", label: "Taglia" },
  misure: { key: "taglia", label: "Taglia" },
  grandezza: { key: "taglia", label: "Taglia" },
  dimensione: { key: "taglia", label: "Taglia" },
  dimensioni: { key: "taglia", label: "Taglia" },
  size: { key: "taglia", label: "Taglia" },
  materiale: { key: "materiale", label: "Materiale" },
  materiali: { key: "materiale", label: "Materiale" },
  filato: { key: "materiale", label: "Materiale" },
};

/** Ordine logico delle taglie in lettere. */
const SIZE_ORDER = ["xxs", "xs", "s", "m", "l", "xl", "xxl", "xxxl", "unica", "taglia unica"];

/** "m" -> "M", "taglia unica" -> "Taglia unica", "0-3 mesi" resta com'è. */
function valueLabel(raw: string): string {
  const t = raw.trim().replace(/\s+/g, " ");
  return /^(x{0,3}s|m|x{0,3}l)$/i.test(t) ? t.toUpperCase() : capitalize(t);
}

function compareValues(a: FacetOption, b: FacetOption): number {
  const sa = SIZE_ORDER.indexOf(a.value), sb = SIZE_ORDER.indexOf(b.value);
  if (sa !== -1 || sb !== -1) return (sa === -1 ? 99 : sa) - (sb === -1 ? 99 : sb);
  // numeri in ordine di grandezza ("2 anni" prima di "10 anni")
  const na = parseFloat(a.value.replace(",", ".")), nb = parseFloat(b.value.replace(",", "."));
  if (!Number.isNaN(na) && !Number.isNaN(nb) && na !== nb) return na - nb;
  return a.label.localeCompare(b.label, "it", { numeric: true });
}

/** Un gruppo per ogni opzione (non di colore) usata dai pezzi della pagina. */
function optionFacets(items: Product[]): Facet[] {
  const groups = new Map<string, { label: string; values: Map<string, FacetOption>; products: Set<string> }>();
  for (const p of items) {
    for (const o of p.options ?? []) {
      const name = key(o.name ?? "");
      if (!name || isColorOption(o.name)) continue;
      const syn = SYNONYMS[name];
      const gKey = `opt:${syn?.key ?? name}`;
      const group = groups.get(gKey) ?? { label: syn?.label ?? capitalize(o.name.trim()), values: new Map(), products: new Set() };
      for (const v of o.values ?? []) {
        const vKey = key(v);
        if (!vKey) continue;
        const entry = group.values.get(vKey) ?? { value: vKey, label: valueLabel(v), ids: [] };
        if (!entry.ids.includes(p.id)) entry.ids.push(p.id);
        group.values.set(vKey, entry);
        group.products.add(p.id);
      }
      groups.set(gKey, group);
    }
  }
  return [...groups.entries()]
    // un gruppo ha senso solo se almeno due pezzi hanno quell'opzione
    .filter(([, g]) => g.products.size >= 2)
    .map(([k, g]) => ({ key: k, label: g.label, options: [...g.values.values()].sort(compareValues) }))
    .sort((a, b) => (a.key === "opt:taglia" ? -1 : b.key === "opt:taglia" ? 1 : a.label.localeCompare(b.label, "it")));
}

// ------------------------------------------------------------------ prezzo

/** Passo del cursore: fine con prezzi bassi, più largo con prezzi alti. */
function stepFor(max: number): number {
  return max <= 100 ? 1 : max <= 300 ? 5 : 10;
}

function priceRange(items: Product[]): PriceRange | null {
  const prices = items.map((p) => p.price).filter((p): p is number => p != null && p >= 0);
  if (new Set(prices).size < 2) return null; // un solo prezzo: non c'è niente da scegliere
  const rawMax = Math.min(PRICE_CEILING, Math.max(...prices));
  const step = stepFor(rawMax);
  const max = Math.min(PRICE_CEILING, Math.ceil(rawMax / step) * step);
  const min = Math.floor(Math.min(...prices) / step) * step;
  return { min, max, step };
}

// ------------------------------------------------------------------ insieme

/** Un gruppo a scelte serve solo se divide davvero i pezzi. */
function useful(options: FacetOption[], total: number): boolean {
  return options.length >= 2 || (options.length === 1 && options[0].ids.length < total);
}

export function buildFilters(items: Product[], categories: FacetOption[]): Filters {
  const facets: Facet[] = [
    { key: "category", label: "Categoria", options: categories },
    { key: "color", label: "Colore", options: colorOptions(items) },
    ...optionFacets(items),
  ].filter((f) => useful(f.options, items.length));
  return { facets, price: priceRange(items) };
}

/** Il prezzo scelto vale solo se è sotto il massimo del cursore. */
export function activeMaxPrice(filters: Filters, selection: Selection): number | null {
  const m = selection.maxPrice;
  return filters.price && m != null && m < filters.price.max ? m : null;
}

/** Pezzi che passano i filtri scelti, ignorando eventualmente un gruppo (per i conteggi). */
export function matchingIds(items: Product[], filters: Filters, selection: Selection, skip?: string): Set<string> {
  // Con un prezzo massimo scelto, i pezzi "su richiesta" non si possono confrontare: restano fuori
  const maxPrice = activeMaxPrice(filters, selection);
  let ids = new Set(
    items.filter((p) => maxPrice == null || (p.price != null && p.price <= maxPrice)).map((p) => p.id),
  );
  for (const f of filters.facets) {
    const chosen = selection.choices?.[f.key];
    if (f.key === skip || !chosen?.length) continue;
    const allowed = new Set(f.options.filter((o) => chosen.includes(o.value)).flatMap((o) => o.ids));
    ids = new Set([...ids].filter((id) => allowed.has(id)));
  }
  return ids;
}

/** Quanti pezzi hanno questa scelta, tenendo conto degli ALTRI filtri già scelti. */
export function optionCount(
  items: Product[],
  filters: Filters,
  selection: Selection,
  facet: Facet,
  option: FacetOption,
): number {
  const base = matchingIds(items, filters, selection, facet.key);
  return option.ids.filter((id) => base.has(id)).length;
}

export function selectedCount(filters: Filters, selection: Selection): number {
  const choices = Object.values(selection.choices ?? {}).reduce((n, v) => n + v.length, 0);
  return choices + (activeMaxPrice(filters, selection) != null ? 1 : 0);
}

/** Scelte di un gruppo, aggiornate (aggiunge o toglie un valore). */
export function toggleChoice(selection: Selection, facetKey: string, value: string): Selection {
  const current = selection.choices?.[facetKey] ?? [];
  const next = current.includes(value) ? current.filter((v) => v !== value) : [...current, value];
  return { ...selection, choices: { ...selection.choices, [facetKey]: next } };
}

export function priceLabel(value: number): string {
  return `Fino a ${value.toLocaleString("it-IT")} €`;
}

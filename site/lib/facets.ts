import { colorFor, isColorOption } from "./colors";
import type { Product } from "./types";

// Filtri della pagina di una categoria: categoria e colore (scelte da spuntare) e prezzo
// (cursore "fino a quanto spendere"). Dentro un filtro le scelte si sommano (Borse O Cappelli);
// tra filtri diversi devono valere tutte (Borse E rosso E fino a 30 €).

export interface FacetOption {
  value: string;
  label: string;
  /** Pezzi che rientrano in questa scelta */
  ids: string[];
  /** Solo per i colori: sfondo del pallino */
  swatch?: string | null;
}

export interface Facet {
  key: "category" | "color";
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
  category?: string[];
  color?: string[];
  /** Prezzo massimo scelto; assente = qualsiasi prezzo */
  maxPrice?: number;
}

export interface Filters {
  facets: Facet[];
  price: PriceRange | null;
}

/** Il cursore arriva al massimo a 999 €, come sul resto del sito. */
export const PRICE_CEILING = 999;

const key = (s: string) =>
  s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim().replace(/\s+/g, " ");
const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

/** I colori arrivano dall'opzione "Colore" dei pezzi (la stessa che vede il cliente). */
function colorOptions(items: Product[]): FacetOption[] {
  const byKey = new Map<string, FacetOption>();
  for (const p of items) {
    const seen = new Set<string>();
    for (const o of p.options ?? []) {
      if (!isColorOption(o.name)) continue;
      for (const v of o.values ?? []) {
        const k = key(v);
        if (!k || seen.has(k)) continue;
        seen.add(k);
        const entry = byKey.get(k) ?? { value: k, label: capitalize(v.trim()), ids: [], swatch: colorFor(v) };
        entry.ids.push(p.id);
        byKey.set(k, entry);
      }
    }
  }
  return [...byKey.values()].sort((a, b) => b.ids.length - a.ids.length || a.label.localeCompare(b.label, "it"));
}

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

/** Un filtro a scelte serve solo se divide davvero i pezzi. */
function useful(options: FacetOption[], total: number): boolean {
  return options.length >= 2 || (options.length === 1 && options[0].ids.length < total);
}

export function buildFilters(items: Product[], categories: FacetOption[]): Filters {
  const facets: Facet[] = [
    { key: "category" as const, label: "Categoria", options: categories },
    { key: "color" as const, label: "Colore", options: colorOptions(items) },
  ].filter((f) => useful(f.options, items.length));
  return { facets, price: priceRange(items) };
}

/** Il prezzo scelto vale solo se è sotto il massimo del cursore. */
export function activeMaxPrice(filters: Filters, selection: Selection): number | null {
  const m = selection.maxPrice;
  return filters.price && m != null && m < filters.price.max ? m : null;
}

/** Pezzi che passano i filtri scelti, ignorando eventualmente un filtro (per i conteggi). */
export function matchingIds(
  items: Product[],
  filters: Filters,
  selection: Selection,
  skip?: Facet["key"],
): Set<string> {
  // Con un prezzo massimo scelto, i pezzi "su richiesta" non si possono confrontare: restano fuori
  const maxPrice = activeMaxPrice(filters, selection);
  let ids = new Set(
    items.filter((p) => maxPrice == null || (p.price != null && p.price <= maxPrice)).map((p) => p.id),
  );
  for (const f of filters.facets) {
    const chosen = selection[f.key];
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
  return (
    (selection.category?.length ?? 0) +
    (selection.color?.length ?? 0) +
    (activeMaxPrice(filters, selection) != null ? 1 : 0)
  );
}

export function priceLabel(value: number): string {
  return `Fino a ${value.toLocaleString("it-IT")} €`;
}

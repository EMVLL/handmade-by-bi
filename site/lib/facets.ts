import { colorFor, isColorOption } from "./colors";
import type { Product } from "./types";

// Filtri della pagina di una categoria (categoria, colore, prezzo), calcolati dai pezzi.
// Dentro un filtro le scelte si sommano (Borse O Cappelli); tra filtri diversi devono
// valere tutte (Borse E rosso E fino a 20 €).

export interface FacetOption {
  value: string;
  label: string;
  /** Pezzi che rientrano in questa scelta */
  ids: string[];
  /** Solo per i colori: sfondo del pallino */
  swatch?: string | null;
}

export interface Facet {
  key: "category" | "color" | "price";
  label: string;
  options: FacetOption[];
}

export type Selection = Partial<Record<Facet["key"], string[]>>;

const PRICE_BANDS: { value: string; label: string; test: (p: number | null) => boolean }[] = [
  { value: "fino-20", label: "Fino a 20 €", test: (p) => p != null && p <= 20 },
  { value: "20-40", label: "20 – 40 €", test: (p) => p != null && p > 20 && p <= 40 },
  { value: "oltre-40", label: "Oltre 40 €", test: (p) => p != null && p > 40 },
  { value: "su-richiesta", label: "Su richiesta", test: (p) => p == null },
];

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

function priceOptions(items: Product[]): FacetOption[] {
  return PRICE_BANDS.map((b) => ({
    value: b.value,
    label: b.label,
    ids: items.filter((p) => b.test(p.price)).map((p) => p.id),
  })).filter((o) => o.ids.length);
}

/** Un filtro serve solo se divide davvero i pezzi. */
function useful(options: FacetOption[], total: number): boolean {
  return options.length >= 2 || (options.length === 1 && options[0].ids.length < total);
}

export function buildFacets(items: Product[], categories: FacetOption[]): Facet[] {
  const all: Facet[] = [
    { key: "category", label: "Categoria", options: categories },
    { key: "color", label: "Colore", options: colorOptions(items) },
    { key: "price", label: "Prezzo", options: priceOptions(items) },
  ];
  return all.filter((f) => useful(f.options, items.length));
}

/** Pezzi che passano i filtri scelti, ignorando eventualmente un filtro (per i conteggi). */
export function matchingIds(items: Product[], facets: Facet[], selection: Selection, skip?: Facet["key"]): Set<string> {
  let ids = new Set(items.map((p) => p.id));
  for (const f of facets) {
    const chosen = selection[f.key];
    if (f.key === skip || !chosen?.length) continue;
    const allowed = new Set(f.options.filter((o) => chosen.includes(o.value)).flatMap((o) => o.ids));
    ids = new Set([...ids].filter((id) => allowed.has(id)));
  }
  return ids;
}

/** Quanti pezzi hanno questa scelta, tenendo conto degli ALTRI filtri già scelti. */
export function optionCount(items: Product[], facets: Facet[], selection: Selection, facet: Facet, option: FacetOption): number {
  const base = matchingIds(items, facets, selection, facet.key);
  return option.ids.filter((id) => base.has(id)).length;
}

export function selectedCount(selection: Selection): number {
  return Object.values(selection).reduce((n, v) => n + (v?.length ?? 0), 0);
}

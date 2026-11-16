"use client";

import { useMemo, useState } from "react";
import FilterMenu from "./FilterMenu";
import ProductCard from "./ProductCard";
import SortMenu from "./SortMenu";
import { buildFacets, matchingIds, type FacetOption, type Selection } from "@/lib/facets";
import type { BadgeSettings, Product } from "@/lib/types";

/** Una categoria con cui filtrare: i pezzi che ne fanno parte. */
export type BrowserFilter = FacetOption;

type Sort = "default" | "newest" | "price_asc" | "price_desc";

const SORTS: { value: Sort; label: string }[] = [
  { value: "default", label: "In evidenza" },
  { value: "newest", label: "Più recenti" },
  { value: "price_asc", label: "Prezzo: dal più basso" },
  { value: "price_desc", label: "Prezzo: dal più alto" },
];

/**
 * Griglia dei pezzi di una categoria, con "Filtra" (categoria, colore, prezzo, anche
 * insieme) e "Ordina per". Tutto avviene nel browser: la pagina non si ricarica.
 */
export default function ProductBrowser({
  items,
  filters = [],
  badges,
}: {
  items: Product[];
  /** Categorie con cui filtrare (le altre categorie dei pezzi di questa pagina) */
  filters?: BrowserFilter[];
  badges?: BadgeSettings;
}) {
  const [selection, setSelection] = useState<Selection>({});
  const [sort, setSort] = useState<Sort>("default");

  const facets = useMemo(() => buildFacets(items, filters), [items, filters]);

  const shown = useMemo(() => {
    const ids = matchingIds(items, facets, selection);
    const list = items.filter((p) => ids.has(p.id));
    // I pezzi "prezzo su richiesta" vanno in fondo quando si ordina per prezzo
    const price = (p: Product, fallback: number) => p.price ?? fallback;
    switch (sort) {
      case "newest":
        return list.sort((a, b) => b.created_at.localeCompare(a.created_at));
      case "price_asc":
        return list.sort((a, b) => price(a, Infinity) - price(b, Infinity));
      case "price_desc":
        return list.sort((a, b) => price(b, -Infinity) - price(a, -Infinity));
      default:
        return list;
    }
  }, [items, facets, selection, sort]);

  // Le scelte attive, da togliere una per una sotto i pulsanti
  const chips = facets.flatMap((f) =>
    f.options
      .filter((o) => selection[f.key]?.includes(o.value))
      .map((o) => ({ facet: f.key, value: o.value, label: o.label })),
  );
  const remove = (facet: keyof Selection, value: string) =>
    setSelection((s) => ({ ...s, [facet]: (s[facet] ?? []).filter((v) => v !== value) }));

  const showFilters = facets.length > 0;
  const showSort = items.length > 1;

  return (
    <>
      {(showFilters || showSort) && (
        <div className="mb-6 space-y-3">
          <div className="relative flex flex-wrap items-center justify-between gap-3">
            {showFilters ? (
              <FilterMenu
                items={items}
                facets={facets}
                selection={selection}
                onChange={setSelection}
                resultCount={shown.length}
              />
            ) : (
              <div />
            )}
            {showSort && <SortMenu label="Ordina per" options={SORTS} value={sort} onChange={setSort} />}
          </div>
          {chips.length > 0 && (
            <div className="flex flex-wrap items-center gap-2">
              {chips.map((c) => (
                <button
                  key={`${c.facet}-${c.value}`}
                  type="button"
                  onClick={() => remove(c.facet, c.value)}
                  aria-label={`Togli il filtro ${c.label}`}
                  className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 py-1.5 pl-3.5 pr-2.5 text-sm text-primary transition hover:bg-primary/20"
                >
                  {c.label}
                  <svg aria-hidden viewBox="0 0 20 20" className="h-4 w-4">
                    <path d="M6 6l8 8M14 6l-8 8" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                  </svg>
                </button>
              ))}
              {chips.length > 1 && (
                <button
                  type="button"
                  onClick={() => setSelection({})}
                  className="px-1 text-sm font-semibold text-primary underline-offset-4 hover:underline"
                >
                  Azzera tutto
                </button>
              )}
            </div>
          )}
        </div>
      )}
      {shown.length ? (
        <div className="grid grid-cols-2 gap-x-4 gap-y-8 md:grid-cols-3">
          {shown.map((p) => (
            <ProductCard key={p.id} product={p} showPrice badges={badges} />
          ))}
        </div>
      ) : (
        <div className="space-y-4 py-6">
          <p className="opacity-70">Nessun lavoro con questi filtri.</p>
          <button
            type="button"
            onClick={() => setSelection({})}
            className="rounded-site border border-primary px-5 py-2.5 text-sm font-semibold text-primary"
          >
            Togli i filtri
          </button>
        </div>
      )}
    </>
  );
}

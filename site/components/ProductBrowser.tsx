"use client";

import { useMemo, useState } from "react";
import ProductCard from "./ProductCard";
import SortMenu from "./SortMenu";
import type { BadgeSettings, Product } from "@/lib/types";

export interface BrowserFilter {
  value: string;
  label: string;
  /** Pezzi che rientrano nel filtro */
  ids: string[];
}

type Sort = "default" | "newest" | "price_asc" | "price_desc";

const SORTS: { value: Sort; label: string }[] = [
  { value: "default", label: "In evidenza" },
  { value: "newest", label: "Più recenti" },
  { value: "price_asc", label: "Prezzo: dal più basso" },
  { value: "price_desc", label: "Prezzo: dal più alto" },
];

/**
 * Griglia dei pezzi di una categoria, con "Ordina per" e, se servono, i filtri.
 * Tutto avviene nel browser: la pagina resta veloce e non si ricarica.
 */
export default function ProductBrowser({
  items,
  filters = [],
  badges,
}: {
  items: Product[];
  filters?: BrowserFilter[];
  badges?: BadgeSettings;
}) {
  const [filter, setFilter] = useState<string | null>(null);
  const [sort, setSort] = useState<Sort>("default");

  const shown = useMemo(() => {
    const ids = filter ? new Set(filters.find((f) => f.value === filter)?.ids ?? []) : null;
    const list = ids ? items.filter((p) => ids.has(p.id)) : [...items];
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
  }, [items, filters, filter, sort]);

  // Filtri solo se dividono davvero i pezzi in più gruppi
  const showFilters = filters.length > 1;
  const showSort = items.length > 1;

  const chip = (active: boolean) =>
    `rounded-full border px-4 py-2 text-sm transition ${
      active ? "border-primary bg-primary text-white" : "border-foreground/20 hover:border-primary"
    }`;

  return (
    <>
      {(showFilters || showSort) && (
        <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          {showFilters ? (
            <div className="min-w-0">
              <p className="mb-2 text-sm font-semibold opacity-70">Filtra</p>
              <div className="-mx-5 flex gap-2 overflow-x-auto px-5 pb-1 sm:mx-0 sm:flex-wrap sm:overflow-visible sm:px-0">
                <button type="button" className={`shrink-0 ${chip(filter === null)}`} onClick={() => setFilter(null)}>
                  Tutti
                </button>
                {filters.map((f) => (
                  <button
                    key={f.value}
                    type="button"
                    className={`shrink-0 ${chip(filter === f.value)}`}
                    aria-pressed={filter === f.value}
                    onClick={() => setFilter(filter === f.value ? null : f.value)}
                  >
                    {f.label}
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div />
          )}
          {showSort && <SortMenu label="Ordina per" options={SORTS} value={sort} onChange={setSort} />}
        </div>
      )}
      {shown.length ? (
        <div className="grid grid-cols-2 gap-x-4 gap-y-8 md:grid-cols-3">
          {shown.map((p) => (
            <ProductCard key={p.id} product={p} showPrice badges={badges} />
          ))}
        </div>
      ) : (
        <p className="opacity-70">Nessun lavoro con questo filtro.</p>
      )}
    </>
  );
}

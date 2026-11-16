"use client";

import { useEffect, useId, useRef, useState, type CSSProperties } from "react";
import {
  activeMaxPrice,
  optionCount,
  priceLabel,
  selectedCount,
  toggleChoice,
  type Facet,
  type Filters,
  type Selection,
} from "@/lib/facets";
import type { Product } from "@/lib/types";

/**
 * Menu "Filtra" accanto a "Ordina per": categoria, colore e le altre opzioni dei pezzi
 * (Taglia, Materiale…) da spuntare, prezzo con un cursore "fino a quanto spendere"; anche insieme.
 * Le scelte si applicano subito; "Mostra N lavori" chiude il pannello.
 */
export default function FilterMenu({
  items,
  filters,
  selection,
  onChange,
  resultCount,
}: {
  items: Product[];
  filters: Filters;
  selection: Selection;
  onChange: (next: Selection) => void;
  resultCount: number;
}) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const panelId = useId();
  const active = selectedCount(filters, selection);
  const { facets, price } = filters;
  const maxPrice = activeMaxPrice(filters, selection);

  useEffect(() => {
    if (!open) return;
    const onPointer = (e: PointerEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setOpen(false);
        buttonRef.current?.focus();
      }
    };
    document.addEventListener("pointerdown", onPointer);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("pointerdown", onPointer);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const toggle = (facet: Facet, value: string) => onChange(toggleChoice(selection, facet.key, value));

  return (
    <div ref={rootRef} className="static sm:relative">
      <button
        ref={buttonRef}
        type="button"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen((o) => !o)}
        className={`flex items-center gap-2 rounded-site border bg-background py-2.5 pl-3.5 pr-4 transition ${
          open || active ? "border-primary" : "border-primary/40 hover:border-primary"
        } ${open ? "ring-2 ring-primary/20" : ""} focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40`}
      >
        <svg aria-hidden viewBox="0 0 20 20" className="h-5 w-5 shrink-0 text-primary">
          <path d="M3 5h14M6 10h8M8.5 15h3" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </svg>
        <span>Filtra</span>
        {active > 0 && (
          <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1.5 text-xs font-semibold text-white">
            {active}
          </span>
        )}
      </button>

      <div
        id={panelId}
        role="dialog"
        aria-label="Filtri"
        className={`absolute left-0 right-0 top-full z-30 mt-2 origin-top overflow-hidden rounded-site border border-primary/20 bg-background shadow-xl shadow-foreground/10 transition duration-150 sm:right-auto sm:w-[26rem] ${
          open ? "visible scale-100 opacity-100" : "pointer-events-none invisible scale-95 opacity-0"
        }`}
      >
        <div className="max-h-[60vh] space-y-5 overflow-y-auto p-5">
          {facets.map((facet) => (
            <fieldset key={facet.key}>
              <legend className="mb-2.5 text-sm font-semibold text-primary">{facet.label}</legend>
              <div className="flex flex-wrap gap-2">
                {facet.options.map((option) => {
                  const on = selection.choices?.[facet.key]?.includes(option.value) ?? false;
                  const count = optionCount(items, filters, selection, facet, option);
                  const disabled = !on && count === 0;
                  return (
                    <button
                      key={option.value}
                      type="button"
                      aria-pressed={on}
                      disabled={disabled}
                      tabIndex={open ? 0 : -1}
                      onClick={() => toggle(facet, option.value)}
                      className={`inline-flex items-center gap-2 rounded-full border px-3.5 py-2 text-sm transition ${
                        on
                          ? "border-primary bg-primary text-white"
                          : disabled
                            ? "cursor-not-allowed border-foreground/10 opacity-40"
                            : "border-foreground/20 hover:border-primary"
                      }`}
                    >
                      {facet.key === "color" && option.swatch && (
                        <span
                          aria-hidden
                          className="h-4 w-4 shrink-0 rounded-full border border-black/15"
                          style={{ background: option.swatch }}
                        />
                      )}
                      {option.label}
                      <span className={on ? "opacity-80" : "opacity-50"}>{count}</span>
                    </button>
                  );
                })}
              </div>
            </fieldset>
          ))}
          {price && (
            <div>
              <div className="mb-2 flex items-baseline justify-between gap-3">
                <label htmlFor={`${panelId}-price`} className="text-sm font-semibold text-primary">
                  Prezzo
                </label>
                <span className="text-sm font-semibold" aria-hidden>
                  {maxPrice == null ? "Qualsiasi prezzo" : priceLabel(maxPrice)}
                </span>
              </div>
              <input
                id={`${panelId}-price`}
                type="range"
                min={price.min}
                max={price.max}
                step={price.step}
                value={maxPrice ?? price.max}
                tabIndex={open ? 0 : -1}
                aria-valuetext={maxPrice == null ? "Qualsiasi prezzo" : priceLabel(maxPrice)}
                onChange={(e) => {
                  const v = Number(e.target.value);
                  onChange({ ...selection, maxPrice: v >= price.max ? undefined : v });
                }}
                className="price-range h-11 w-full cursor-pointer"
                style={{ "--fill": `${(((maxPrice ?? price.max) - price.min) / (price.max - price.min)) * 100}%` } as CSSProperties}
              />
              <div className="flex justify-between text-xs opacity-60" aria-hidden>
                <span>{price.min.toLocaleString("it-IT")} €</span>
                <span>{price.max.toLocaleString("it-IT")} €</span>
              </div>
              {maxPrice != null && (
                <p className="mt-1.5 text-xs opacity-60">I pezzi con prezzo su richiesta sono nascosti.</p>
              )}
            </div>
          )}
        </div>
        <div className="flex items-center justify-between gap-3 border-t border-primary/15 px-5 py-3">
          <button
            type="button"
            tabIndex={open ? 0 : -1}
            onClick={() => onChange({})}
            disabled={!active}
            className="py-2 text-sm font-semibold text-primary underline-offset-4 hover:underline disabled:opacity-40 disabled:hover:no-underline"
          >
            Azzera
          </button>
          <button
            type="button"
            tabIndex={open ? 0 : -1}
            onClick={() => {
              setOpen(false);
              buttonRef.current?.focus({ preventScroll: true });
            }}
            className="rounded-site bg-primary px-5 py-2.5 text-sm font-semibold text-white"
          >
            {resultCount === 1 ? "Mostra 1 lavoro" : `Mostra ${resultCount} lavori`}
          </button>
        </div>
      </div>
    </div>
  );
}

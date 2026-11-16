"use client";

import { useEffect, useId, useRef, useState } from "react";

export interface SortOption<T extends string> {
  value: T;
  label: string;
}

/**
 * Menu "Ordina per" con i colori e gli angoli del sito, al posto della tendina
 * del telefono (che su Android è nera e diversa da tutto il resto).
 * Si chiude toccando fuori, con Esc o scegliendo una voce; si usa anche da tastiera.
 */
export default function SortMenu<T extends string>({
  label,
  options,
  value,
  onChange,
}: {
  label: string;
  options: SortOption<T>[];
  value: T;
  onChange: (value: T) => void;
}) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const optionRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const id = useId();
  const current = options.find((o) => o.value === value) ?? options[0];

  // Chiusura toccando fuori o con Esc
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
    // Il fuoco va sulla voce scelta, così con le frecce si parte da lì
    const i = Math.max(0, options.findIndex((o) => o.value === value));
    optionRefs.current[i]?.focus({ preventScroll: true });
    return () => {
      document.removeEventListener("pointerdown", onPointer);
      document.removeEventListener("keydown", onKey);
    };
  }, [open, options, value]);

  const choose = (v: T) => {
    onChange(v);
    setOpen(false);
    buttonRef.current?.focus({ preventScroll: true });
  };

  const onListKey = (e: React.KeyboardEvent) => {
    const i = optionRefs.current.findIndex((el) => el === document.activeElement);
    const target: Record<string, number> = { ArrowDown: i + 1, ArrowUp: i - 1, Home: 0, End: options.length - 1 };
    if (e.key in target) {
      e.preventDefault();
      optionRefs.current[(target[e.key] + options.length) % options.length]?.focus();
    } else if (e.key === "Tab") setOpen(false);
  };

  return (
    <div ref={rootRef} className="relative flex min-w-0 items-center gap-3">
      <span id={`${id}-label`} className="hidden shrink-0 text-sm font-semibold opacity-70 sm:inline">
        {label}
      </span>
      <button
        ref={buttonRef}
        type="button"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-labelledby={`${id}-label ${id}-value`}
        onClick={() => setOpen((o) => !o)}
        onKeyDown={(e) => {
          if (e.key === "ArrowDown" || e.key === "ArrowUp") {
            e.preventDefault();
            setOpen(true);
          }
        }}
        className={`flex min-w-0 items-center gap-3 rounded-site border bg-background py-2.5 pl-4 pr-3 text-left transition ${
          open ? "border-primary ring-2 ring-primary/20" : "border-primary/40 hover:border-primary"
        } focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40`}
      >
        {/* Il testo si accorcia con "…", la freccia resta sempre visibile */}
        <span id={`${id}-value`} className="min-w-0 truncate">
          {current.label}
        </span>
        <svg
          aria-hidden
          viewBox="0 0 20 20"
          className={`h-5 w-5 shrink-0 text-primary transition-transform duration-200 ${open ? "rotate-180" : ""}`}
        >
          <path d="M5 7.5l5 5 5-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>

      <div
        role="listbox"
        aria-labelledby={`${id}-label`}
        onKeyDown={onListKey}
        className={`absolute right-0 top-full z-30 mt-2 min-w-full origin-top-right overflow-hidden rounded-site border border-primary/20 bg-background py-1.5 shadow-xl shadow-foreground/10 transition duration-150 ${
          open ? "visible scale-100 opacity-100" : "pointer-events-none invisible scale-95 opacity-0"
        }`}
      >
        {options.map((o, i) => {
          const selected = o.value === value;
          return (
            <button
              key={o.value}
              ref={(el) => {
                optionRefs.current[i] = el;
              }}
              type="button"
              role="option"
              aria-selected={selected}
              tabIndex={open ? 0 : -1}
              onClick={() => choose(o.value)}
              className={`flex w-full items-center justify-between gap-6 whitespace-nowrap px-4 py-3 text-left transition-colors focus-visible:bg-primary/10 focus-visible:outline-none ${
                selected ? "font-semibold text-primary" : "hover:bg-primary/10"
              }`}
            >
              {o.label}
              <svg
                aria-hidden
                viewBox="0 0 20 20"
                className={`h-5 w-5 shrink-0 text-primary ${selected ? "" : "invisible"}`}
              >
                <path d="M4.5 10.5l3.5 3.5 7.5-8" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          );
        })}
      </div>
    </div>
  );
}

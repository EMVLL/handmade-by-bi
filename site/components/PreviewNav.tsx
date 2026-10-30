"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef } from "react";

// Cronologia interna dell'anteprima: non usa quella del browser, così
// "Indietro" non può mai far uscire dall'anteprima o dall'app che la contiene.
const visited: string[] = [];

// Barra dell'anteprima con "Indietro" e "Inizio".
// I link interni restano in anteprima (/anteprima/...), quelli esterni
// (WhatsApp, Instagram, Vinted…) non si aprono.
export default function PreviewNav({ token }: { token: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const home = `/anteprima?t=${encodeURIComponent(token)}`;
  const atHome = pathname === "/anteprima";
  const bar = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Next tiene nascoste le pagine già visitate: ci si aggancia solo alla propria.
    const root = bar.current?.closest(".preview-root");
    if (!root) return;

    const onClick = (event: Event) => {
      const link = (event.target as Element | null)?.closest?.("a");
      if (!link || !root.contains(link)) return;
      event.preventDefault();
      event.stopPropagation();

      const href = link.getAttribute("href") ?? "";
      if (!href.startsWith("/") || href.startsWith("//")) return;
      const [path, hash] = href.split("#");
      const target = `/anteprima${path === "/" ? "" : path}?t=${encodeURIComponent(token)}${hash ? `#${hash}` : ""}`;
      visited.push(window.location.pathname + window.location.search);
      router.replace(target);
    };

    root.addEventListener("click", onClick, true);
    return () => root.removeEventListener("click", onClick, true);
  }, [router, token]);

  const back = () => router.replace(visited.pop() ?? home);
  const goHome = () => {
    visited.length = 0;
    router.replace(home);
  };

  const button = "rounded-full px-3 py-1 font-semibold transition hover:bg-background/15";
  return (
    <div ref={bar} className="sticky top-0 z-50 flex items-center gap-2 bg-foreground px-3 py-2 text-sm text-background">
      <div className="w-28 shrink-0">
        {!atHome && (
          <button type="button" onClick={back} className={button}>
            ← Indietro
          </button>
        )}
      </div>
      <p className="flex-1 text-center font-semibold">Anteprima · non ancora online</p>
      <div className="w-28 shrink-0 text-right">
        {!atHome && (
          <button type="button" onClick={goHome} className={button}>
            Inizio
          </button>
        )}
      </div>
    </div>
  );
}

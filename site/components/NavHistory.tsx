"use client";

import { usePathname } from "next/navigation";
import { useEffect } from "react";

/** Quante pagine del sito sono state aperte in questa visita (senza ricaricare). */
export const navState = { pages: 0 };

// Conta i cambi di pagina: serve a "← Indietro" per sapere se c'è
// una pagina del sito a cui tornare o se il visitatore è arrivato da fuori.
export default function NavHistory() {
  const pathname = usePathname();
  useEffect(() => {
    navState.pages++;
  }, [pathname]);
  return null;
}

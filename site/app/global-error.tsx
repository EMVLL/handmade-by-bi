"use client";

import "./globals.css";
import ErrorScreen from "@/components/ErrorScreen";

// Errore nella struttura del sito (intestazione, menu): sostituisce tutta la pagina.
export default function GlobalError({ error }: { error: unknown }) {
  return (
    <html lang="it">
      <body>
        <ErrorScreen error={error} />
      </body>
    </html>
  );
}

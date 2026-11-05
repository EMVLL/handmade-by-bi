"use client";

import ErrorScreen from "@/components/ErrorScreen";

// Errore in una pagina: intestazione e piè di pagina restano, il contenuto si ricarica.
export default function PageError({ error }: { error: unknown }) {
  return <ErrorScreen error={error} />;
}

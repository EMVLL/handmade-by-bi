"use client";

import { useEffect, useState } from "react";

const CHIAVE = "hbb-ricarica-automatica";
const PAUSA_MS = 30_000;

/**
 * Pagina che non si è caricata nel browser. Di solito è un intoppo passeggero
 * (sito appena aggiornato mentre la pagina era aperta, oppure rete lenta):
 * la prima volta si ricarica da sola, come farebbe il visitatore con "Ricarica".
 * Se l'errore si ripete entro 30 secondi mostra il messaggio, così non ricarica all'infinito.
 */
export default function ErrorScreen({ error }: { error: unknown }) {
  const [mostra, setMostra] = useState(false);

  useEffect(() => {
    console.error(error);
    let ultima = 0;
    try {
      ultima = Number(sessionStorage.getItem(CHIAVE)) || 0;
      if (Date.now() - ultima > PAUSA_MS) {
        sessionStorage.setItem(CHIAVE, String(Date.now()));
        window.location.reload();
        return;
      }
    } catch {
      // senza sessionStorage niente ricarica automatica: non si saprebbe quando fermarsi
    }
    // sessionStorage esiste solo nel browser, quindi la scelta si fa qui dopo il montaggio
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setMostra(true);
  }, [error]);

  if (!mostra) return <div className="min-h-[60vh]" aria-busy="true" />;

  return (
    <div className="mx-auto max-w-xl px-5 py-24 text-center">
      <h1 className="font-heading text-4xl">La pagina non si è caricata</h1>
      <p className="mt-4 opacity-70">Capita con una connessione lenta. Riprova tra un attimo.</p>
      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <button
          type="button"
          onClick={() => window.location.reload()}
          className="rounded-site bg-primary px-6 py-3 font-semibold text-white"
        >
          Riprova
        </button>
        {/* link "normale" apposta: ricarica tutto il sito da capo invece di riusare quello in errore */}
        {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
        <a href="/" className="rounded-site border border-primary px-6 py-3 font-semibold text-primary">
          Torna alla home
        </a>
      </div>
    </div>
  );
}

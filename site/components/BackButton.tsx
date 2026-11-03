"use client";

import { useRouter } from "next/navigation";
import { useRef } from "react";
import { navState } from "./NavHistory";

// "← Indietro": torna alla pagina da cui si è arrivati.
// Se il visitatore è entrato direttamente qui (es. da un link su WhatsApp) va alla home.
// Nell'anteprima chiede alla barra dell'anteprima di tornare indietro.
export default function BackButton({ fallback = "/" }: { fallback?: string }) {
  const router = useRouter();
  const ref = useRef<HTMLButtonElement>(null);

  const goBack = () => {
    const preview = ref.current?.closest(".preview-root");
    if (preview) {
      preview.dispatchEvent(new CustomEvent("preview-back"));
      return;
    }
    if (navState.pages > 1) router.back();
    else router.push(fallback);
  };

  return (
    <button
      ref={ref}
      type="button"
      onClick={goBack}
      className="mb-6 inline-flex items-center gap-1 text-sm opacity-70 transition hover:opacity-100"
    >
      ← Indietro
    </button>
  );
}

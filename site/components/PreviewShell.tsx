import type { ReactNode } from "react";
import PreviewLinks from "@/components/PreviewLinks";
import SiteFooter from "@/components/SiteFooter";
import SiteHeader from "@/components/SiteHeader";
import { themeStyle } from "@/lib/theme";
import type { LiveSite } from "@/lib/types";

// Cornice dell'anteprima: tema, intestazione e piè di pagina presi dalla BOZZA.
export default function PreviewShell({ site, token, children }: { site: LiveSite; token: string; children: ReactNode }) {
  return (
    <div
      className="preview-root flex min-h-dvh flex-col bg-background font-body text-foreground"
      style={themeStyle(site.settings.theme)}
    >
      <div className="sticky top-0 z-50 bg-foreground px-4 py-2 text-center text-sm font-semibold text-background">
        Anteprima: queste modifiche non sono ancora online
      </div>
      <SiteHeader site={site} chrome={false} preview />
      <div className="flex-1">{children}</div>
      <SiteFooter site={site} chrome={false} />
      <PreviewLinks token={token} />
    </div>
  );
}

export function PreviewUnavailable() {
  return (
    <div className="preview-root mx-auto max-w-xl px-5 py-24 text-center">
      <h1 className="font-heading text-3xl">Anteprima non disponibile</h1>
      <p className="mt-4 opacity-70">Apri l&apos;anteprima dall&apos;app di gestione del negozio.</p>
    </div>
  );
}

export const previewFallback = <div className="preview-root min-h-[60vh]" />;

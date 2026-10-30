import type { Metadata } from "next";
import { Suspense } from "react";
import BlockList from "@/components/BlockList";
import SiteFooter from "@/components/SiteFooter";
import SiteHeader from "@/components/SiteHeader";
import { supabase } from "@/lib/supabase";
import { themeStyle } from "@/lib/theme";
import type { LiveSite } from "@/lib/types";

// Pagina privata: mostra la BOZZA della home, prima della pubblicazione.
// Si apre dall'app con la chiave dell'anteprima; senza chiave non mostra nulla.
export const metadata: Metadata = {
  title: "Anteprima",
  robots: { index: false, follow: false },
};

type Props = { searchParams: Promise<{ t?: string | string[] }> };

async function Preview({ searchParams }: Props) {
  const { t } = await searchParams;
  const token = typeof t === "string" ? t : "";
  const { data, error } = token
    ? await supabase.rpc("get_draft_site", { p_token: token })
    : { data: null, error: null };
  const site = (data as LiveSite | null) ?? null;

  if (error || !site) {
    return (
      <div className="preview-root mx-auto max-w-xl px-5 py-24 text-center">
        <h1 className="font-heading text-3xl">Anteprima non disponibile</h1>
        <p className="mt-4 opacity-70">Apri l&apos;anteprima dall&apos;app di gestione del negozio.</p>
      </div>
    );
  }

  const home = site.pages.find((p) => p.is_home);
  return (
    <div className="preview-root flex min-h-dvh flex-col bg-background font-body text-foreground" style={themeStyle(site.settings.theme)}>
      <div className="sticky top-0 z-50 bg-foreground px-4 py-2 text-center text-sm font-semibold text-background">
        Anteprima: queste modifiche non sono ancora online
      </div>
      <SiteHeader site={site} chrome={false} />
      <div className="flex-1">{home ? <BlockList blocks={home.blocks} site={site} /> : null}</div>
      <SiteFooter site={site} chrome={false} />
    </div>
  );
}

export default function PreviewPage(props: Props) {
  return (
    <Suspense fallback={<div className="preview-root min-h-[60vh]" />}>
      <Preview searchParams={props.searchParams} />
    </Suspense>
  );
}

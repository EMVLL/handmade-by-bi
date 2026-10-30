import { Suspense } from "react";
import BlockList from "@/components/BlockList";
import PreviewShell, { PreviewUnavailable, previewFallback } from "@/components/PreviewShell";
import { loadDraft, type PreviewSearch } from "@/lib/preview";

type Props = { searchParams: PreviewSearch };

// Pagina iniziale in BOZZA, prima della pubblicazione.
async function Content({ searchParams }: Props) {
  const draft = await loadDraft(searchParams);
  if (!draft) return <PreviewUnavailable />;
  const home = draft.site.pages.find((p) => p.is_home);
  return (
    <PreviewShell site={draft.site} token={draft.token}>
      {home ? <BlockList blocks={home.blocks} site={draft.site} /> : null}
    </PreviewShell>
  );
}

export default function PreviewHome(props: Props) {
  return (
    <Suspense fallback={previewFallback}>
      <Content {...props} />
    </Suspense>
  );
}

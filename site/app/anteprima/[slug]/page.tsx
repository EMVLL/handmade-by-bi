import { notFound } from "next/navigation";
import { Suspense } from "react";
import BlockList from "@/components/BlockList";
import PreviewShell, { PreviewUnavailable, previewFallback } from "@/components/PreviewShell";
import { loadDraft, type PreviewSearch } from "@/lib/preview";

type Props = { params: Promise<{ slug: string }>; searchParams: PreviewSearch };

// Pagine extra in BOZZA (es. "Chi sono").
async function Content({ params, searchParams }: Props) {
  const [draft, { slug }] = await Promise.all([loadDraft(searchParams), params]);
  if (!draft) return <PreviewUnavailable />;
  const page = draft.site.pages.find((p) => p.slug === slug && !p.is_home);
  if (!page) notFound();
  return (
    <PreviewShell site={draft.site} token={draft.token}>
      <BlockList blocks={page.blocks} site={draft.site} />
    </PreviewShell>
  );
}

export default function PreviewPage(props: Props) {
  return (
    <Suspense fallback={previewFallback}>
      <Content {...props} />
    </Suspense>
  );
}

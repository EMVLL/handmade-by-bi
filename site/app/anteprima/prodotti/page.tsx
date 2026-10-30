import { Suspense } from "react";
import PreviewShell, { PreviewUnavailable, previewFallback } from "@/components/PreviewShell";
import ProductsView from "@/components/views/ProductsView";
import { loadDraft, type PreviewSearch } from "@/lib/preview";

type Props = { searchParams: PreviewSearch };

async function Content({ searchParams }: Props) {
  const draft = await loadDraft(searchParams);
  if (!draft) return <PreviewUnavailable />;
  return (
    <PreviewShell site={draft.site} token={draft.token}>
      <ProductsView site={draft.site} />
    </PreviewShell>
  );
}

export default function PreviewProducts(props: Props) {
  return (
    <Suspense fallback={previewFallback}>
      <Content {...props} />
    </Suspense>
  );
}

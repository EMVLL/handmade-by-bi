import { Suspense } from "react";
import PreviewShell, { PreviewUnavailable, previewFallback } from "@/components/PreviewShell";
import CategoryView from "@/components/views/CategoryView";
import { loadDraft, type PreviewSearch } from "@/lib/preview";

type Props = { params: Promise<{ slug: string }>; searchParams: PreviewSearch };

async function Content({ params, searchParams }: Props) {
  const [draft, { slug }] = await Promise.all([loadDraft(searchParams), params]);
  if (!draft) return <PreviewUnavailable />;
  return (
    <PreviewShell site={draft.site} token={draft.token}>
      <div className="mx-auto max-w-5xl px-5 py-10">
        <CategoryView slug={slug} site={draft.site} />
      </div>
    </PreviewShell>
  );
}

export default function PreviewCategory(props: Props) {
  return (
    <Suspense fallback={previewFallback}>
      <Content {...props} />
    </Suspense>
  );
}

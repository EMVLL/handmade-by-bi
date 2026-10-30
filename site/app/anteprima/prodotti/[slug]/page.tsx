import Link from "next/link";
import { Suspense } from "react";
import PreviewShell, { PreviewUnavailable, previewFallback } from "@/components/PreviewShell";
import ProductView from "@/components/views/ProductView";
import { loadDraft, type PreviewSearch } from "@/lib/preview";

type Props = { params: Promise<{ slug: string }>; searchParams: PreviewSearch };

async function Content({ params, searchParams }: Props) {
  const [draft, { slug }] = await Promise.all([loadDraft(searchParams), params]);
  if (!draft) return <PreviewUnavailable />;
  return (
    <PreviewShell site={draft.site} token={draft.token}>
      <div className="mx-auto max-w-5xl px-5 py-10">
        <Link href="/prodotti" className="mb-6 inline-block text-sm opacity-70 hover:opacity-100">
          ← Tutti i lavori
        </Link>
        <ProductView slug={slug} site={draft.site} preview />
      </div>
    </PreviewShell>
  );
}

export default function PreviewProduct(props: Props) {
  return (
    <Suspense fallback={previewFallback}>
      <Content {...props} />
    </Suspense>
  );
}

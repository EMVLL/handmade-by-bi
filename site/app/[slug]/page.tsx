import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { Suspense } from "react";
import BlockList from "@/components/BlockList";
import { getLiveSite } from "@/lib/data";

type Params = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const site = await getLiveSite();
  const slugs = (site?.pages ?? []).filter((p) => !p.is_home).map((p) => ({ slug: p.slug }));
  // Con Cache Components serve almeno un valore: se non ci sono pagine, un segnaposto che dà 404.
  return slugs.length ? slugs : [{ slug: "pagina-segnaposto" }];
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const site = await getLiveSite();
  const page = site?.pages.find((p) => p.slug === slug);
  if (!page) return { title: "Pagina non trovata", robots: { index: false } };
  return {
    title: page.seo?.title || page.title,
    description: page.seo?.description || undefined,
  };
}

async function PageContent({ params }: Params) {
  const { slug } = await params;
  const site = await getLiveSite();
  const page = site?.pages.find((p) => p.slug === slug);
  if (!site || !page) notFound();
  if (page.is_home) redirect("/");
  return <BlockList blocks={page.blocks} site={site} />;
}

export default function Page(props: Params) {
  return (
    <Suspense fallback={<div className="min-h-[60vh]" />}>
      <PageContent params={props.params} />
    </Suspense>
  );
}

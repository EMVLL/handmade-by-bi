import type { Metadata } from "next";
import { Suspense } from "react";
import CategoryView from "@/components/views/CategoryView";
import { OTHER_SLUG, READY_SLUG, categoryInfo, siteMenuSettings } from "@/lib/categories";
import { getCollections, getLiveSite, getProducts } from "@/lib/data";

type Params = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const collections = await getCollections();
  return [...collections.map((c) => ({ slug: c.slug })), { slug: READY_SLUG }, { slug: OTHER_SLUG }];
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const [site, products, collections] = await Promise.all([getLiveSite(), getProducts(), getCollections()]);
  const info = categoryInfo(slug, siteMenuSettings(site), products, collections);
  if (!info) return { title: "Categoria non trovata", robots: { index: false } };
  return {
    title: info.name,
    description: info.description.replace(/\s+/g, " ").slice(0, 160) || undefined,
    openGraph: info.cover ? { images: [{ url: info.cover }] } : undefined,
  };
}

async function CategoryContent({ params }: Params) {
  const { slug } = await params;
  const site = await getLiveSite();
  return <CategoryView slug={slug} site={site} />;
}

export default function CategoryPage(props: Params) {
  return (
    <div className="mx-auto max-w-5xl px-5 py-10">
      <Suspense fallback={<div className="min-h-[60vh]" />}>
        <CategoryContent params={props.params} />
      </Suspense>
    </div>
  );
}

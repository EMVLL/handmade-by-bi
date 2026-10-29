import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import CategoryMenu from "@/components/CategoryMenu";
import ProductCard from "@/components/ProductCard";
import {
  OTHER_SLUG,
  READY_SLUG,
  categoryEntries,
  categoryName,
  productsInCategory,
  siteMenuSettings,
} from "@/lib/categories";
import { getCollections, getLiveSite, getProducts } from "@/lib/data";

type Params = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const collections = await getCollections();
  return [...collections.map((c) => ({ slug: c.slug })), { slug: READY_SLUG }, { slug: OTHER_SLUG }];
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const [site, collections] = await Promise.all([getLiveSite(), getCollections()]);
  const name = categoryName(slug, siteMenuSettings(site), collections);
  if (!name) return { title: "Categoria non trovata", robots: { index: false } };
  return { title: name };
}

async function CategoryContent({ params }: Params) {
  const { slug } = await params;
  const [site, products, collections] = await Promise.all([getLiveSite(), getProducts(), getCollections()]);
  const settings = siteMenuSettings(site);
  const name = categoryName(slug, settings, collections);
  if (!name) notFound();

  const items = productsInCategory(slug, products, collections);
  const entries = categoryEntries(settings, products, collections);

  return (
    <>
      <CategoryMenu entries={entries} style="buttons" current={slug} />
      <h1 className="mb-8 mt-8 font-heading text-4xl">{name}</h1>
      {items.length ? (
        <div className="grid grid-cols-2 gap-x-4 gap-y-8 md:grid-cols-3">
          {items.map((p) => (
            <ProductCard key={p.id} product={p} showPrice />
          ))}
        </div>
      ) : (
        <p className="opacity-70">Nessun lavoro in questa categoria, per ora.</p>
      )}
    </>
  );
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

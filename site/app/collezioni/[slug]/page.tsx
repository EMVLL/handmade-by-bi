import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import CategoryMenu from "@/components/CategoryMenu";
import ProductCard from "@/components/ProductCard";
import {
  OTHER_SLUG,
  READY_SLUG,
  categoryEntries,
  categoryInfo,
  productsInCategory,
  siteMenuSettings,
} from "@/lib/categories";
import { paragraphs } from "@/lib/format";
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
  const [site, products, collections] = await Promise.all([getLiveSite(), getProducts(), getCollections()]);
  const settings = siteMenuSettings(site);
  const info = categoryInfo(slug, settings, products, collections);
  if (!info) notFound();

  const items = productsInCategory(slug, products, collections);
  const entries = categoryEntries(settings, products, collections);
  // Copertina in testata solo se Benedetta l'ha scelta per questa categoria
  const chosenCover = collections.find((c) => c.slug === slug)?.cover_path
    ? info.cover
    : slug === READY_SLUG && settings.readyCover
      ? info.cover
      : slug === OTHER_SLUG && settings.otherCover
        ? info.cover
        : null;

  return (
    <>
      <CategoryMenu entries={entries} style="buttons" current={slug} />
      {chosenCover ? (
        <div className="relative mt-8 flex aspect-[3/1] min-h-44 items-end overflow-hidden rounded-site">
          <Image src={chosenCover} alt="" fill sizes="(min-width: 1024px) 1024px, 100vw" className="object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
          <h1 className="relative p-6 font-heading text-4xl text-white md:text-5xl">{info.name}</h1>
        </div>
      ) : (
        <h1 className="mt-8 font-heading text-4xl">{info.name}</h1>
      )}
      {info.description && (
        <div className="mt-4 max-w-2xl space-y-3 text-lg opacity-80">
          {paragraphs(info.description).map((para, i) => (
            <p key={i} className="whitespace-pre-line">
              {para}
            </p>
          ))}
        </div>
      )}
      <div className="mt-8">
        {items.length ? (
          <div className="grid grid-cols-2 gap-x-4 gap-y-8 md:grid-cols-3">
            {items.map((p) => (
              <ProductCard key={p.id} product={p} showPrice />
            ))}
          </div>
        ) : (
          <p className="opacity-70">Nessun lavoro in questa categoria, per ora.</p>
        )}
      </div>
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

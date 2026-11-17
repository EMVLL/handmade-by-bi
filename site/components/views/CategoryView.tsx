import Image from "next/image";
import { notFound } from "next/navigation";
import BackButton from "@/components/BackButton";
import CategoryMenu from "@/components/CategoryMenu";
import ProductBrowser, { type BrowserFilter } from "@/components/ProductBrowser";
import {
  OTHER_SLUG,
  READY_SLUG,
  categoryEntries,
  categoryInfo,
  productsInCategory,
  siteMenuSettings,
} from "@/lib/categories";
import { getCollections, getProducts } from "@/lib/data";
import { paragraphs } from "@/lib/format";
import { kindsFor } from "@/lib/kinds";
import type { LiveSite } from "@/lib/types";

// Pagina di una categoria: usata dal sito e dall'anteprima (con il sito in bozza).
export default async function CategoryView({ slug, site }: { slug: string; site: LiveSite | null }) {
  const [products, collections] = await Promise.all([getProducts(), getCollections()]);
  const settings = siteMenuSettings(site);
  const info = categoryInfo(slug, settings, products, collections);
  if (!info) notFound();

  const items = productsInCategory(slug, products, collections);
  const entries = categoryEntries(settings, products, collections);

  // Filtro per categoria: per ogni pezzo le sue ALTRE categorie vere oppure, se non ne ha,
  // il tipo ricavato dal nome ("Clutch Marrone" -> Borse). Serve soprattutto in pagine come
  // "Disponibili" o i pezzi pronti; compare solo se divide davvero i pezzi.
  const current = collections.find((c) => c.slug === slug)?.id;
  const kinds = new Map(items.map((p) => [p.id, kindsFor(p, collections, current)]));
  const filters: BrowserFilter[] = [];
  if (slug !== OTHER_SLUG) {
    for (const c of collections) {
      if (c.id === current) continue;
      const ids = items.filter((p) => kinds.get(p.id)?.includes(c.id)).map((p) => p.id);
      if (ids.length) filters.push({ value: c.id, label: c.name, ids });
    }
    // "Altro" solo nelle pagine che raccolgono pezzi di più categorie (pronti, "Disponibili"):
    // in Borse vorrebbe dire "solo borse" e confonderebbe
    const loose = items.filter((p) => !kinds.get(p.id)?.length).map((p) => p.id);
    if (loose.length && filters.length >= 2) filters.push({ value: "__altro", label: settings.otherLabel, ids: loose });
  }
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
      <BackButton />
      <CategoryMenu entries={entries} style="buttons" current={slug} />
      {chosenCover ? (
        <div className="relative mt-8 flex h-44 w-full items-end overflow-hidden rounded-site sm:h-56 md:h-72">
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
          <ProductBrowser items={items} filters={filters} badges={site?.settings.badges} />
        ) : (
          <p className="opacity-70">Nessun lavoro in questa categoria, per ora.</p>
        )}
      </div>
    </>
  );
}

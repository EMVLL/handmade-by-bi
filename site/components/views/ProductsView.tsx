import CategoryMenu from "@/components/CategoryMenu";
import ProductCard from "@/components/ProductCard";
import { categoryEntries, siteMenuSettings } from "@/lib/categories";
import { getCollections, getProducts } from "@/lib/data";
import type { LiveSite } from "@/lib/types";

// "Tutti i lavori": usata dal sito e dall'anteprima.
export default async function ProductsView({ site }: { site: LiveSite | null }) {
  const [products, collections] = await Promise.all([getProducts(), getCollections()]);
  const entries = categoryEntries(siteMenuSettings(site), products, collections);
  return (
    <div className="mx-auto max-w-5xl px-5 py-12">
      <CategoryMenu entries={entries} style="buttons" />
      <h1 className="mb-8 mt-8 font-heading text-4xl">Tutti i lavori</h1>
      {products.length ? (
        <div className="grid grid-cols-2 gap-x-4 gap-y-8 md:grid-cols-3">
          {products.map((p) => (
            <ProductCard key={p.id} product={p} showPrice />
          ))}
        </div>
      ) : (
        <p className="opacity-70">I primi lavori arrivano presto.</p>
      )}
    </div>
  );
}

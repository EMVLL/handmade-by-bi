import type { Metadata } from "next";
import ProductCard from "@/components/ProductCard";
import { getProducts } from "@/lib/data";

export const metadata: Metadata = { title: "Tutti i lavori" };

export default async function ProductsPage() {
  const products = await getProducts();
  return (
    <div className="mx-auto max-w-5xl px-5 py-12">
      <h1 className="mb-8 font-heading text-4xl">Tutti i lavori</h1>
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

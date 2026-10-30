import { notFound } from "next/navigation";
import OrderPanel from "@/components/OrderPanel";
import { PriceLine } from "@/components/ProductCard";
import ProductGallery from "@/components/ProductGallery";
import { getProduct } from "@/lib/data";
import { mediaUrl, paragraphs, priceLabel } from "@/lib/format";
import type { LiveSite } from "@/lib/types";

// Scheda di un pezzo: usata dal sito e dall'anteprima (con il sito in bozza).
export default async function ProductView({
  slug,
  site,
  preview = false,
}: {
  slug: string;
  site: LiveSite | null;
  preview?: boolean;
}) {
  const product = await getProduct(slug);
  if (!product || !site) notFound();

  const images = product.photos.map((p) => mediaUrl(p)).filter((u): u is string => Boolean(u));

  return (
    <div className="grid gap-10 md:grid-cols-2">
      <ProductGallery images={images} alt={product.title} />
      <div>
        <h1 className="font-heading text-4xl leading-tight">{product.title}</h1>
        <PriceLine product={product} className="mt-3 text-xl" />
        {product.status === "su_ordinazione" && (
          <p className="mt-2 text-sm font-semibold text-accent">Realizzato su ordinazione</p>
        )}
        {product.status === "venduto" && <p className="mt-2 text-sm font-semibold">Venduto</p>}
        <div className="mt-6 space-y-4 leading-relaxed">
          {paragraphs(product.description).map((para, i) => (
            <p key={i} className="whitespace-pre-line">
              {para}
            </p>
          ))}
        </div>
        <div className="mt-8">
          <OrderPanel
            title={product.title}
            priceText={priceLabel(product.price)}
            status={product.status}
            options={product.options ?? []}
            vintedUrl={product.vinted_url}
            contacts={site.settings.contacts}
            preview={preview}
          />
        </div>
      </div>
    </div>
  );
}

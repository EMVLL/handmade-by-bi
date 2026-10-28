import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import OrderPanel from "@/components/OrderPanel";
import { PriceLine } from "@/components/ProductCard";
import ProductGallery from "@/components/ProductGallery";
import { getLiveSite, getProduct, getProducts } from "@/lib/data";
import { mediaUrl, paragraphs, priceLabel } from "@/lib/format";

type Params = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const products = await getProducts();
  const slugs = products.map((p) => ({ slug: p.slug }));
  // Con Cache Components serve almeno un valore: se il catalogo è vuoto, un segnaposto che dà 404.
  return slugs.length ? slugs : [{ slug: "prodotto-segnaposto" }];
}

// Titolo, descrizione e foto: è l'anteprima che compare quando il link si condivide su WhatsApp o Instagram.
export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const product = await getProduct(slug);
  if (!product) return { title: "Prodotto non trovato", robots: { index: false } };
  const image = mediaUrl(product.photos?.[0]);
  const description =
    product.description.replace(/\s+/g, " ").trim().slice(0, 160) ||
    `${product.title} · ${priceLabel(product.price)}`;
  return {
    title: product.title,
    description,
    openGraph: {
      title: product.title,
      description,
      type: "website",
      images: image ? [{ url: image, alt: product.title }] : undefined,
    },
  };
}

async function ProductDetails({ params }: Params) {
  const { slug } = await params;
  const [product, site] = await Promise.all([getProduct(slug), getLiveSite()]);
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
          />
        </div>
      </div>
    </div>
  );
}

export default function ProductPage(props: Params) {
  return (
    <div className="mx-auto max-w-5xl px-5 py-10">
      <Link href="/prodotti" className="mb-6 inline-block text-sm opacity-70 hover:opacity-100">
        ← Tutti i lavori
      </Link>
      <Suspense fallback={<div className="aspect-square max-w-md animate-pulse rounded-site bg-foreground/5" />}>
        <ProductDetails params={props.params} />
      </Suspense>
    </div>
  );
}

import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import ProductView from "@/components/views/ProductView";
import { getLiveSite, getProduct, getProducts } from "@/lib/data";
import { mediaUrl, priceLabel } from "@/lib/format";

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
  const site = await getLiveSite();
  return <ProductView slug={slug} site={site} />;
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

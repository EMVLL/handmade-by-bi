import Image from "next/image";
import Link from "next/link";
import type { BadgeSettings, Product } from "@/lib/types";
import StatusBadge from "./StatusBadge";
import { formatPrice, mediaUrl } from "@/lib/format";

export function PriceLine({ product, className = "" }: { product: Product; className?: string }) {
  const price = formatPrice(product.price);
  const compare = formatPrice(product.compare_at_price);
  return (
    <p className={className}>
      {price ? (
        <>
          <span className="font-semibold">{price}</span>
          {compare && <span className="ml-2 text-sm line-through opacity-60">{compare}</span>}
        </>
      ) : (
        <span className="opacity-70">Prezzo su richiesta</span>
      )}
    </p>
  );
}

export default function ProductCard({
  product,
  showPrice,
  badges,
}: {
  product: Product;
  showPrice: boolean;
  badges?: BadgeSettings;
}) {
  const img = mediaUrl(product.photos?.[0]);
  // Tempi di realizzazione: interruttore generale in "Etichette dei pezzi" + quello del pezzo
  const leadTime =
    badges?.lead_time_cards && product.show_lead_time ? product.lead_time?.trim() : "";
  return (
    <Link href={`/prodotti/${product.slug}`} className="group block">
      <div className="relative aspect-square overflow-hidden rounded-site bg-foreground/5">
        {img ? (
          <Image
            src={img}
            alt={product.title}
            fill
            sizes="(min-width: 768px) 33vw, 50vw"
            className={`object-cover transition duration-300 group-hover:scale-105 ${
              product.status === "venduto" ? "opacity-70" : ""
            }`}
          />
        ) : (
          <div className="flex h-full items-center justify-center text-sm opacity-50">Foto in arrivo</div>
        )}
        <StatusBadge status={product.status} settings={badges} />
      </div>
      <h3 className="mt-3 font-heading text-lg leading-snug">{product.title}</h3>
      {showPrice && <PriceLine product={product} className="mt-1" />}
      {leadTime ? <p className="mt-1 text-sm opacity-70">Realizzazione: {leadTime}</p> : null}
    </Link>
  );
}

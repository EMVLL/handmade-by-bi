import Image from "next/image";
import Link from "next/link";
import { formatPrice, mediaUrl } from "@/lib/format";
import RibbonScroller from "./RibbonScroller";
import type { Product } from "@/lib/types";

// Nastro che scorre da solo: i lavori come in una vetrina.
// Di base non si cliccano (si passa dalle categorie); con "links" toccando un lavoro si apre la sua scheda.
export default function ProductRibbon({
  products,
  showPrice,
  links = false,
}: {
  products: Product[];
  showPrice: boolean;
  links?: boolean;
}) {
  const withPhoto = products.filter((p) => p.photos?.length);
  if (!withPhoto.length) return null;

  // Ripeto i lavori finché il nastro è abbastanza lungo da riempire lo schermo,
  // poi lo raddoppio per farlo girare senza scatti.
  const half: Product[] = [];
  while (half.length < 8) half.push(...withPhoto);
  const loop = [...half, ...half];

  return (
    <RibbonScroller>
      {loop.map((p, i) => {
        const price = formatPrice(p.price);
        const copy = i >= half.length;
        const content = (
          <>
            <div className="relative aspect-square overflow-hidden rounded-site bg-foreground/5">
              <Image
                src={mediaUrl(p.photos[0])!}
                alt={copy ? "" : p.title}
                fill
                sizes="(min-width: 768px) 240px, 176px"
                draggable={false}
                className="select-none object-cover"
              />
            </div>
            <p className="mt-2 truncate font-heading">{p.title}</p>
            {showPrice && price && (
              <p className="text-sm opacity-80">{price}</p>
            )}
          </>
        );
        return links ? (
          <Link
            key={`${p.id}-${i}`}
            href={`/prodotti/${p.slug}`}
            draggable={false}
            className="block w-44 shrink-0 pr-4 md:w-60"
            aria-hidden={copy || undefined}
            tabIndex={copy ? -1 : undefined}
          >
            {content}
          </Link>
        ) : (
          <div
            key={`${p.id}-${i}`}
            className="w-44 shrink-0 pr-4 md:w-60"
            aria-hidden={copy || undefined}
          >
            {content}
          </div>
        );
      })}
    </RibbonScroller>
  );
}

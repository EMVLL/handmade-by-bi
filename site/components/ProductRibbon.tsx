import Image from "next/image";
import { formatPrice, mediaUrl } from "@/lib/format";
import type { Product } from "@/lib/types";

// Nastro che scorre da solo: i lavori come in una vetrina, non cliccabili.
// Per vedere un pezzo si passa dalle categorie.
export default function ProductRibbon({ products, showPrice }: { products: Product[]; showPrice: boolean }) {
  const withPhoto = products.filter((p) => p.photos?.length);
  if (!withPhoto.length) return null;

  // Ripeto i lavori finché il nastro è abbastanza lungo da riempire lo schermo,
  // poi lo raddoppio per farlo girare senza scatti.
  const half: Product[] = [];
  while (half.length < 8) half.push(...withPhoto);
  const loop = [...half, ...half];
  const seconds = Math.max(25, half.length * 4);

  return (
    <div className="ribbon -mx-5 overflow-hidden">
      <div className="ribbon-track flex w-max" style={{ animationDuration: `${seconds}s` }}>
        {loop.map((p, i) => {
          const price = formatPrice(p.price);
          return (
            <div key={`${p.id}-${i}`} className="w-44 shrink-0 pr-4 md:w-60" aria-hidden={i >= half.length || undefined}>
              <div className="relative aspect-square overflow-hidden rounded-site bg-foreground/5">
                <Image
                  src={mediaUrl(p.photos[0])!}
                  alt={i < half.length ? p.title : ""}
                  fill
                  sizes="(min-width: 768px) 240px, 176px"
                  draggable={false}
                  className="select-none object-cover"
                />
              </div>
              <p className="mt-2 truncate font-heading">{p.title}</p>
              {showPrice && price && <p className="text-sm opacity-80">{price}</p>}
            </div>
          );
        })}
      </div>
    </div>
  );
}

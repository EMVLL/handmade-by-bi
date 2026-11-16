import Image from "next/image";
import Link from "next/link";
import { formatPrice, mediaUrl, photoPosition } from "@/lib/format";
import RibbonScroller from "./RibbonScroller";
import type { BadgeSettings, Product } from "@/lib/types";
import StatusBadge from "./StatusBadge";

// Nastro che scorre da solo: i lavori come in una vetrina.
// Di base non si cliccano (si passa dalle categorie); con "links" toccando un lavoro si apre la sua scheda.
export default function ProductRibbon({
  products,
  showPrice,
  links = false,
  showNames = true,
  badges,
}: {
  products: Product[];
  showPrice: boolean;
  links?: boolean;
  showNames?: boolean;
  badges?: BadgeSettings;
}) {
  const withPhoto = products.filter((p) => p.photos?.length);
  if (!withPhoto.length) return null;

  // Ripeto i lavori finché un giro è più lungo dello schermo, poi metto tre giri
  // uguali in fila: si scorre sempre in quello centrale, con un giro intero di
  // margine a destra e a sinistra, così il dito non arriva mai al bordo.
  const round: Product[] = [];
  while (round.length < 8) round.push(...withPhoto);
  const loop = [...round, ...round, ...round];

  return (
    <RibbonScroller>
      {loop.map((p, i) => {
        const price = formatPrice(p.price);
        // per i lettori di schermo conta solo il giro centrale
        const copy = i < round.length || i >= round.length * 2;
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
                style={{ objectPosition: photoPosition(p.photo_focus, p.photos[0]) }}
              />
              <StatusBadge status={p.status} settings={badges} />
            </div>
            {showNames && <p className="mt-2 truncate font-heading">{p.title}</p>}
            {showPrice && price && (
              <p className={`text-sm opacity-80 ${showNames ? "" : "mt-2"}`}>{price}</p>
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

import Image from "next/image";
import Link from "next/link";
import type { CategoryEntry, MenuStyle, TileShape } from "@/lib/categories";

const COLS: Record<number, string> = {
  2: "grid-cols-2",
  3: "grid-cols-2 md:grid-cols-3",
  4: "grid-cols-2 sm:grid-cols-3 md:grid-cols-4",
};

const SHAPE: Record<TileShape, string> = {
  square: "aspect-square",
  landscape: "aspect-[4/3]",
  portrait: "aspect-[3/4]",
};

function Tile({ e, shape, className = "" }: { e: CategoryEntry; shape: TileShape; className?: string }) {
  return (
    <Link href={e.href} className={`group relative block overflow-hidden rounded-site bg-primary/15 ${SHAPE[shape]} ${className}`}>
      {e.cover && (
        <Image
          src={e.cover}
          alt=""
          fill
          sizes="(min-width: 768px) 25vw, 50vw"
          className="object-cover transition duration-300 group-hover:scale-105"
        />
      )}
      <span className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/10 to-transparent" />
      <span className="absolute inset-x-0 bottom-0 p-3 font-heading text-lg leading-tight text-white">{e.name}</span>
    </Link>
  );
}

// Menu delle categorie, in quattro forme a scelta di Benedetta.
export default function CategoryMenu({
  entries,
  style,
  columns = 4,
  shape = "landscape",
  current,
}: {
  entries: CategoryEntry[];
  style: MenuStyle;
  columns?: number;
  shape?: TileShape;
  current?: string;
}) {
  if (!entries.length) return null;

  if (style === "buttons") {
    return (
      <nav aria-label="Categorie" className="-mx-5 flex gap-2 overflow-x-auto px-5 pb-1">
        {entries.map((e) => {
          const active = e.slug === current;
          return (
            <Link
              key={e.slug}
              href={e.href}
              aria-current={active ? "page" : undefined}
              className={`shrink-0 whitespace-nowrap rounded-full border px-4 py-2 text-sm transition ${
                active ? "border-primary bg-primary text-white" : "border-foreground/20 hover:border-primary"
              }`}
            >
              {e.name}
            </Link>
          );
        })}
      </nav>
    );
  }

  if (style === "circles") {
    return (
      <nav aria-label="Categorie" className="-mx-5 flex gap-5 overflow-x-auto px-5 pb-2 md:flex-wrap md:justify-center">
        {entries.map((e) => (
          <Link key={e.slug} href={e.href} className="group flex w-24 shrink-0 flex-col items-center gap-2 text-center">
            <span className="relative block h-24 w-24 overflow-hidden rounded-full bg-primary/15 ring-2 ring-primary/30 transition group-hover:ring-primary">
              {e.cover && <Image src={e.cover} alt="" fill sizes="96px" className="object-cover" />}
            </span>
            <span className="text-sm leading-tight">{e.name}</span>
          </Link>
        ))}
      </nav>
    );
  }

  if (style === "carousel") {
    return (
      <nav aria-label="Categorie" className="-mx-5 flex snap-x snap-mandatory gap-3 overflow-x-auto px-5 pb-2">
        {entries.map((e) => (
          <Tile key={e.slug} e={e} shape={shape} className="w-2/3 shrink-0 snap-start sm:w-1/3 md:w-1/4" />
        ))}
      </nav>
    );
  }

  return (
    <nav aria-label="Categorie" className={`grid gap-3 ${COLS[columns] ?? COLS[4]}`}>
      {entries.map((e) => (
        <Tile key={e.slug} e={e} shape={shape} />
      ))}
    </nav>
  );
}

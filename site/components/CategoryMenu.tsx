import Image from "next/image";
import Link from "next/link";
import type { CategoryEntry } from "@/lib/categories";

// Menu delle categorie: riquadri con foto (homepage) o pulsanti (pagine categoria).
export default function CategoryMenu({
  entries,
  style,
  current,
}: {
  entries: CategoryEntry[];
  style: "tiles" | "buttons";
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

  return (
    <nav aria-label="Categorie" className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
      {entries.map((e) => (
        <Link key={e.slug} href={e.href} className="group relative block aspect-[4/3] overflow-hidden rounded-site bg-primary/15">
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
          <span className="absolute inset-x-0 bottom-0 p-3 font-heading text-lg leading-tight text-white">
            {e.name}
          </span>
        </Link>
      ))}
    </nav>
  );
}

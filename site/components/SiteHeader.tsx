import Image from "next/image";
import Link from "next/link";
import type { LiveSite } from "@/lib/types";
import { mediaUrl, menuHref } from "@/lib/format";
import SmartLink from "./SmartLink";

export default function SiteHeader({
  site,
  chrome = true,
  preview = false,
}: {
  site: LiveSite;
  chrome?: boolean;
  /** In anteprima il logo non è cliccabile. */
  preview?: boolean;
}) {
  const logo = mediaUrl(site.settings.logo_path);
  const items = [...site.menu]
    .sort((a, b) => a.position - b.position)
    .map((item) => ({ item, href: menuHref(site, item) }))
    .filter((x): x is { item: typeof x.item; href: string } => Boolean(x.href));

  const brand = logo ? (
    <Image src={logo} alt={site.settings.site_name} width={160} height={48} className="h-10 w-auto" />
  ) : (
    site.settings.site_name
  );

  return (
    <header className={`${chrome ? "site-chrome " : ""}border-b border-foreground/10`}>
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-5 py-4">
        {preview ? (
          <span className="flex items-center gap-3 font-heading text-xl font-semibold">{brand}</span>
        ) : (
          <Link href="/" className="flex items-center gap-3 font-heading text-xl font-semibold">
            {brand}
          </Link>
        )}
        {items.length > 1 && (
          <nav className="flex gap-5 overflow-x-auto text-sm">
            {items.map(({ item, href }) => (
              <SmartLink key={item.id} href={href} className="whitespace-nowrap hover:text-primary">
                {item.label}
              </SmartLink>
            ))}
          </nav>
        )}
      </div>
    </header>
  );
}

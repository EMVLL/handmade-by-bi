import Image from "next/image";
import Link from "next/link";
import type { CSSProperties } from "react";
import { fontFamily } from "@/lib/fonts";
import { mediaUrl, menuHref } from "@/lib/format";
import { textStyleCss } from "@/lib/textStyle";
import type { LiveSite } from "@/lib/types";
import SmartLink from "./SmartLink";

const LOGO_HEIGHT = { s: "h-8", m: "h-10", l: "h-16", xl: "h-24" } as const;
const NAME_SIZE = { s: "text-lg", m: "text-xl", l: "text-3xl" } as const;
const ROW = {
  left: "flex-row items-center justify-between",
  right: "flex-row-reverse items-center justify-between",
  center: "flex-col items-center",
} as const;

// Intestazione: logo e nome come li ha scelti Benedetta (Negozio → Nome, logo e Google).
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
  const h = site.settings.header ?? {};
  const logo = mediaUrl(site.settings.logo_path);

  const wantsLogo = h.show_logo ?? true;
  const showLogo = wantsLogo && Boolean(logo);
  // Valori di sempre: se non ha scelto, il nome compare solo quando non c'è un logo.
  // Se voleva il logo ma il logo non c'è, si mostra il nome per non lasciare il vuoto.
  const showName = (h.show_name ?? !logo) || (wantsLogo && !logo);
  const align = h.align ?? "left";
  const stack = h.arrangement === "stack";
  const nameStyle: CSSProperties = {
    ...(h.name_font && h.name_font !== "theme" ? { fontFamily: fontFamily(h.name_font, "Fraunces") } : {}),
    ...textStyleCss(h.name_style),
  };

  const items = [...site.menu]
    .sort((a, b) => a.position - b.position)
    .map((item) => ({ item, href: menuHref(site, item) }))
    .filter((x): x is { item: typeof x.item; href: string } => Boolean(x.href));
  const showMenu = items.length > 1;

  const brandContent =
    showLogo || showName ? (
      <>
        {showLogo && (
          <Image
            src={logo!}
            alt={site.settings.site_name}
            width={480}
            height={160}
            className={`${LOGO_HEIGHT[h.logo_size ?? "m"]} w-auto`}
          />
        )}
        {showName && (
          <span className={`${NAME_SIZE[h.name_size ?? "m"]} leading-tight`} style={nameStyle}>
            {site.settings.site_name}
          </span>
        )}
      </>
    ) : null;

  if (!brandContent && !showMenu) return null;

  const brandClass = `flex font-heading font-semibold ${stack ? "flex-col items-center gap-1 text-center" : "items-center gap-3"}`;

  return (
    <header className={`${chrome ? "site-chrome " : ""}border-b border-foreground/10`}>
      <div className={`mx-auto flex max-w-5xl gap-4 px-5 py-4 ${ROW[align]}`}>
        {brandContent &&
          (preview ? (
            <span className={brandClass}>{brandContent}</span>
          ) : (
            <Link href="/" className={brandClass}>
              {brandContent}
            </Link>
          ))}
        {showMenu && (
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

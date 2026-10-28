import type { Metadata } from "next";
import type { CSSProperties } from "react";
import "./globals.css";
import { getLiveSite } from "@/lib/data";
import { fontFamily } from "@/lib/fonts";
import { mediaUrl } from "@/lib/format";
import SiteFooter from "@/components/SiteFooter";
import SiteHeader from "@/components/SiteHeader";

const RADIUS: Record<string, string> = { none: "0px", small: "6px", medium: "12px", large: "24px" };

export async function generateMetadata(): Promise<Metadata> {
  const site = await getLiveSite();
  const name = site?.settings.site_name ?? "Handmade by Bi";
  const seo = site?.settings.seo ?? {};
  const image = mediaUrl(seo.image);
  return {
    title: { default: seo.title || name, template: `%s · ${name}` },
    description: seo.description,
    openGraph: {
      siteName: name,
      type: "website",
      locale: "it_IT",
      images: image ? [image] : undefined,
    },
  };
}

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const site = await getLiveSite();
  const t = site?.settings.theme;

  const style = {
    "--c-primary": t?.primary,
    "--c-accent": t?.accent,
    "--c-background": t?.background,
    "--c-text": t?.text,
    "--f-heading": fontFamily(t?.font_heading, "Fraunces"),
    "--f-body": fontFamily(t?.font_body, "Nunito"),
    "--r-site": RADIUS[t?.radius ?? "medium"] ?? RADIUS.medium,
  } as CSSProperties;

  return (
    <html lang="it" style={style}>
      <body className="flex min-h-dvh flex-col antialiased">
        {site && <SiteHeader site={site} />}
        <main className="flex-1">{children}</main>
        {site && <SiteFooter site={site} />}
      </body>
    </html>
  );
}

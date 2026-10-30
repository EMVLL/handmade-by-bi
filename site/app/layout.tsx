import type { Metadata } from "next";
import "./globals.css";
import { getLiveSite } from "@/lib/data";
import { mediaUrl } from "@/lib/format";
import { themeStyle } from "@/lib/theme";
import SiteFooter from "@/components/SiteFooter";
import SiteHeader from "@/components/SiteHeader";

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
  const style = themeStyle(site?.settings.theme);

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

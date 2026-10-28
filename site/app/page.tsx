import type { Metadata } from "next";
import BlockList from "@/components/BlockList";
import { getLiveSite } from "@/lib/data";

export async function generateMetadata(): Promise<Metadata> {
  const site = await getLiveSite();
  const home = site?.pages.find((p) => p.is_home);
  return {
    title: home?.seo?.title ? { absolute: home.seo.title } : undefined,
    description: home?.seo?.description || undefined,
  };
}

export default async function HomePage() {
  const site = await getLiveSite();
  const home = site?.pages.find((p) => p.is_home);

  if (!site || !home) {
    return (
      <div className="mx-auto max-w-xl px-5 py-24 text-center">
        <h1 className="font-heading text-4xl">Stiamo preparando il negozio</h1>
        <p className="mt-4 opacity-70">Torna a trovarci tra poco!</p>
      </div>
    );
  }

  return <BlockList blocks={home.blocks} site={site} />;
}

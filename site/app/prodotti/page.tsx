import type { Metadata } from "next";
import ProductsView from "@/components/views/ProductsView";
import { getLiveSite } from "@/lib/data";

export const metadata: Metadata = { title: "Tutti i lavori" };

export default async function ProductsPage() {
  const site = await getLiveSite();
  return <ProductsView site={site} />;
}

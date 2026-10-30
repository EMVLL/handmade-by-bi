import { cacheLife, cacheTag } from "next/cache";
import { supabase } from "./supabase";
import type { Collection, LiveSite, Product } from "./types";

// Versione pubblicata del sito (tema, contatti, pagine, blocchi, menu).
// Si aggiorna da sola entro ~1 minuto da una nuova pubblicazione;
// /api/revalidate la aggiorna subito.
export async function getLiveSite(): Promise<LiveSite | null> {
  "use cache";
  cacheTag("site");
  cacheLife("minutes");

  const { data, error } = await supabase.rpc("get_live_site");
  if (error) throw new Error(`Supabase get_live_site: ${error.message}`);
  return (data as LiveSite | null) ?? null;
}

// Catalogo: le policy RLS restituiscono solo i prodotti visibili.
export async function getProducts(): Promise<Product[]> {
  "use cache";
  cacheTag("products");
  cacheLife("minutes");

  const { data, error } = await supabase
    .from("products")
    .select(
      "id, slug, title, description, price, compare_at_price, status, photos, options, vinted_url, position, created_at, product_collections(collection_id, position)",
    )
    .order("position", { ascending: true })
    .order("created_at", { ascending: false });

  if (error) throw new Error(`Supabase products: ${error.message}`);
  return (data ?? []) as unknown as Product[];
}

export async function getProduct(slug: string): Promise<Product | null> {
  const products = await getProducts();
  return products.find((p) => p.slug === slug) ?? null;
}

// Categorie create da Benedetta (le automatiche le calcola lib/categories.ts).
export async function getCollections(): Promise<Collection[]> {
  "use cache";
  cacheTag("products");
  cacheLife("minutes");

  const { data, error } = await supabase
    .from("collections")
    .select("id, slug, name, description, cover_path, position")
    .order("position", { ascending: true })
    .order("name", { ascending: true });

  if (error) throw new Error(`Supabase collections: ${error.message}`);
  return (data ?? []) as Collection[];
}

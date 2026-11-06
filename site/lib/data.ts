import { cacheLife, cacheTag } from "next/cache";
import { supabase } from "./supabase";
import type { Collection, LiveSite, Product } from "./types";

// Per quanto tempo il sito tiene in memoria i dati.
// - revalidate 60 s: se l'avviso dal database non arriva, le novità compaiono comunque entro ~1 minuto.
// - expire 30 giorni: anche dopo ore senza visite le pagine si aprono subito (si aggiornano
//   dietro le quinte), invece di aspettare Supabase. Quando Benedetta salva o pubblica, il database
//   avvisa /api/revalidate e la copia vecchia viene scartata all'istante.
const DURATA = { stale: 300, revalidate: 60, expire: 60 * 60 * 24 * 30 };

type Risposta = PromiseLike<{ data: unknown; error: { message: string } | null }>;

/** Fino a 3 tentativi: un intoppo momentaneo di rete non deve diventare una pagina di errore. */
async function leggi(nome: string, query: () => Risposta): Promise<unknown> {
  let ultimoErrore = "";
  for (let tentativo = 1; tentativo <= 3; tentativo++) {
    const { data, error } = await query();
    if (!error) return data;
    ultimoErrore = error.message;
    if (tentativo < 3) await new Promise((fine) => setTimeout(fine, 400 * tentativo));
  }
  throw new Error(`Supabase ${nome}: ${ultimoErrore}`);
}

// Versione pubblicata del sito (tema, contatti, pagine, blocchi, menu).
export async function getLiveSite(): Promise<LiveSite | null> {
  "use cache";
  cacheTag("site");
  cacheLife(DURATA);

  const data = await leggi("get_live_site", () => supabase.rpc("get_live_site"));
  return (data as LiveSite | null) ?? null;
}

// Catalogo: le policy RLS restituiscono solo i prodotti visibili.
export async function getProducts(): Promise<Product[]> {
  "use cache";
  cacheTag("products");
  cacheLife(DURATA);

  const data = await leggi("products", () =>
    supabase
      .from("products")
      .select(
        "id, slug, title, description, price, compare_at_price, status, photos, options, vinted_url, lead_time, show_lead_time, position, created_at, product_collections(collection_id, position)",
      )
      .order("position", { ascending: true })
      .order("created_at", { ascending: false }),
  );
  return (data ?? []) as Product[];
}

export async function getProduct(slug: string): Promise<Product | null> {
  const products = await getProducts();
  return products.find((p) => p.slug === slug) ?? null;
}

// Categorie create da Benedetta (le automatiche le calcola lib/categories.ts).
export async function getCollections(): Promise<Collection[]> {
  "use cache";
  cacheTag("products");
  cacheLife(DURATA);

  const data = await leggi("collections", () =>
    supabase
      .from("collections")
      .select("id, slug, name, description, cover_path, position")
      .order("position", { ascending: true })
      .order("name", { ascending: true }),
  );
  return (data ?? []) as Collection[];
}

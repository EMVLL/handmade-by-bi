import { mediaUrl } from "./format";
import type { Collection, LiveSite, Product } from "./types";

// Due categorie automatiche: nessuno deve tenerle aggiornate a mano.
export const READY_SLUG = "pronta-consegna"; // pezzi con stato "disponibile"
export const OTHER_SLUG = "altro"; // pezzi senza categoria

export interface MenuSettings {
  title: string;
  style: "tiles" | "buttons";
  showReady: boolean;
  readyLabel: string;
  showOther: boolean;
  otherLabel: string;
  hideEmpty: boolean;
}

const str = (v: unknown, d: string) => (typeof v === "string" && v ? v : d);
const bool = (v: unknown, d: boolean) => (typeof v === "boolean" ? v : d);

export function menuSettings(props: Record<string, unknown> = {}): MenuSettings {
  return {
    title: typeof props.title === "string" ? props.title : "Scegli una categoria",
    style: props.style === "buttons" ? "buttons" : "tiles",
    showReady: bool(props.show_ready, true),
    readyLabel: str(props.ready_label, "Disponibili in pronta consegna"),
    showOther: bool(props.show_other, true),
    otherLabel: str(props.other_label, "Altro"),
    hideEmpty: bool(props.hide_empty, true),
  };
}

/** Impostazioni del primo "Menu categorie" pubblicato (servono anche alle pagine categoria). */
export function siteMenuSettings(site: LiveSite | null): MenuSettings {
  for (const page of site?.pages ?? []) {
    const block = page.blocks.find((b) => b.type === "category_menu");
    if (block) return menuSettings(block.props);
  }
  return menuSettings();
}

/** Pezzi di una categoria, nell'ordine scelto. */
export function productsInCategory(slug: string, products: Product[], collections: Collection[]): Product[] {
  if (slug === READY_SLUG) return products.filter((p) => p.status === "disponibile");
  if (slug === OTHER_SLUG) return products.filter((p) => !p.product_collections?.length);
  const collection = collections.find((c) => c.slug === slug);
  if (!collection) return [];
  const pos = (p: Product) =>
    p.product_collections.find((pc) => pc.collection_id === collection.id)?.position ?? 0;
  return products
    .filter((p) => p.product_collections?.some((pc) => pc.collection_id === collection.id))
    .sort((a, b) => pos(a) - pos(b) || b.created_at.localeCompare(a.created_at));
}

export interface CategoryEntry {
  slug: string;
  name: string;
  href: string;
  count: number;
  cover: string | null;
}

/** Voci del menu, nell'ordine: categorie di Benedetta, poi Pronta consegna e Altro. */
export function categoryEntries(
  settings: MenuSettings,
  products: Product[],
  collections: Collection[],
): CategoryEntry[] {
  const make = (slug: string, name: string): CategoryEntry => {
    const items = productsInCategory(slug, products, collections);
    const withPhoto = items.find((p) => p.photos?.length);
    return {
      slug,
      name,
      href: `/collezioni/${slug}`,
      count: items.length,
      cover: withPhoto ? mediaUrl(withPhoto.photos[0]) : null,
    };
  };
  const entries = collections.map((c) => make(c.slug, c.name));
  if (settings.showReady) entries.push(make(READY_SLUG, settings.readyLabel));
  if (settings.showOther) entries.push(make(OTHER_SLUG, settings.otherLabel));
  return settings.hideEmpty ? entries.filter((e) => e.count > 0) : entries;
}

export function categoryName(slug: string, settings: MenuSettings, collections: Collection[]): string | null {
  if (slug === READY_SLUG) return settings.readyLabel;
  if (slug === OTHER_SLUG) return settings.otherLabel;
  return collections.find((c) => c.slug === slug)?.name ?? null;
}

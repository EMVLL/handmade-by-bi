import type { LiveSite, MenuItem } from "./types";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";

export function mediaUrl(path?: string | null): string | null {
  if (!path) return null;
  const safe = path.split("/").map(encodeURIComponent).join("/");
  return `${SUPABASE_URL}/storage/v1/object/public/media/${safe}`;
}

/**
 * Punto da tenere al centro quando una foto viene ritagliata (griglie, nastro, miniature):
 * scelto da Benedetta nell'app, altrimenti il centro della foto. Valore CSS per object-position.
 */
export function photoPosition(
  focus: Record<string, { x: number; y: number }> | null | undefined,
  path: string | null | undefined,
): string | undefined {
  const f = path ? focus?.[path] : undefined;
  if (!f) return undefined;
  const pct = (v: unknown) => (typeof v === "number" && Number.isFinite(v) ? Math.min(100, Math.max(0, v)) : 50);
  return `${pct(f.x)}% ${pct(f.y)}%`;
}

const eur = new Intl.NumberFormat("it-IT", { style: "currency", currency: "EUR" });

export function formatPrice(value: number | null | undefined): string | null {
  return value == null ? null : eur.format(value);
}

export function priceLabel(value: number | null | undefined): string {
  return formatPrice(value) ?? "prezzo su richiesta";
}

// Letture tolleranti delle props dei blocchi: mai un crash per un campo strano.
export const str = (v: unknown, fallback = ""): string => (typeof v === "string" ? v : fallback);
export const bool = (v: unknown, fallback: boolean): boolean => (typeof v === "boolean" ? v : fallback);
export const num = (v: unknown, fallback: number): number =>
  typeof v === "number" && Number.isFinite(v) ? v : fallback;
export const list = <T,>(v: unknown): T[] => (Array.isArray(v) ? (v as T[]) : []);

export function paragraphs(text: string): string[] {
  return text
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter(Boolean);
}

export function isInternal(href: string): boolean {
  return href.startsWith("/");
}

export function menuHref(site: LiveSite, item: MenuItem): string | null {
  if (item.url) return item.url;
  const page = site.pages.find((p) => p.id === item.page_id);
  if (!page) return null;
  return page.is_home ? "/" : `/${page.slug}`;
}

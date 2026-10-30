import { supabase } from "./supabase";
import type { LiveSite } from "./types";

export type PreviewSearch = Promise<{ t?: string | string[] }>;

/** Sito in BOZZA per l'anteprima (serve la chiave giusta, altrimenti null). Mai in cache. */
export async function loadDraft(searchParams: PreviewSearch): Promise<{ site: LiveSite; token: string } | null> {
  const { t } = await searchParams;
  const token = typeof t === "string" ? t : "";
  if (!token) return null;
  const { data, error } = await supabase.rpc("get_draft_site", { p_token: token });
  if (error || !data) return null;
  return { site: data as LiveSite, token };
}

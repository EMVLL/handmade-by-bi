export type Props = Record<string, unknown>;

export interface Theme {
  primary: string;
  background: string;
  text: string;
  accent: string;
  font_heading: string;
  font_body: string;
  radius: "none" | "small" | "medium" | "large";
}

interface Channel {
  enabled?: boolean;
}

export interface Contacts {
  whatsapp?: Channel & { number?: string; template?: string };
  email?: Channel & { address?: string; subject_template?: string; body_template?: string };
  vinted?: Channel & { profile_url?: string };
  instagram?: Channel & { profile_url?: string };
}

export interface Seo {
  title?: string;
  description?: string;
  image?: string;
}

export interface Block {
  id: string;
  type: string;
  position: number;
  visible: boolean;
  props: Props;
}

export interface SitePage {
  id: string;
  slug: string;
  title: string;
  seo: Seo;
  is_home: boolean;
  position: number;
  blocks: Block[];
}

export interface MenuItem {
  id: string;
  label: string;
  page_id: string | null;
  url: string | null;
  position: number;
}

export interface HeaderSettings {
  show_logo?: boolean;
  logo_size?: "s" | "m" | "l" | "xl";
  show_name?: boolean;
  name_size?: "s" | "m" | "l";
  name_font?: string;
  align?: "left" | "center" | "right";
  arrangement?: "row" | "stack";
  name_style?: TextStyle;
}

export type TextStyle = "normal" | "italic" | "uppercase" | "italic_uppercase";

/** Etichette sui pezzi (Negozio → Etichette dei pezzi). Colori vuoti = colori del tema. */
export interface BadgeSettings {
  show?: boolean;
  font?: string;
  text_style?: TextStyle;
  position?: "top_left" | "top_right" | "bottom_left" | "bottom_right";
  ready_show?: boolean;
  ready_text?: string;
  ready_bg?: string;
  ready_color?: string;
  order_show?: boolean;
  order_text?: string;
  order_bg?: string;
  order_color?: string;
  sold_show?: boolean;
  sold_text?: string;
  sold_bg?: string;
  sold_color?: string;
  /** Tempi di realizzazione anche nei riquadri dei pezzi (script 009) */
  lead_time_cards?: boolean;
}

export interface LiveSite {
  settings: {
    site_name: string;
    logo_path: string | null;
    theme: Theme;
    contacts: Contacts;
    seo: Seo;
    header?: HeaderSettings;
    badges?: BadgeSettings;
  };
  pages: SitePage[];
  menu: MenuItem[];
}

export type ProductStatus = "disponibile" | "su_ordinazione" | "venduto" | "nascosto";

export interface ProductOption {
  name: string;
  values: string[];
}

export interface Product {
  id: string;
  slug: string;
  title: string;
  description: string;
  price: number | null;
  compare_at_price: number | null;
  status: ProductStatus;
  photos: string[];
  options: ProductOption[];
  vinted_url: string | null;
  /** Tempi di realizzazione, es. "7–10 giorni" (script 008) */
  lead_time: string | null;
  show_lead_time: boolean;
  position: number;
  created_at: string;
  product_collections: { collection_id: string; position: number }[];
}

export interface Collection {
  id: string;
  slug: string;
  name: string;
  description: string;
  cover_path: string | null;
  position: number;
}

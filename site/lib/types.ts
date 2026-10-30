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

export interface LiveSite {
  settings: {
    site_name: string;
    logo_path: string | null;
    theme: Theme;
    contacts: Contacts;
    seo: Seo;
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

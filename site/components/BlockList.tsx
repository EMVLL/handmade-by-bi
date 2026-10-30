import type { CSSProperties } from "react";
import type { Block, LiveSite, Props } from "@/lib/types";
import { getCollections, getProducts } from "@/lib/data";
import { fontFamily } from "@/lib/fonts";
import { RENDERERS, type BlockContext } from "./blocks";

const NEEDS_PRODUCTS = new Set(["product_grid", "featured_product", "category_menu"]);
const NEEDS_COLLECTIONS = new Set(["category_menu"]);

// Sfondo scelto per la sezione ("Aspetto" nell'app)
const BACKGROUND: Record<string, string> = {
  soft: "bg-foreground/5",
  primary: "bg-primary text-white",
  accent: "bg-accent text-white",
};

const SIZES = new Set(["s", "l"]);

/** Attributi della sezione: sfondo, carattere e grandezza del titolo. */
function sectionLook(props: Props): { className?: string; style?: CSSProperties; size?: string; bg?: string } {
  const bg = typeof props.section_bg === "string" ? props.section_bg : "";
  const font = typeof props.title_font === "string" && props.title_font !== "theme" ? props.title_font : null;
  const size = typeof props.title_size === "string" && SIZES.has(props.title_size) ? props.title_size : undefined;
  return {
    className: `blk ${BACKGROUND[bg] ?? ""}`.trim(),
    style: font ? ({ "--bt-font": fontFamily(font, "Fraunces") } as CSSProperties) : undefined,
    size,
    bg: BACKGROUND[bg] ? bg : undefined,
  };
}

// Disegna i blocchi di una pagina. Un blocco sconosciuto o difettoso
// viene saltato (e segnalato nei log): la pagina non cade mai per colpa sua.
export default async function BlockList({ blocks, site }: { blocks: Block[]; site: LiveSite }) {
  const visible = blocks.filter((b) => b.visible).sort((a, b) => a.position - b.position);
  const [products, collections] = await Promise.all([
    visible.some((b) => NEEDS_PRODUCTS.has(b.type)) ? getProducts() : [],
    visible.some((b) => NEEDS_COLLECTIONS.has(b.type)) ? getCollections() : [],
  ]);
  const ctx: BlockContext = { site, products, collections };

  return (
    <>
      {visible.map((b) => {
        const render = RENDERERS[b.type];
        if (!render) return null;
        try {
          const props = b.props ?? {};
          const content = render(props, ctx);
          if (!content) return null;
          const look = sectionLook(props);
          return (
            <section key={b.id} className={look.className} style={look.style} data-ts={look.size} data-bg={look.bg}>
              {content}
            </section>
          );
        } catch (err) {
          console.error(`Blocco "${b.type}" (${b.id}) saltato:`, err);
          return null;
        }
      })}
    </>
  );
}

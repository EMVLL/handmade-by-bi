import type { Block, LiveSite } from "@/lib/types";
import { getCollections, getProducts } from "@/lib/data";
import { RENDERERS, type BlockContext } from "./blocks";

const NEEDS_PRODUCTS = new Set(["product_grid", "featured_product", "category_menu"]);
const NEEDS_COLLECTIONS = new Set(["category_menu"]);

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
          const content = render(b.props ?? {}, ctx);
          return content ? <section key={b.id}>{content}</section> : null;
        } catch (err) {
          console.error(`Blocco "${b.type}" (${b.id}) saltato:`, err);
          return null;
        }
      })}
    </>
  );
}

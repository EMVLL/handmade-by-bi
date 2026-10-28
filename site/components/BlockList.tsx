import type { Block, LiveSite } from "@/lib/types";
import { getProducts } from "@/lib/data";
import { RENDERERS, type BlockContext } from "./blocks";

const NEEDS_PRODUCTS = new Set(["product_grid", "featured_product"]);

// Disegna i blocchi di una pagina. Un blocco sconosciuto o difettoso
// viene saltato (e segnalato nei log): la pagina non cade mai per colpa sua.
export default async function BlockList({ blocks, site }: { blocks: Block[]; site: LiveSite }) {
  const visible = blocks.filter((b) => b.visible).sort((a, b) => a.position - b.position);
  const products = visible.some((b) => NEEDS_PRODUCTS.has(b.type)) ? await getProducts() : [];
  const ctx: BlockContext = { site, products };

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

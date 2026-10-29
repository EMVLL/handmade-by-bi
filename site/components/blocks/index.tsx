import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";
import { categoryEntries, menuSettings } from "@/lib/categories";
import type { Collection, LiveSite, Product, Props } from "@/lib/types";
import { bool, list, mediaUrl, num, paragraphs, str } from "@/lib/format";
import CategoryMenu from "../CategoryMenu";
import ContactLinks from "../ContactLinks";
import ProductCard, { PriceLine } from "../ProductCard";
import SmartLink from "../SmartLink";

export interface BlockContext {
  site: LiveSite;
  products: Product[];
  collections: Collection[];
}

type Renderer = (props: Props, ctx: BlockContext) => ReactNode;

const wrap = "mx-auto w-full max-w-5xl px-5";
const button =
  "inline-flex items-center justify-center rounded-site bg-primary px-6 py-3 font-semibold text-white transition hover:opacity-90";

const GRID: Record<number, string> = {
  2: "grid-cols-2",
  3: "grid-cols-2 md:grid-cols-3",
  4: "grid-cols-2 md:grid-cols-4",
};

function Title({ text, center = false }: { text: string; center?: boolean }) {
  if (!text) return null;
  return <h2 className={`mb-6 font-heading text-3xl ${center ? "text-center" : ""}`}>{text}</h2>;
}

// ---------------------------------------------------------------- Copertina
const hero: Renderer = (p) => {
  const title = str(p.title, "Fatto a mano, con amore");
  const subtitle = str(p.subtitle);
  const image = mediaUrl(str(p.image) || null);
  const btnText = str(p.button_text);
  const btnLink = str(p.button_link);
  const layout = str(p.layout, "center");
  const cta = btnText && btnLink ? <SmartLink href={btnLink} className={button}>{btnText}</SmartLink> : null;

  if (layout === "full_image" && image) {
    return (
      <div className="relative isolate flex min-h-[70vh] items-end">
        <Image src={image} alt="" fill sizes="100vw" loading="eager" fetchPriority="high" className="-z-10 object-cover" />
        <div className="absolute inset-0 -z-10 bg-gradient-to-t from-black/60 to-black/10" />
        <div className={`${wrap} pb-14 text-white`}>
          <h1 className="max-w-2xl font-heading text-4xl leading-tight md:text-6xl">{title}</h1>
          {subtitle && <p className="mt-4 max-w-xl text-lg opacity-90">{subtitle}</p>}
          {cta && <div className="mt-8">{cta}</div>}
        </div>
      </div>
    );
  }

  const left = layout === "left";
  return (
    <div className={`${wrap} py-14 md:py-20`}>
      <div className={`grid items-center gap-10 ${image ? "md:grid-cols-2" : ""}`}>
        <div className={left || image ? "" : "mx-auto max-w-2xl text-center"}>
          <h1 className="font-heading text-4xl leading-tight md:text-6xl">{title}</h1>
          {subtitle && <p className="mt-4 text-lg opacity-80">{subtitle}</p>}
          {cta && <div className="mt-8">{cta}</div>}
        </div>
        {image && (
          <div className="relative aspect-[4/5] overflow-hidden rounded-site">
            <Image src={image} alt="" fill sizes="(min-width: 768px) 50vw, 100vw" loading="eager" fetchPriority="high" className="object-cover" />
          </div>
        )}
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- Testo
const text: Renderer = (p) => {
  const body = paragraphs(str(p.body));
  const title = str(p.title);
  if (!title && !body.length) return null;
  const center = str(p.align) === "center";
  return (
    <div className={`${wrap} py-10`}>
      <div className={`max-w-2xl ${center ? "mx-auto text-center" : ""}`}>
        <Title text={title} center={center} />
        <div className="space-y-4 text-lg leading-relaxed">
          {body.map((para, i) => (
            <p key={i} className="whitespace-pre-line">
              {para}
            </p>
          ))}
        </div>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- Galleria
const gallery: Renderer = (p) => {
  const images = list<string>(p.images)
    .map((path) => mediaUrl(typeof path === "string" ? path : null))
    .filter((u): u is string => Boolean(u));
  if (!images.length) return null;
  const carousel = str(p.style) === "carousel";
  const cols = num(p.columns, 3);
  return (
    <div className={`${wrap} py-10`}>
      <Title text={str(p.title)} />
      {carousel ? (
        <div className="-mx-5 flex snap-x snap-mandatory gap-3 overflow-x-auto px-5 pb-2">
          {images.map((src) => (
            <div key={src} className="relative aspect-square w-4/5 shrink-0 snap-center overflow-hidden rounded-site sm:w-1/3">
              <Image src={src} alt="" fill sizes="(min-width: 640px) 33vw, 80vw" className="object-cover" />
            </div>
          ))}
        </div>
      ) : (
        <div className={`grid gap-3 ${GRID[cols] ?? GRID[3]}`}>
          {images.map((src) => (
            <div key={src} className="relative aspect-square overflow-hidden rounded-site">
              <Image src={src} alt="" fill sizes="(min-width: 768px) 33vw, 50vw" className="object-cover" />
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

// ---------------------------------------------------------------- Griglia prodotti
const productGrid: Renderer = (p, ctx) => {
  const collection = str(p.collection_id);
  const sort = str(p.sort, "newest");
  let items = ctx.products;

  if (collection) items = items.filter((x) => x.product_collections?.some((c) => c.collection_id === collection));
  if (!bool(p.show_sold, true)) items = items.filter((x) => x.status !== "venduto");

  const collPos = (x: Product) => x.product_collections?.find((c) => c.collection_id === collection)?.position ?? 0;
  items = [...items].sort((a, b) => {
    switch (sort) {
      case "manual":
        return collection ? collPos(a) - collPos(b) : a.position - b.position;
      case "price_asc":
        return (a.price ?? Infinity) - (b.price ?? Infinity);
      case "price_desc":
        return (b.price ?? -Infinity) - (a.price ?? -Infinity);
      default:
        return b.created_at.localeCompare(a.created_at);
    }
  });
  items = items.slice(0, Math.max(1, num(p.limit, 12)));
  if (!items.length) return null;

  const cols = num(p.columns, 3);
  return (
    <div className={`${wrap} py-10`}>
      <Title text={str(p.title)} />
      <div className={`grid gap-x-4 gap-y-8 ${GRID[cols] ?? GRID[3]}`}>
        {items.map((x) => (
          <ProductCard key={x.id} product={x} showPrice={bool(p.show_price, true)} />
        ))}
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- Menu categorie
const categoryMenu: Renderer = (p, ctx) => {
  const settings = menuSettings(p);
  const entries = categoryEntries(settings, ctx.products, ctx.collections);
  if (!entries.length) return null;
  return (
    <div className={`${wrap} py-10`}>
      <Title text={settings.title} />
      <CategoryMenu entries={entries} style={settings.style} />
    </div>
  );
};

// ---------------------------------------------------------------- Prodotto in evidenza
const featuredProduct: Renderer = (p, ctx) => {
  const product = ctx.products.find((x) => x.id === str(p.product_id));
  if (!product) return null;
  const image = mediaUrl(product.photos?.[0]);
  const right = str(p.layout) === "image_right";
  const extra = str(p.text);
  return (
    <div className={`${wrap} py-10`}>
      <div className="grid items-center gap-8 md:grid-cols-2">
        <div className={`relative aspect-square overflow-hidden rounded-site bg-foreground/5 ${right ? "md:order-2" : ""}`}>
          {image && <Image src={image} alt={product.title} fill sizes="(min-width: 768px) 50vw, 100vw" className="object-cover" />}
        </div>
        <div>
          <h2 className="font-heading text-3xl">{product.title}</h2>
          <PriceLine product={product} className="mt-2 text-lg" />
          {extra && <p className="mt-4 text-lg opacity-80">{extra}</p>}
          <Link href={`/prodotti/${product.slug}`} className={`${button} mt-6`}>
            Scopri
          </Link>
        </div>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- Recensioni
const testimonials: Renderer = (p) => {
  const items = list<{ name?: unknown; text?: unknown }>(p.items).filter((i) => str(i?.text));
  if (!items.length) return null;
  return (
    <div className={`${wrap} py-10`}>
      <Title text={str(p.title)} center />
      <div className="grid gap-4 md:grid-cols-3">
        {items.map((i, idx) => (
          <figure key={idx} className="rounded-site bg-foreground/5 p-6">
            <blockquote className="leading-relaxed">“{str(i.text)}”</blockquote>
            <figcaption className="mt-4 text-sm font-semibold">{str(i.name)}</figcaption>
          </figure>
        ))}
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- FAQ
const faq: Renderer = (p) => {
  const items = list<{ question?: unknown; answer?: unknown }>(p.items).filter((i) => str(i?.question));
  if (!items.length) return null;
  return (
    <div className={`${wrap} py-10`}>
      <div className="mx-auto max-w-2xl">
        <Title text={str(p.title)} center />
        <div className="divide-y divide-foreground/10 border-y border-foreground/10">
          {items.map((i, idx) => (
            <details key={idx} className="group py-4">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-semibold">
                {str(i.question)}
                <span className="transition group-open:rotate-45">+</span>
              </summary>
              <p className="mt-3 whitespace-pre-line opacity-80">{str(i.answer)}</p>
            </details>
          ))}
        </div>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- Contatti
const contact: Renderer = (p, ctx) => {
  const links = (
    <ContactLinks
      contacts={ctx.site.settings.contacts}
      show={{
        whatsapp: bool(p.show_whatsapp, true),
        email: bool(p.show_email, true),
        vinted: bool(p.show_vinted, true),
        instagram: bool(p.show_instagram, true),
      }}
    />
  );
  return (
    <div className={`${wrap} py-12`}>
      <div className="mx-auto max-w-2xl rounded-site bg-foreground/5 px-6 py-10 text-center">
        <Title text={str(p.title)} center />
        {str(p.text) && <p className="-mt-2 mb-6 text-lg opacity-80">{str(p.text)}</p>}
        <div className="flex justify-center">{links}</div>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- Avviso
const BANNER: Record<string, string> = {
  info: "bg-foreground/5",
  highlight: "bg-primary text-white",
  sale: "bg-accent text-white",
};

const banner: Renderer = (p) => {
  const message = str(p.text);
  if (!message) return null;
  const link = str(p.link);
  const cls = `block px-5 py-3 text-center text-sm font-semibold ${BANNER[str(p.style)] ?? BANNER.info}`;
  return link ? (
    <SmartLink href={link} className={`${cls} hover:underline`}>
      {message}
    </SmartLink>
  ) : (
    <div className={cls}>{message}</div>
  );
};

// ---------------------------------------------------------------- Spazio
const SPACE: Record<string, string> = { small: "h-6", medium: "h-12", large: "h-24" };

const spacer: Renderer = (p) => (
  <div className={`${wrap} flex items-center ${SPACE[str(p.size)] ?? SPACE.medium}`}>
    {bool(p.divider, false) && <hr className="w-full border-foreground/10" />}
  </div>
);

export const RENDERERS: Record<string, Renderer> = {
  hero,
  text,
  gallery,
  product_grid: productGrid,
  category_menu: categoryMenu,
  featured_product: featuredProduct,
  testimonials,
  faq,
  contact,
  banner,
  spacer,
};

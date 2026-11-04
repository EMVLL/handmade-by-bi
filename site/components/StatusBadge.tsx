import type { CSSProperties } from "react";
import { fontFamily } from "@/lib/fonts";
import { textStyleCss } from "@/lib/textStyle";
import type { BadgeSettings, ProductStatus } from "@/lib/types";

const POSITION = {
  top_left: "left-3 top-3",
  top_right: "right-3 top-3",
  bottom_left: "left-3 bottom-3",
  bottom_right: "right-3 bottom-3",
} as const;

// Valori di sempre: "Su ordinazione" e "Venduto" visibili, "Disponibile" nascosta.
const DEFAULTS = {
  disponibile: { key: "ready", show: false, text: "Disponibile", bg: "var(--c-primary)", color: "#FFFFFF" },
  su_ordinazione: { key: "order", show: true, text: "Su ordinazione", bg: "var(--c-accent)", color: "#FFFFFF" },
  venduto: { key: "sold", show: true, text: "Venduto", bg: "var(--c-text)", color: "var(--c-background)" },
} as const;

/** Testo e colori dell'etichetta per questo stato (null se non va mostrata). */
export function badgeLook(status: ProductStatus, settings: BadgeSettings = {}) {
  if (settings.show === false || status === "nascosto") return null;
  const d = DEFAULTS[status];
  const s = settings as Record<string, unknown>;
  const show = typeof s[`${d.key}_show`] === "boolean" ? (s[`${d.key}_show`] as boolean) : d.show;
  if (!show) return null;
  const text = typeof s[`${d.key}_text`] === "string" && s[`${d.key}_text`] ? (s[`${d.key}_text`] as string) : d.text;
  const style: CSSProperties = {
    background: (s[`${d.key}_bg`] as string) || d.bg,
    color: (s[`${d.key}_color`] as string) || d.color,
    ...(settings.font && settings.font !== "theme" ? { fontFamily: fontFamily(settings.font, "Nunito") } : {}),
    ...textStyleCss(settings.text_style),
  };
  return { text, style };
}

/** Etichetta sopra la foto di un pezzo. */
export default function StatusBadge({ status, settings }: { status: ProductStatus; settings?: BadgeSettings }) {
  const look = badgeLook(status, settings);
  if (!look) return null;
  return (
    <span
      className={`absolute rounded-full px-3 py-1 text-xs font-semibold ${POSITION[settings?.position ?? "top_left"] ?? POSITION.top_left}`}
      style={look.style}
    >
      {look.text}
    </span>
  );
}

/** La stessa etichetta, in riga (scheda del pezzo). */
export function StatusPill({ status, settings }: { status: ProductStatus; settings?: BadgeSettings }) {
  const look = badgeLook(status, settings);
  if (!look) return null;
  return (
    <span className="inline-block rounded-full px-3 py-1 text-xs font-semibold" style={look.style}>
      {look.text}
    </span>
  );
}

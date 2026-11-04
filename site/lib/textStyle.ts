import type { CSSProperties } from "react";

/** Corsivo / stampatello scelti nell'app, come stile CSS. */
export function textStyleCss(style: string | undefined): CSSProperties {
  const italic = style === "italic" || style === "italic_uppercase";
  const upper = style === "uppercase" || style === "italic_uppercase";
  return {
    ...(italic ? { fontStyle: "italic" } : {}),
    ...(upper ? { textTransform: "uppercase", letterSpacing: "0.04em" } : {}),
  };
}

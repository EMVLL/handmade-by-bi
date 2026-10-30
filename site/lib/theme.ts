import type { CSSProperties } from "react";
import { fontFamily } from "./fonts";
import type { Theme } from "./types";

const RADIUS: Record<string, string> = { none: "0px", small: "6px", medium: "12px", large: "24px" };

/** Variabili CSS del tema scelto nell'app (usate dal layout e dall'anteprima). */
export function themeStyle(t: Partial<Theme> | undefined): CSSProperties {
  return {
    "--c-primary": t?.primary,
    "--c-accent": t?.accent,
    "--c-background": t?.background,
    "--c-text": t?.text,
    "--f-heading": fontFamily(t?.font_heading, "Fraunces"),
    "--f-body": fontFamily(t?.font_body, "Nunito"),
    "--r-site": RADIUS[t?.radius ?? "medium"] ?? RADIUS.medium,
  } as CSSProperties;
}

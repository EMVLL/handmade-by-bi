"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

// Nell'anteprima i link interni restano in anteprima (/anteprima/...),
// quelli esterni (WhatsApp, Instagram, Vinted…) non si aprono.
export default function PreviewLinks({ token }: { token: string }) {
  const router = useRouter();

  useEffect(() => {
    const root = document.querySelector(".preview-root");
    if (!root) return;

    const onClick = (event: Event) => {
      const link = (event.target as Element | null)?.closest?.("a");
      if (!link || !root.contains(link)) return;
      event.preventDefault();
      event.stopPropagation();

      const href = link.getAttribute("href") ?? "";
      if (!href.startsWith("/") || href.startsWith("//")) return;
      const [path, hash] = href.split("#");
      const target = `/anteprima${path === "/" ? "" : path}?t=${encodeURIComponent(token)}${hash ? `#${hash}` : ""}`;
      router.push(target);
    };

    root.addEventListener("click", onClick, true);
    return () => root.removeEventListener("click", onClick, true);
  }, [router, token]);

  return null;
}

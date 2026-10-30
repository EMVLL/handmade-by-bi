import type { Metadata } from "next";
import type { ReactNode } from "react";

// Tutte le pagine di anteprima sono private: niente motori di ricerca.
export const metadata: Metadata = {
  title: "Anteprima",
  robots: { index: false, follow: false },
};

export default function PreviewLayout({ children }: { children: ReactNode }) {
  return children;
}

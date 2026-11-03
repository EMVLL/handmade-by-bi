import { redirect } from "next/navigation";
import { Suspense } from "react";
import type { PreviewSearch } from "@/lib/preview";

type Props = { searchParams: PreviewSearch };

// Come sul sito: "Tutti i lavori" porta al menu categorie dell'anteprima.
async function Go({ searchParams }: Props) {
  const { t } = await searchParams;
  redirect(`/anteprima?t=${encodeURIComponent(typeof t === "string" ? t : "")}#categorie`);
  return null;
}

export default function PreviewProducts(props: Props) {
  return (
    <Suspense fallback={null}>
      <Go {...props} />
    </Suspense>
  );
}

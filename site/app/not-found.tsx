import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto max-w-xl px-5 py-24 text-center">
      <h1 className="font-heading text-4xl">Pagina non trovata</h1>
      <p className="mt-4 opacity-70">Forse il pezzo che cercavi non è più disponibile.</p>
      <Link href="/" className="mt-8 inline-block rounded-site bg-primary px-6 py-3 font-semibold text-white">
        Torna alla home
      </Link>
    </div>
  );
}

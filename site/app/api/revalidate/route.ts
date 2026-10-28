import { revalidateTag } from "next/cache";

// Aggiornamento immediato dopo una pubblicazione o una modifica ai prodotti.
// Chiamata da un Database Webhook di Supabase con l'header x-revalidate-secret.
export async function POST(request: Request) {
  const secret = process.env.REVALIDATE_SECRET;
  if (!secret || request.headers.get("x-revalidate-secret") !== secret) {
    return Response.json({ ok: false }, { status: 401 });
  }
  revalidateTag("site", { expire: 0 });
  revalidateTag("products", { expire: 0 });
  return Response.json({ ok: true });
}

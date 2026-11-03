import { permanentRedirect } from "next/navigation";

// La pagina "Tutti i lavori" non c'è più: i lavori si guardano per categoria.
// I vecchi link (es. il bottone della copertina) portano al menu categorie in home.
export default function ProductsPage() {
  permanentRedirect("/#categorie");
}

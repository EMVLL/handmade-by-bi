import type { Contacts } from "@/lib/types";

const btn =
  "inline-flex items-center justify-center rounded-site px-5 py-3 text-sm font-semibold transition hover:opacity-90";

// Pulsanti di contatto generici (senza prodotto): blocco "Contatti" e footer.
export default function ContactLinks({
  contacts,
  show = { whatsapp: true, email: true, vinted: true, instagram: true },
  compact = false,
}: {
  contacts: Contacts;
  show?: { whatsapp: boolean; email: boolean; vinted: boolean; instagram: boolean };
  compact?: boolean;
}) {
  const links: { key: string; href: string; label: string; primary?: boolean }[] = [];
  const { whatsapp, email, vinted, instagram } = contacts;

  if (show.whatsapp && whatsapp?.enabled && whatsapp.number) {
    links.push({
      key: "wa",
      href: `https://wa.me/${whatsapp.number}?text=${encodeURIComponent("Ciao!")}`,
      label: "WhatsApp",
      primary: true,
    });
  }
  if (show.email && email?.enabled && email.address) {
    links.push({ key: "mail", href: `mailto:${email.address}`, label: "Email" });
  }
  if (show.instagram && instagram?.enabled && instagram.profile_url) {
    links.push({ key: "ig", href: instagram.profile_url, label: "Instagram" });
  }
  if (show.vinted && vinted?.enabled && vinted.profile_url) {
    links.push({ key: "vinted", href: vinted.profile_url, label: "Vinted" });
  }

  if (!links.length) return null;

  return (
    <div className="flex flex-wrap gap-3">
      {links.map((l) => (
        <a
          key={l.key}
          href={l.href}
          target={l.href.startsWith("mailto:") ? undefined : "_blank"}
          rel="noopener noreferrer"
          className={
            compact
              ? "text-sm underline-offset-4 hover:underline"
              : `${btn} ${l.primary ? "btn bg-primary text-white" : "border border-foreground/20"}`
          }
        >
          {l.label}
        </a>
      ))}
    </div>
  );
}

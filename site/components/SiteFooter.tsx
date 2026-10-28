import type { LiveSite } from "@/lib/types";
import ContactLinks from "./ContactLinks";

export default function SiteFooter({ site }: { site: LiveSite }) {
  return (
    <footer className="mt-16 border-t border-foreground/10">
      <div className="mx-auto flex max-w-5xl flex-col gap-4 px-5 py-8 text-sm sm:flex-row sm:items-center sm:justify-between">
        <p className="opacity-70">© {site.settings.site_name} · Creazioni fatte a mano</p>
        <ContactLinks contacts={site.settings.contacts} compact />
      </div>
    </footer>
  );
}

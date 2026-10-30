"use client";

import { useState } from "react";
import { colorFor, isColorOption } from "@/lib/colors";
import type { Contacts, ProductOption, ProductStatus } from "@/lib/types";

const DEFAULT_TEMPLATE = "Ciao! Vorrei ordinare {prodotto} ({prezzo}). {opzione} {link}";

function fill(template: string, values: Record<string, string>): string {
  return template
    .replace(/\{(prodotto|prezzo|opzione|link)\}/g, (_, key: string) => values[key] ?? "")
    .replace(/[ \t]{2,}/g, " ")
    .replace(/\(\s*\)/g, "")
    .trim();
}

const btn =
  "flex w-full items-center justify-center rounded-site px-5 py-3.5 text-base font-semibold transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40";

export default function OrderPanel({
  title,
  priceText,
  status,
  options,
  vintedUrl,
  contacts,
  preview = false,
}: {
  title: string;
  priceText: string;
  status: ProductStatus;
  options: ProductOption[];
  vintedUrl: string | null;
  contacts: Contacts;
  /** In anteprima i bottoni si vedono ma non aprono WhatsApp o l'email. */
  preview?: boolean;
}) {
  const [choices, setChoices] = useState<Record<string, string>>({});
  const [copied, setCopied] = useState(false);

  const sold = status === "venduto";
  const missing = sold ? [] : options.filter((o) => !choices[o.name]).map((o) => o.name);
  const ready = missing.length === 0;

  // Il messaggio si costruisce al click, così il link è sempre quello della pagina aperta.
  const values = () => ({
    prodotto: title,
    prezzo: priceText,
    opzione: options
      .filter((o) => choices[o.name])
      .map((o) => `${o.name}: ${choices[o.name]}`)
      .join(", "),
    link: window.location.href,
  });

  const { whatsapp, email, vinted, instagram } = contacts;
  const waOn = Boolean(whatsapp?.enabled && whatsapp.number);
  const mailOn = Boolean(email?.enabled && email.address);
  const vintedHref = vintedUrl ?? (vinted?.enabled ? vinted.profile_url : undefined);
  const igHref = instagram?.enabled ? instagram.profile_url : undefined;
  const anyChannel = waOn || mailOn || vintedHref || igHref;

  function openWhatsApp() {
    if (preview) return;
    const text = fill(whatsapp?.template || DEFAULT_TEMPLATE, values());
    window.location.href = `https://wa.me/${whatsapp!.number}?text=${encodeURIComponent(text)}`;
  }

  function openEmail() {
    if (preview) return;
    const v = values();
    const subject = fill(email?.subject_template || "Ordine: {prodotto}", v);
    const body = fill(email?.body_template || DEFAULT_TEMPLATE, v);
    window.location.href = `mailto:${email!.address}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  }

  async function copyEmail() {
    try {
      await navigator.clipboard.writeText(email!.address!);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* clipboard non disponibile: l'indirizzo resta comunque visibile */
    }
  }

  return (
    <div className="space-y-5">
      {!sold &&
        options.map((o, oi) => {
          const colors = isColorOption(o.name);
          const chosen = choices[o.name];
          return (
            <fieldset key={`${o.name}-${oi}`}>
              <legend className="mb-2 text-sm font-semibold">
                {o.name}
                {chosen && <span className="font-normal opacity-70">: {chosen}</span>}
              </legend>
              <div className="flex flex-wrap gap-2">
                {o.values.map((v, vi) => {
                  const active = chosen === v;
                  const swatch = colors ? colorFor(v) : null;
                  return (
                    <button
                      key={`${v}-${vi}`}
                      type="button"
                      onClick={() => setChoices((c) => ({ ...c, [o.name]: v }))}
                      className={`inline-flex min-w-11 items-center justify-center gap-2 rounded-full border px-4 py-2 text-sm transition ${
                        active
                          ? "border-primary bg-primary text-white"
                          : "border-foreground/20 hover:border-primary"
                      }`}
                      aria-pressed={active}
                    >
                      {swatch && (
                        <span
                          aria-hidden
                          className="h-4 w-4 shrink-0 rounded-full border border-black/15"
                          style={{ background: swatch }}
                        />
                      )}
                      {v}
                    </button>
                  );
                })}
              </div>
            </fieldset>
          );
        })}

      {!anyChannel && <p className="text-sm opacity-70">I canali per ordinare saranno attivi a breve.</p>}

      {anyChannel && (
        <div className="space-y-3">
          <p className="text-sm font-semibold">
            {sold ? "Questo pezzo è stato venduto: chiedimi un pezzo simile" : "Ordina scrivendomi su"}
          </p>
          {!ready && <p className="text-sm text-primary">Scegli prima: {missing.join(", ")}</p>}

          {waOn && (
            <button type="button" onClick={openWhatsApp} disabled={!ready} className={`${btn} bg-[#25D366] text-white`}>
              WhatsApp
            </button>
          )}
          {mailOn && (
            <>
              <button
                type="button"
                onClick={openEmail}
                disabled={!ready}
                className={`${btn} border border-foreground/20`}
              >
                Email
              </button>
              <p className="text-center text-xs opacity-70">
                oppure scrivi a {email!.address}{" "}
                <button type="button" onClick={copyEmail} className="underline">
                  {copied ? "copiato!" : "copia"}
                </button>
              </p>
            </>
          )}
          {vintedHref && !sold && (
            <a href={vintedHref} target="_blank" rel="noopener noreferrer" className={`${btn} bg-[#09B1BA] text-white`}>
              {vintedUrl ? "Compra su Vinted" : "Il mio profilo Vinted"}
            </a>
          )}
          {igHref && (
            <a href={igHref} target="_blank" rel="noopener noreferrer" className={`${btn} border border-foreground/20`}>
              Instagram
            </a>
          )}
        </div>
      )}
    </div>
  );
}

import {
  DM_Sans,
  DM_Serif_Display,
  Fraunces,
  Lato,
  Lora,
  Nunito,
  Playfair_Display,
  Quicksand,
} from "next/font/google";

// Tutti i font selezionabili dall'app admin, scaricati e serviti dal sito stesso
// (nessuna richiesta a Google dal browser dei visitatori).
// Il browser scarica solo i file dei font effettivamente usati.
const fraunces = Fraunces({ subsets: ["latin"], display: "swap", preload: false });
const playfair = Playfair_Display({ subsets: ["latin"], display: "swap", preload: false });
const lora = Lora({ subsets: ["latin"], display: "swap", preload: false });
const dmSerif = DM_Serif_Display({ subsets: ["latin"], weight: "400", display: "swap", preload: false });
const nunito = Nunito({ subsets: ["latin"], display: "swap", preload: false });
const quicksand = Quicksand({ subsets: ["latin"], display: "swap", preload: false });
const dmSans = DM_Sans({ subsets: ["latin"], display: "swap", preload: false });
const lato = Lato({ subsets: ["latin"], weight: ["400", "700"], display: "swap", preload: false });

const FONTS: Record<string, { style: { fontFamily: string } }> = {
  Fraunces: fraunces,
  "Playfair Display": playfair,
  Lora: lora,
  "DM Serif Display": dmSerif,
  Nunito: nunito,
  Quicksand: quicksand,
  "DM Sans": dmSans,
  Lato: lato,
};

export function fontFamily(name: string | undefined, fallback: string): string {
  return (FONTS[name ?? ""] ?? FONTS[fallback]).style.fontFamily;
}

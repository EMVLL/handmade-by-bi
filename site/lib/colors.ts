// Colori riconosciuti dal nome: il pallino accanto alle scelte di colore e il filtro
// "Colore" delle categorie. Ogni nome appartiene a una famiglia (Verde, Rosa…): nel filtro
// il cliente sceglie la famiglia, così "verde militare" e "verde salvia" stanno insieme.
// La stessa lista di nomi e tinte è nell'app admin (admin/lib/color_names.dart):
// se ne aggiungi uno qui, aggiungilo anche lì.

export type ColorFamily =
  | "bianco" | "beige" | "marrone" | "grigio" | "nero" | "rosso" | "rosa" | "arancione"
  | "giallo" | "verde" | "azzurro" | "blu" | "viola" | "oro" | "multicolore";

/** Famiglie nell'ordine in cui compaiono nel filtro, con nome e pallino. */
export const FAMILIES: { key: ColorFamily; label: string; swatch: string }[] = [
  { key: "bianco", label: "Bianco e panna", swatch: "#FFF8E7" },
  { key: "beige", label: "Beige", swatch: "#E8D9B5" },
  { key: "marrone", label: "Marrone", swatch: "#7B4B2A" },
  { key: "grigio", label: "Grigio", swatch: "#9E9E9E" },
  { key: "nero", label: "Nero", swatch: "#111111" },
  { key: "rosso", label: "Rosso", swatch: "#D32F2F" },
  { key: "rosa", label: "Rosa", swatch: "#F48FB1" },
  { key: "arancione", label: "Arancione", swatch: "#FB8C00" },
  { key: "giallo", label: "Giallo", swatch: "#FDD835" },
  { key: "verde", label: "Verde", swatch: "#43A047" },
  { key: "azzurro", label: "Azzurro", swatch: "#64B5F6" },
  { key: "blu", label: "Blu", swatch: "#1E40AF" },
  { key: "viola", label: "Viola e lilla", swatch: "#8E24AA" },
  { key: "oro", label: "Oro e argento", swatch: "linear-gradient(135deg, #D4AF37, #F3E5AB 50%, #C0C0C0)" },
  { key: "multicolore", label: "Multicolore", swatch: "conic-gradient(#E53935, #FB8C00, #FDD835, #43A047, #1E88E5, #8E24AA, #E53935)" },
];

// nome (senza accenti, minuscolo) -> [tinta, famiglia]
const PALETTE: Record<string, [string, ColorFamily]> = {
  // bianco e panna
  bianco: ["#FFFFFF", "bianco"], bianca: ["#FFFFFF", "bianco"], bianchi: ["#FFFFFF", "bianco"], bianche: ["#FFFFFF", "bianco"],
  panna: ["#FFF5D6", "bianco"], "bianco panna": ["#FFF5D6", "bianco"], avorio: ["#FFFFF0", "bianco"],
  crema: ["#FFF5D6", "bianco"], latte: ["#FDFBF5", "bianco"], vaniglia: ["#F3E5AB", "bianco"],
  ecru: ["#F0E6D2", "bianco"], ghiaccio: ["#E8F1F5", "azzurro"],
  // beige
  beige: ["#E8D9B5", "beige"], sabbia: ["#D8C49F", "beige"], tortora: ["#A89F91", "beige"], taupe: ["#A89F91", "beige"],
  visone: ["#A28F7D", "beige"], corda: ["#C9B99A", "beige"], naturale: ["#E6D8BD", "beige"], cammello: ["#C19A6B", "beige"],
  // marrone
  marrone: ["#7B4B2A", "marrone"], marroni: ["#7B4B2A", "marrone"], cioccolato: ["#5C3317", "marrone"],
  cuoio: ["#8B5A2B", "marrone"], tabacco: ["#71482A", "marrone"], cognac: ["#9A463D", "marrone"],
  nocciola: ["#A0785A", "marrone"], caramello: ["#AF6E3D", "marrone"], cappuccino: ["#A47551", "marrone"],
  caffe: ["#6F4E37", "marrone"], moka: ["#5E4334", "marrone"], "testa di moro": ["#4A2C21", "marrone"],
  // grigio e nero
  grigio: ["#9E9E9E", "grigio"], grigia: ["#9E9E9E", "grigio"], grigi: ["#9E9E9E", "grigio"], grigie: ["#9E9E9E", "grigio"],
  "grigio chiaro": ["#D3D3D3", "grigio"], "grigio scuro": ["#555555", "grigio"], "grigio perla": ["#D9D9D6", "grigio"],
  perla: ["#E2DFD2", "grigio"], "grigio melange": ["#A9A9A9", "grigio"], fumo: ["#848884", "grigio"],
  antracite: ["#3B3B3B", "grigio"], nero: ["#111111", "nero"], nera: ["#111111", "nero"], neri: ["#111111", "nero"], nere: ["#111111", "nero"],
  // rosso
  rosso: ["#D32F2F", "rosso"], rossa: ["#D32F2F", "rosso"], rossi: ["#D32F2F", "rosso"], rosse: ["#D32F2F", "rosso"],
  "rosso fuoco": ["#E32B1E", "rosso"], "rosso ruggine": ["#A0401E", "rosso"], ciliegia: ["#B11E31", "rosso"],
  mattone: ["#A63A2B", "rosso"], vinaccia: ["#6E1E2E", "rosso"], bordeaux: ["#800020", "rosso"], bordo: ["#800020", "rosso"],
  // rosa
  rosa: ["#F48FB1", "rosa"], "rosa chiaro": ["#F8BBD0", "rosa"], "rosa antico": ["#C08081", "rosa"],
  "rosa cipria": ["#E8B4B8", "rosa"], cipria: ["#E8B4B8", "rosa"], "rosa baby": ["#F8C8DC", "rosa"],
  "rosa shocking": ["#FC0FC0", "rosa"], "rosa pesca": ["#F6B49F", "rosa"], fucsia: ["#E91E63", "rosa"],
  magenta: ["#D81B60", "rosa"], ciclamino: ["#D62D7F", "rosa"], lampone: ["#C72C5B", "rosa"],
  salmone: ["#FA8072", "rosa"], corallo: ["#FF7F50", "arancione"],
  // arancione
  arancione: ["#FB8C00", "arancione"], arancio: ["#FB8C00", "arancione"], arancioni: ["#FB8C00", "arancione"],
  pesca: ["#FFCBA4", "arancione"], albicocca: ["#F7A25B", "arancione"], mandarino: ["#F28500", "arancione"],
  zucca: ["#E8761B", "arancione"], terracotta: ["#C2603F", "arancione"], ruggine: ["#B7410E", "arancione"],
  rame: ["#B87333", "arancione"],
  // giallo
  giallo: ["#FDD835", "giallo"], gialla: ["#FDD835", "giallo"], gialli: ["#FDD835", "giallo"], gialle: ["#FDD835", "giallo"],
  limone: ["#F7E34B", "giallo"], senape: ["#E1AD01", "giallo"], ocra: ["#CC7722", "giallo"], "giallo ocra": ["#CC9922", "giallo"],
  // verde
  verde: ["#43A047", "verde"], verdi: ["#43A047", "verde"], "verde chiaro": ["#9CCC65", "verde"], "verde scuro": ["#1B5E20", "verde"],
  "verde salvia": ["#9CAF88", "verde"], salvia: ["#9CAF88", "verde"], "verde acqua": ["#66CDAA", "verde"],
  "verde bosco": ["#2E5E3A", "verde"], "verde militare": ["#4B5320", "verde"], militare: ["#4B5320", "verde"],
  "verde oliva": ["#808000", "verde"], oliva: ["#808000", "verde"], menta: ["#98E6B0", "verde"],
  "verde bottiglia": ["#09532F", "verde"], bottiglia: ["#09532F", "verde"], smeraldo: ["#1E8E5A", "verde"],
  "verde pistacchio": ["#93C572", "verde"], pistacchio: ["#93C572", "verde"], "verde mela": ["#8DB600", "verde"],
  lime: ["#B5D33D", "verde"], "verde lime": ["#B5D33D", "verde"], "verde petrolio": ["#1B5E62", "verde"],
  // azzurro
  azzurro: ["#64B5F6", "azzurro"], azzurra: ["#64B5F6", "azzurro"], azzurri: ["#64B5F6", "azzurro"], azzurre: ["#64B5F6", "azzurro"],
  celeste: ["#87CEEB", "azzurro"], celesti: ["#87CEEB", "azzurro"], turchese: ["#40E0D0", "azzurro"],
  "carta da zucchero": ["#8CA9C9", "azzurro"], avion: ["#7EA6CE", "azzurro"], acquamarina: ["#7FD8D0", "azzurro"],
  ottanio: ["#1F6F7A", "azzurro"], petrolio: ["#1B5E62", "azzurro"],
  // blu
  blu: ["#1E40AF", "blu"], "blu chiaro": ["#5C8DD6", "blu"], "blu navy": ["#1F2A44", "blu"], navy: ["#1F2A44", "blu"],
  "blu notte": ["#191970", "blu"], "blu elettrico": ["#2F4BFF", "blu"], "blu royal": ["#2A52BE", "blu"],
  cobalto: ["#1F4AA8", "blu"], bluette: ["#3B5FC0", "blu"], zaffiro: ["#0F52BA", "blu"], jeans: ["#5D7EA7", "blu"], denim: ["#5D7EA7", "blu"],
  indaco: ["#4B0082", "blu"],
  // viola
  viola: ["#8E24AA", "viola"], lilla: ["#C8A2C8", "viola"], lavanda: ["#B57EDC", "viola"], glicine: ["#C9A0DC", "viola"],
  malva: ["#B784A7", "viola"], prugna: ["#7D3C62", "viola"], melanzana: ["#4E2A4F", "viola"],
  // oro e argento
  oro: ["#D4AF37", "oro"], dorato: ["#D4AF37", "oro"], dorata: ["#D4AF37", "oro"], argento: ["#C0C0C0", "oro"],
  argentato: ["#C0C0C0", "oro"], bronzo: ["#A97142", "oro"],
};

const RAINBOW = new Set(["multicolore", "multicolor", "arcobaleno", "misto", "mix"]);
const RAINBOW_CSS = FAMILIES.find((f) => f.key === "multicolore")!.swatch;

/**
 * Parole che nelle descrizioni hanno spesso un altro significato ("filato naturale",
 * "misto cotone", "taglia a pesca"…): valgono come colore solo nell'opzione "Colore".
 */
const AMBIGUOUS_IN_TEXT = new Set([
  "naturale", "corda", "misto", "mix", "latte", "caffe", "fumo", "pesca", "salvia", "menta", "oliva",
  "prugna", "limone", "zucca", "ciliegia", "lampone", "vaniglia", "ghiaccio", "perla", "cappuccino",
  "moka", "jeans", "denim", "militare", "bottiglia", "rame", "oro", "crema", "lime", "navy", "avion",
]);

function normalize(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ");
}

/** L'opzione è un colore? ("Colore", "Colori", "Colore del filato"…) */
export function isColorOption(name: string): boolean {
  return normalize(name).startsWith("color");
}

interface Match {
  name: string;
  hex: string;
  family: ColorFamily;
  start: number;
  end: number;
}

/** Tutti i colori trovati in un testo, dal nome più lungo ("verde militare" prima di "verde"). */
function findColors(text: string, skip?: Set<string>): Match[] {
  const words = normalize(text).split(/[^a-z0-9#]+/).filter(Boolean);
  const used = new Array(words.length).fill(false);
  const found: Match[] = [];
  for (let n = 3; n > 0; n--) {
    for (let i = 0; i + n <= words.length; i++) {
      if (used.slice(i, i + n).some(Boolean)) continue;
      const name = words.slice(i, i + n).join(" ");
      if (skip?.has(name)) continue;
      const hit = RAINBOW.has(name) ? ([RAINBOW_CSS, "multicolore"] as const) : PALETTE[name];
      if (!hit) continue;
      for (let k = i; k < i + n; k++) used[k] = true;
      found.push({ name, hex: hit[0], family: hit[1], start: i, end: i + n });
    }
  }
  return found.sort((a, b) => a.start - b.start);
}

/** Schiarisce o scurisce una tinta (#RRGGBB) verso il bianco o il nero. */
function shade(hex: string, amount: number): string {
  if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return hex;
  const target = amount > 0 ? 255 : 0;
  const k = Math.abs(amount);
  const ch = (i: number) => {
    const v = parseInt(hex.slice(i, i + 2), 16);
    return Math.round(v + (target - v) * k).toString(16).padStart(2, "0");
  };
  return `#${ch(1)}${ch(3)}${ch(5)}`;
}

/** Valore CSS per lo sfondo del pallino, oppure null se il colore non è riconosciuto. */
export function colorFor(value: string): string | null {
  const v = normalize(value);
  if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(v)) return v;
  const [first] = findColors(v);
  if (!first) return null;
  // "chiaro" / "scuro" dopo un colore che non li contiene già: tinta un po' più chiara o scura
  const words = v.split(" ");
  if (words.includes("chiaro") || words.includes("chiara")) return shade(first.hex, first.name.includes("chiar") ? 0 : 0.4);
  if (words.includes("scuro") || words.includes("scura")) return shade(first.hex, first.name.includes("scur") ? 0 : -0.35);
  return first.hex;
}

/** Famiglie di un valore dell'opzione "Colore": "Nero e oro" -> nero e oro. */
export function colorFamilies(value: string): ColorFamily[] {
  return [...new Set(findColors(value).map((m) => m.family))];
}

/** Famiglie dei colori scritti in un testo libero (titolo, descrizione), senza le parole ambigue. */
export function familiesInText(text: string): ColorFamily[] {
  return [...new Set(findColors(text, AMBIGUOUS_IN_TEXT).map((m) => m.family))];
}

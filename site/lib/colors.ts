// Colori riconosciuti dal nome, per il pallino accanto alle scelte di colore.
// La stessa lista è nell'app admin (admin/lib/color_names.dart):
// se ne aggiungi uno qui, aggiungilo anche lì.
const PALETTE: Record<string, string> = {
  bianco: "#FFFFFF", bianca: "#FFFFFF", panna: "#FFF5D6", avorio: "#FFFFF0",
  crema: "#FFF5D6", beige: "#E8D9B5", sabbia: "#D8C49F", tortora: "#A89F91",
  grigio: "#9E9E9E", grigia: "#9E9E9E", "grigio chiaro": "#D3D3D3", "grigio scuro": "#555555",
  antracite: "#3B3B3B", argento: "#C0C0C0", nero: "#111111", nera: "#111111",
  marrone: "#7B4B2A", cammello: "#C19A6B", cioccolato: "#5C3317", cuoio: "#8B5A2B",
  rosso: "#D32F2F", rossa: "#D32F2F", bordeaux: "#800020", bordo: "#800020",
  corallo: "#FF7F50", salmone: "#FA8072", pesca: "#FFCBA4",
  arancione: "#FB8C00", arancio: "#FB8C00", senape: "#E1AD01", ocra: "#CC7722",
  giallo: "#FDD835", gialla: "#FDD835", oro: "#D4AF37", dorato: "#D4AF37",
  verde: "#43A047", "verde chiaro": "#9CCC65", "verde scuro": "#1B5E20", "verde salvia": "#9CAF88",
  salvia: "#9CAF88", "verde acqua": "#66CDAA", "verde bosco": "#2E5E3A", "verde militare": "#4B5320",
  "verde oliva": "#808000", oliva: "#808000", menta: "#98E6B0", petrolio: "#1B5E62",
  turchese: "#40E0D0", azzurro: "#64B5F6", azzurra: "#64B5F6", celeste: "#87CEEB",
  blu: "#1E40AF", "blu chiaro": "#5C8DD6", "blu navy": "#1F2A44", navy: "#1F2A44",
  "blu notte": "#191970", jeans: "#5D7EA7", denim: "#5D7EA7", indaco: "#4B0082",
  viola: "#8E24AA", lilla: "#C8A2C8", lavanda: "#B57EDC", glicine: "#C9A0DC",
  prugna: "#7D3C62", fucsia: "#E91E63", magenta: "#D81B60", rosa: "#F48FB1",
  "rosa chiaro": "#F8BBD0", "rosa antico": "#C08081", "rosa cipria": "#E8B4B8", cipria: "#E8B4B8",
};

const RAINBOW = new Set(["multicolore", "multicolor", "arcobaleno", "misto", "mix"]);
const RAINBOW_CSS = "conic-gradient(#E53935, #FB8C00, #FDD835, #43A047, #1E88E5, #8E24AA, #E53935)";

function normalize(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ");
}

/** L'opzione è un colore? ("Colore", "Colori", "Colore del filato"…) */
export function isColorOption(name: string): boolean {
  return normalize(name).startsWith("color");
}

/** Valore CSS per lo sfondo del pallino, oppure null se il colore non è riconosciuto. */
export function colorFor(value: string): string | null {
  const v = normalize(value);
  if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(v)) return v;
  const words = v.split(" ");
  for (let n = words.length; n > 0; n--) {
    const key = words.slice(0, n).join(" ");
    if (RAINBOW.has(key)) return RAINBOW_CSS;
    if (PALETTE[key]) return PALETTE[key];
  }
  return null;
}

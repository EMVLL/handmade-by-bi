import 'dart:ui';

import 'utils.dart';

/// Colori riconosciuti dal nome, per mostrare il pallino accanto alla scelta.
/// La stessa lista è nel sito (site/lib/colors.ts): se ne aggiungi uno qui,
/// aggiungilo anche lì.
const _palette = <String, int>{
  'bianco': 0xFFFFFFFF, 'bianca': 0xFFFFFFFF, 'bianchi': 0xFFFFFFFF, 'bianche': 0xFFFFFFFF,
  'panna': 0xFFFFF5D6, 'bianco panna': 0xFFFFF5D6, 'avorio': 0xFFFFFFF0, 'crema': 0xFFFFF5D6,
  'latte': 0xFFFDFBF5, 'vaniglia': 0xFFF3E5AB, 'ecru': 0xFFF0E6D2, 'ghiaccio': 0xFFE8F1F5,
  'beige': 0xFFE8D9B5, 'sabbia': 0xFFD8C49F, 'tortora': 0xFFA89F91, 'taupe': 0xFFA89F91,
  'visone': 0xFFA28F7D, 'corda': 0xFFC9B99A, 'naturale': 0xFFE6D8BD, 'cammello': 0xFFC19A6B,
  'marrone': 0xFF7B4B2A, 'marroni': 0xFF7B4B2A, 'cioccolato': 0xFF5C3317, 'cuoio': 0xFF8B5A2B,
  'tabacco': 0xFF71482A, 'cognac': 0xFF9A463D, 'nocciola': 0xFFA0785A, 'caramello': 0xFFAF6E3D,
  'cappuccino': 0xFFA47551, 'caffe': 0xFF6F4E37, 'moka': 0xFF5E4334, 'testa di moro': 0xFF4A2C21,
  'grigio': 0xFF9E9E9E, 'grigia': 0xFF9E9E9E, 'grigi': 0xFF9E9E9E, 'grigie': 0xFF9E9E9E,
  'grigio chiaro': 0xFFD3D3D3, 'grigio scuro': 0xFF555555, 'grigio perla': 0xFFD9D9D6, 'perla': 0xFFE2DFD2,
  'grigio melange': 0xFFA9A9A9, 'fumo': 0xFF848884, 'antracite': 0xFF3B3B3B, 'nero': 0xFF111111,
  'nera': 0xFF111111, 'neri': 0xFF111111, 'nere': 0xFF111111, 'rosso': 0xFFD32F2F, 'rossa': 0xFFD32F2F,
  'rossi': 0xFFD32F2F, 'rosse': 0xFFD32F2F, 'rosso fuoco': 0xFFE32B1E, 'rosso ruggine': 0xFFA0401E,
  'ciliegia': 0xFFB11E31, 'mattone': 0xFFA63A2B, 'vinaccia': 0xFF6E1E2E, 'bordeaux': 0xFF800020,
  'bordo': 0xFF800020, 'rosa': 0xFFF48FB1, 'rosa chiaro': 0xFFF8BBD0, 'rosa antico': 0xFFC08081,
  'rosa cipria': 0xFFE8B4B8, 'cipria': 0xFFE8B4B8, 'rosa baby': 0xFFF8C8DC, 'rosa shocking': 0xFFFC0FC0,
  'rosa pesca': 0xFFF6B49F, 'fucsia': 0xFFE91E63, 'magenta': 0xFFD81B60, 'ciclamino': 0xFFD62D7F,
  'lampone': 0xFFC72C5B, 'salmone': 0xFFFA8072, 'corallo': 0xFFFF7F50, 'arancione': 0xFFFB8C00,
  'arancio': 0xFFFB8C00, 'arancioni': 0xFFFB8C00, 'pesca': 0xFFFFCBA4, 'albicocca': 0xFFF7A25B,
  'mandarino': 0xFFF28500, 'zucca': 0xFFE8761B, 'terracotta': 0xFFC2603F, 'ruggine': 0xFFB7410E,
  'rame': 0xFFB87333, 'giallo': 0xFFFDD835, 'gialla': 0xFFFDD835, 'gialli': 0xFFFDD835, 'gialle': 0xFFFDD835,
  'limone': 0xFFF7E34B, 'senape': 0xFFE1AD01, 'ocra': 0xFFCC7722, 'giallo ocra': 0xFFCC9922,
  'verde': 0xFF43A047, 'verdi': 0xFF43A047, 'verde chiaro': 0xFF9CCC65, 'verde scuro': 0xFF1B5E20,
  'verde salvia': 0xFF9CAF88, 'salvia': 0xFF9CAF88, 'verde acqua': 0xFF66CDAA, 'verde bosco': 0xFF2E5E3A,
  'verde militare': 0xFF4B5320, 'militare': 0xFF4B5320, 'verde oliva': 0xFF808000, 'oliva': 0xFF808000,
  'menta': 0xFF98E6B0, 'verde bottiglia': 0xFF09532F, 'bottiglia': 0xFF09532F, 'smeraldo': 0xFF1E8E5A,
  'verde pistacchio': 0xFF93C572, 'pistacchio': 0xFF93C572, 'verde mela': 0xFF8DB600, 'lime': 0xFFB5D33D,
  'verde lime': 0xFFB5D33D, 'verde petrolio': 0xFF1B5E62, 'azzurro': 0xFF64B5F6, 'azzurra': 0xFF64B5F6,
  'azzurri': 0xFF64B5F6, 'azzurre': 0xFF64B5F6, 'celeste': 0xFF87CEEB, 'celesti': 0xFF87CEEB,
  'turchese': 0xFF40E0D0, 'carta da zucchero': 0xFF8CA9C9, 'avion': 0xFF7EA6CE, 'acquamarina': 0xFF7FD8D0,
  'ottanio': 0xFF1F6F7A, 'petrolio': 0xFF1B5E62, 'blu': 0xFF1E40AF, 'blu chiaro': 0xFF5C8DD6,
  'blu navy': 0xFF1F2A44, 'navy': 0xFF1F2A44, 'blu notte': 0xFF191970, 'blu elettrico': 0xFF2F4BFF,
  'blu royal': 0xFF2A52BE, 'cobalto': 0xFF1F4AA8, 'bluette': 0xFF3B5FC0, 'zaffiro': 0xFF0F52BA,
  'jeans': 0xFF5D7EA7, 'denim': 0xFF5D7EA7, 'indaco': 0xFF4B0082, 'viola': 0xFF8E24AA, 'lilla': 0xFFC8A2C8,
  'lavanda': 0xFFB57EDC, 'glicine': 0xFFC9A0DC, 'malva': 0xFFB784A7, 'prugna': 0xFF7D3C62,
  'melanzana': 0xFF4E2A4F, 'oro': 0xFFD4AF37, 'dorato': 0xFFD4AF37, 'dorata': 0xFFD4AF37,
  'argento': 0xFFC0C0C0, 'argentato': 0xFFC0C0C0, 'bronzo': 0xFFA97142,
};

const _rainbow = {'multicolore', 'multicolor', 'arcobaleno', 'misto', 'mix'};

/// Un colore riconosciuto: tinta unita oppure multicolore.
class NamedColor {
  const NamedColor.solid(Color this.color) : rainbow = false;
  const NamedColor.rainbow()
      : color = null,
        rainbow = true;

  final Color? color;
  final bool rainbow;
}

/// L'opzione è un colore? ("Colore", "Colori", "Colore del filato"…)
bool isColorOption(String name) => removeAccents(name).trim().startsWith('color');

/// "Verde salvia" -> pallino verde salvia; "#FF0000" -> rosso; sconosciuto -> null.
NamedColor? colorForName(String value) {
  final normalized = removeAccents(value).trim().replaceAll(RegExp(r'\s+'), ' ');
  final hex = RegExp(r'^#([0-9a-f]{3}|[0-9a-f]{6})$').firstMatch(normalized);
  if (hex != null) {
    var digits = hex[1]!;
    if (digits.length == 3) digits = digits.split('').map((c) => '$c$c').join();
    return NamedColor.solid(Color(int.parse('FF$digits', radix: 16)));
  }
  // Il nome più lungo, in qualsiasi punto: "Ruggine scuro" -> ruggine, "Rosso ruggine" -> rosso ruggine
  final words = normalized.split(RegExp(r'[^a-z0-9#]+')).where((w) => w.isNotEmpty).toList();
  for (var n = words.length < 3 ? words.length : 3; n > 0; n--) {
    for (var i = 0; i + n <= words.length; i++) {
      final key = words.sublist(i, i + n).join(' ');
      if (_rainbow.contains(key)) return const NamedColor.rainbow();
      final argb = _palette[key];
      if (argb != null) return NamedColor.solid(Color(argb));
    }
  }
  return null;
}

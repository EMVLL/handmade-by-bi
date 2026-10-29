import 'dart:ui';

import 'utils.dart';

/// Colori riconosciuti dal nome, per mostrare il pallino accanto alla scelta.
/// La stessa lista è nel sito (site/lib/colors.ts): se ne aggiungi uno qui,
/// aggiungilo anche lì.
const _palette = <String, int>{
  'bianco': 0xFFFFFFFF, 'bianca': 0xFFFFFFFF, 'panna': 0xFFFFF5D6, 'avorio': 0xFFFFFFF0,
  'crema': 0xFFFFF5D6, 'beige': 0xFFE8D9B5, 'sabbia': 0xFFD8C49F, 'tortora': 0xFFA89F91,
  'grigio': 0xFF9E9E9E, 'grigia': 0xFF9E9E9E, 'grigio chiaro': 0xFFD3D3D3, 'grigio scuro': 0xFF555555,
  'antracite': 0xFF3B3B3B, 'argento': 0xFFC0C0C0, 'nero': 0xFF111111, 'nera': 0xFF111111,
  'marrone': 0xFF7B4B2A, 'cammello': 0xFFC19A6B, 'cioccolato': 0xFF5C3317, 'cuoio': 0xFF8B5A2B,
  'rosso': 0xFFD32F2F, 'rossa': 0xFFD32F2F, 'bordeaux': 0xFF800020, 'bordo': 0xFF800020,
  'corallo': 0xFFFF7F50, 'salmone': 0xFFFA8072, 'pesca': 0xFFFFCBA4,
  'arancione': 0xFFFB8C00, 'arancio': 0xFFFB8C00, 'senape': 0xFFE1AD01, 'ocra': 0xFFCC7722,
  'giallo': 0xFFFDD835, 'gialla': 0xFFFDD835, 'oro': 0xFFD4AF37, 'dorato': 0xFFD4AF37,
  'verde': 0xFF43A047, 'verde chiaro': 0xFF9CCC65, 'verde scuro': 0xFF1B5E20, 'verde salvia': 0xFF9CAF88,
  'salvia': 0xFF9CAF88, 'verde acqua': 0xFF66CDAA, 'verde bosco': 0xFF2E5E3A, 'verde militare': 0xFF4B5320,
  'verde oliva': 0xFF808000, 'oliva': 0xFF808000, 'menta': 0xFF98E6B0, 'petrolio': 0xFF1B5E62,
  'turchese': 0xFF40E0D0, 'azzurro': 0xFF64B5F6, 'azzurra': 0xFF64B5F6, 'celeste': 0xFF87CEEB,
  'blu': 0xFF1E40AF, 'blu chiaro': 0xFF5C8DD6, 'blu navy': 0xFF1F2A44, 'navy': 0xFF1F2A44,
  'blu notte': 0xFF191970, 'jeans': 0xFF5D7EA7, 'denim': 0xFF5D7EA7, 'indaco': 0xFF4B0082,
  'viola': 0xFF8E24AA, 'lilla': 0xFFC8A2C8, 'lavanda': 0xFFB57EDC, 'glicine': 0xFFC9A0DC,
  'prugna': 0xFF7D3C62, 'fucsia': 0xFFE91E63, 'magenta': 0xFFD81B60, 'rosa': 0xFFF48FB1,
  'rosa chiaro': 0xFFF8BBD0, 'rosa antico': 0xFFC08081, 'rosa cipria': 0xFFE8B4B8, 'cipria': 0xFFE8B4B8,
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
  final words = normalized.split(' ');
  for (var n = words.length; n > 0; n--) {
    final key = words.take(n).join(' ');
    if (_rainbow.contains(key)) return const NamedColor.rainbow();
    final argb = _palette[key];
    if (argb != null) return NamedColor.solid(Color(argb));
  }
  return null;
}

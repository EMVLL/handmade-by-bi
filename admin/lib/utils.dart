import 'dart:math';
import 'dart:typed_data';

final _random = Random.secure();

/// 35 -> "35", 12.5 -> "12,50"
String formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceAll('.', ',');

/// Prezzo leggibile, oppure "su richiesta".
String formatPrice(double? value) =>
    value == null ? 'Prezzo su richiesta' : '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

/// Accetta "25", "12,50", "12.50", "€ 12,50". Restituisce null se vuoto o non valido.
double? parsePrice(String text) {
  final cleaned = text.replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return (value * 100).roundToDouble() / 100;
}

/// "Verde, Rosa ,, Azzurro" -> ["Verde", "Rosa", "Azzurro"]
List<String> splitValues(String text) =>
    text.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

/// "Borsa Margherita – Rosa!" -> "borsa-margherita-rosa"
String slugify(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  var slug = buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > 70) {
    slug = slug.substring(0, 70).replaceAll(RegExp(r'-+$'), '');
  }
  return slug.isEmpty ? 'pezzo' : slug;
}

String randomHex(int length) =>
    List.generate(length, (_) => _random.nextInt(16).toRadixString(16)).join();

String randomDigits(int length) =>
    List.generate(length, (_) => _random.nextInt(10).toString()).join();

/// Riconosce il formato reale dell'immagine dai primi byte.
/// Solo JPEG, PNG e WebP sono accettati dal bucket delle foto.
String? detectImageMime(Uint8List bytes) {
  if (bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length > 8 &&
      bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length > 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// Percorso univoco nel bucket "media" per una nuova foto.
String newPhotoPath(String mime) {
  final ext = switch (mime) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };
  return 'products/${DateTime.now().millisecondsSinceEpoch}-${randomHex(6)}.$ext';
}

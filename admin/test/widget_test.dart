import 'dart:typed_data';

import 'package:admin/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('slugify crea indirizzi puliti', () {
    expect(slugify('Borsa Margherita – Rosa!'), 'borsa-margherita-rosa');
    expect(slugify('Però è già così'), 'pero-e-gia-cosi');
    expect(slugify('!!!'), 'pezzo');
  });

  test('parsePrice accetta virgola e punto', () {
    expect(parsePrice('12,50'), 12.5);
    expect(parsePrice('€ 25'), 25);
    expect(parsePrice(''), isNull);
    expect(parsePrice('abc'), isNull);
  });

  test('detectImageMime riconosce JPEG', () {
    expect(detectImageMime(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    expect(detectImageMime(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}

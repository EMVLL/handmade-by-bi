import 'dart:typed_data';

import 'package:admin/color_names.dart';
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

  test('splitChoices tiene insieme le mezze taglie', () {
    expect(splitChoices('25,5'), ['25,5']);
    expect(splitChoices('S, M, L'), ['S', 'M', 'L']);
  });

  test('colori riconosciuti dal nome', () {
    expect(isColorOption('Colore'), isTrue);
    expect(isColorOption('Taglia'), isFalse);
    expect(colorForName('Rosa antico'), isNotNull);
    expect(colorForName('Fantasia'), isNull);
  });

  test('detectImageMime riconosce JPEG', () {
    expect(detectImageMime(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    expect(detectImageMime(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}

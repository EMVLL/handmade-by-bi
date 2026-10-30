import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Caratteri del sito: gli stessi nomi usati nel tema e nelle sezioni.
const headingFonts = ['Fraunces', 'Playfair Display', 'Lora', 'DM Serif Display', 'Nunito', 'Quicksand'];
const bodyFonts = ['Nunito', 'Quicksand', 'DM Sans', 'Lato', 'Lora'];
const allSiteFonts = [
  'Fraunces', 'Playfair Display', 'Lora', 'DM Serif Display', 'Nunito', 'Quicksand', 'DM Sans', 'Lato',
];

final _loading = <String, Future<bool>>{};

String _family(String font) => 'preview-$font';

/// Carica (una volta sola, quando serve) il carattere per l'anteprima.
Future<bool> loadPreviewFont(String font) => _loading.putIfAbsent(font, () async {
      try {
        final loader = FontLoader(_family(font))
          ..addFont(rootBundle.load('assets/fonts/${font.replaceAll(' ', '')}.ttf'));
        await loader.load();
        return true;
      } catch (_) {
        return false; // senza anteprima si vede il carattere normale dell'app
      }
    });

/// Testo scritto con uno dei caratteri del sito.
class FontPreviewText extends StatelessWidget {
  const FontPreviewText(this.text, {super.key, required this.font, this.style});

  final String text;
  final String font;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: loadPreviewFont(font),
      builder: (context, snapshot) {
        final ready = snapshot.data == true;
        return Text(text, style: (style ?? const TextStyle()).copyWith(fontFamily: ready ? _family(font) : null));
      },
    );
  }
}

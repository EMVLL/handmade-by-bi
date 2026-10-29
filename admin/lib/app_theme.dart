import 'package:flutter/material.dart';

/// Colori dell'app admin: si cambiano solo qui.
///
/// Nota: i colori del SITO pubblico non sono qui, li sceglie Benedetta
/// (sono salvati nel tema su Supabase). Se cambi [primary] o [background],
/// aggiorna anche theme-color e background_color in web/index.html e
/// web/manifest.json, che colorano la barra dell'iPhone all'avvio.
abstract final class AppColors {
  /// Colore principale: da questo Flutter ricava tutta la palette.
  static const primary = Color(0xFFB5838D);

  /// Sfondo delle schermate.
  static const background = Color(0xFFFFF8F3);

  /// Fascia "Copertina" sopra la prima foto.
  static const photoLabelBackground = Color(0x8A000000);
  static const photoLabelText = Color(0xFFFFFFFF);

  /// Bordo dei pallini colorati (serve a vedere anche il bianco).
  static const swatchBorder = Color(0x33000000);

  /// Pallino "multicolore".
  static const rainbow = [
    Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047),
    Color(0xFF1E88E5), Color(0xFF8E24AA), Color(0xFFE53935),
  ];
}

/// Tema dell'app: forme e misure comuni, costruite sui colori di [AppColors].
abstract final class AppTheme {
  static const radius = 12.0;
  static const radiusSmall = 8.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      ),
    );
  }
}

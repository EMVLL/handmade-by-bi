import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../texts/app_texts.dart';

final _hexPattern = RegExp(r'^#[0-9a-fA-F]{6}$');

/// "#B5838D" -> Color
Color hexColor(String hex) => Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// Colori proposti (si può comunque scrivere un codice).
const sitePalette = [
  '#B5838D', '#E8B4B8', '#F48FB1', '#D81B60', '#C08081', '#800020',
  '#C0673E', '#FB8C00', '#F2A65A', '#D9A05B', '#C9A227', '#E1AD01',
  '#6D9773', '#7C9473', '#9CAF88', '#43A047', '#2E5E3A', '#66CDAA',
  '#3D7EA6', '#64B5F6', '#1E40AF', '#1F2A44', '#4F6D7A', '#8E7CC3',
  '#B57EDC', '#C8A2C8', '#8B5E3C', '#5C3317', '#3D3033', '#111111',
  '#FFFFFF', '#FFF8F3', '#FFFBF2', '#F7F5EE', '#FAF7FF', '#F5FAFC',
];

/// Finestra per scegliere un colore. Restituisce "#RRGGBB" o null se annullata.
Future<String?> showColorPicker(BuildContext context, {required String title, String? current}) {
  final hexController = TextEditingController(text: current ?? '');
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      String? error;
      return StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final hex in sitePalette)
                      InkWell(
                        onTap: () => Navigator.pop(context, hex),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: hexColor(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: current?.toUpperCase() == hex
                                  ? Theme.of(context).colorScheme.onSurface
                                  : AppColors.swatchBorder,
                              width: current?.toUpperCase() == hex ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hexController,
                        autocorrect: false,
                        decoration: InputDecoration(labelText: t.colorHex, errorText: error),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: FilledButton(
                        onPressed: () {
                          var hex = hexController.text.trim();
                          if (!hex.startsWith('#')) hex = '#$hex';
                          if (_hexPattern.hasMatch(hex)) {
                            Navigator.pop(context, hex.toUpperCase());
                          } else {
                            setSheet(() => error = t.colorHexInvalid);
                          }
                        },
                        child: Text(t.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

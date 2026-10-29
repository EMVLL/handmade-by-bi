import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../color_names.dart';

/// Pallino colorato accanto a una scelta di colore.
class ColorDot extends StatelessWidget {
  const ColorDot(this.named, {super.key, this.size = 16});

  final NamedColor named;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: named.color,
        gradient: named.rainbow ? const SweepGradient(colors: AppColors.rainbow) : null,
        border: Border.all(color: AppColors.swatchBorder),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Stile dei titoli dei riquadri: colore acceso e grassetto, uguale in tutta l'app.
TextStyle? sectionTitleStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(color: AppColors.sectionTitle, fontWeight: FontWeight.w700);

/// Cornice dei riquadri: fondo chiaro e bordo sottile, così ogni sezione
/// si distingue bene dalle altre.
class SectionFrame extends StatelessWidget {
  const SectionFrame({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(top: 16),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: margin,
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTheme.radius)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Riquadro di una sezione: titolo colorato, spiegazione facoltativa e,
/// dentro, solo i campi e gli interruttori che riguardano quella sezione.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.hint,
    required this.children,
    this.margin = const EdgeInsets.only(top: 16),
  });

  final String title;
  final String? hint;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return SectionFrame(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: sectionTitleStyle(context)),
            if (hint != null && hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(hint, style: Theme.of(context).textTheme.bodySmall),
              ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

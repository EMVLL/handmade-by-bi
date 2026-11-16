import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models.dart';
import '../texts/app_texts.dart';
import '../widgets/section_card.dart';

/// Scelta del centro di una foto: Benedetta tocca il pezzo e vede subito il quadrato
/// che comparirà nelle griglie e nel nastro del sito.
/// Restituisce il nuovo [PhotoFocus] con "Fatto"; tornando indietro non cambia nulla.
class PhotoFocusScreen extends StatefulWidget {
  const PhotoFocusScreen({super.key, required this.image, this.initial});

  final ImageProvider image;
  final PhotoFocus? initial;

  @override
  State<PhotoFocusScreen> createState() => _PhotoFocusScreenState();
}

class _PhotoFocusScreenState extends State<PhotoFocusScreen> {
  late PhotoFocus _focus = widget.initial ?? PhotoFocus.center;
  Size? _imageSize;
  bool _failed = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Servono le proporzioni della foto per disegnare il quadrato
    _stream?.removeListener(_listener!);
    _stream = widget.image.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble()));
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  /// Tocco in (dx, dy) sulla foto larga [w] e alta [h]: il quadrato si centra lì,
  /// senza uscire dalla foto. Il risultato è in percentuale, come object-position.
  void _tap(Offset p, double w, double h) {
    final side = w < h ? w : h;
    double pct(double tap, double length) {
      final free = length - side;
      if (free <= 0) return 50;
      final start = (tap - side / 2).clamp(0.0, free);
      return start / free * 100;
    }

    setState(() => _focus = PhotoFocus(pct(p.dx, w), pct(p.dy, h)));
  }

  Widget _picker(BoxConstraints c) {
    final size = _imageSize!;
    // La foto intera, il più grande possibile (al massimo 420 px di lato)
    final maxW = c.maxWidth;
    const maxH = 420.0;
    final scale = [maxW / size.width, maxH / size.height].reduce((a, b) => a < b ? a : b);
    final w = size.width * scale, h = size.height * scale;
    final side = w < h ? w : h;
    final left = (w - side) * _focus.x / 100;
    final top = (h - side) * _focus.y / 100;
    const shade = Color(0x73000000);

    return Center(
      child: GestureDetector(
        onTapDown: (d) => _tap(d.localPosition, w, h),
        onPanUpdate: (d) => _tap(d.localPosition, w, h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                Positioned.fill(child: Image(image: widget.image, fit: BoxFit.fill)),
                // Fuori dal quadrato: più scuro
                Positioned(left: 0, right: 0, top: 0, height: top, child: const ColoredBox(color: shade)),
                Positioned(left: 0, right: 0, top: top + side, bottom: 0, child: const ColoredBox(color: shade)),
                Positioned(left: 0, width: left, top: top, height: side, child: const ColoredBox(color: shade)),
                Positioned(left: left + side, right: 0, top: top, height: side, child: const ColoredBox(color: shade)),
                Positioned(
                  left: left,
                  top: top,
                  width: side,
                  height: side,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  ),
                ),
                // Il punto toccato
                Positioned(
                  left: left + side / 2 - 12,
                  top: top + side / 2 - 12,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.sectionTitle,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body;
    if (_failed) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(t.focusLoadError)));
    } else if (_imageSize == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            margin: EdgeInsets.zero,
            title: t.focusPickTitle,
            hint: t.focusPickHint,
            children: [LayoutBuilder(builder: (context, c) => _picker(c))],
          ),
          SectionCard(
            title: t.focusPreviewTitle,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: Image(image: widget.image, fit: BoxFit.cover, alignment: _focus.alignment),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(t.focusPreviewHint, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.focusTitle)),
      body: body,
      bottomNavigationBar: _imageSize == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _focus = PhotoFocus.center),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        child: Text(t.focusReset),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_focus),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        child: Text(t.focusDone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

import '../config.dart';
import '../draft.dart';
import '../media.dart';
import '../supa.dart';
import '../texts/app_texts.dart';

/// Scheda Anteprima: il sito con le modifiche non ancora pubblicate,
/// e i bottoni Pubblica / Annulla modifiche.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  String? _token;
  String? _error;
  bool _busy = false;
  int _reloads = 0;

  /// La pagina del sito mostrata nell'app (serve per bloccarne i tocchi).
  web.HTMLIFrameElement? _frame;

  /// Sul web una pagina incorporata "ruba" i tocchi anche ai dialoghi disegnati sopra:
  /// mentre un dialogo è aperto la rendiamo trasparente ai tocchi.
  Future<T?> _overFrame<T>(Future<T?> Function() open) async {
    _frame?.style.pointerEvents = 'none';
    try {
      return await open();
    } finally {
      _frame?.style.pointerEvents = 'auto';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
    refreshDraftStatus();
    draftRevision.addListener(_reload);
  }

  @override
  void dispose() {
    draftRevision.removeListener(_reload);
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final token = await supa.rpc('get_preview_token');
      if (mounted) setState(() => _token = token as String?);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  void _reload() {
    if (mounted) setState(() => _reloads++);
    refreshDraftStatus();
  }

  String get _url => '${Config.siteUrl}/anteprima?t=$_token&r=$_reloads-${DateTime.now().millisecondsSinceEpoch}';

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await publishSite(t.notePublish);
      await refreshDraftStatus();
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    final ok = await _overFrame(
      () => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.discardTitle),
          content: Text(t.discardBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.discard)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await supa.rpc('discard_draft');
      notifyDraftSaved();
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _statusBar() {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: draftChanged,
      builder: (context, changed, _) => Container(
        width: double.infinity,
        color: changed ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(changed ? Icons.edit_note : Icons.check_circle_outline),
                const SizedBox(width: 8),
                Text(changed ? t.previewChanges : t.previewNoChanges),
              ],
            ),
            if (changed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: _busy ? null : _discard, child: Text(t.discard)),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _publish,
                    icon: _busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.public),
                    label: Text(_busy ? t.publishing : t.publish),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)),
      );
    } else if (_token == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final url = _url;
      body = HtmlElementView.fromTagName(
        key: ValueKey(url),
        tagName: 'iframe',
        onElementCreated: (Object element) {
          final frame = element as web.HTMLIFrameElement;
          _frame = frame;
          frame.src = url;
          frame.style.border = 'none';
          frame.style.width = '100%';
          frame.style.height = '100%';
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.previewTitle2),
        actions: [
          IconButton(tooltip: t.reload, icon: const Icon(Icons.refresh), onPressed: _reload),
          if (_token != null)
            IconButton(
              tooltip: t.viewSite,
              icon: const Icon(Icons.open_in_new),
              onPressed: () => launchUrl(Uri.parse(_url)),
            ),
        ],
      ),
      body: Column(
        children: [
          _statusBar(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

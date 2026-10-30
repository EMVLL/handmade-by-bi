import 'package:flutter/material.dart';

import '../form_data.dart';
import '../models.dart';
import '../supa.dart';
import '../texts/app_texts.dart';
import '../widgets/schema_form.dart';
import 'block_edit_screen.dart';
import '../draft.dart';

IconData blockIcon(String type) => switch (type) {
      'hero' => Icons.web_asset,
      'category_menu' => Icons.category_outlined,
      'product_grid' => Icons.grid_view,
      'featured_product' => Icons.star_outline,
      'text' => Icons.notes,
      'gallery' => Icons.photo_library_outlined,
      'testimonials' => Icons.format_quote,
      'faq' => Icons.quiz_outlined,
      'contact' => Icons.chat_outlined,
      'banner' => Icons.campaign_outlined,
      'spacer' => Icons.space_bar,
      _ => Icons.widgets_outlined,
    };

/// Sezioni della pagina iniziale: ordine, visibilità, modifica, aggiunta.
/// Ogni modifica viene pubblicata subito.
class PageBlocksScreen extends StatefulWidget {
  const PageBlocksScreen({super.key});

  @override
  State<PageBlocksScreen> createState() => _PageBlocksScreenState();
}

class _PageBlocksScreenState extends State<PageBlocksScreen> {
  String? _pageId;
  List<PageBlock> _blocks = [];
  Map<String, BlockType> _types = {};
  SchemaFormData _data = const SchemaFormData();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await supa.from('pages').select('id').eq('is_home', true).single();
      final pageId = page['id'] as String;
      final results = await Future.wait([
        supa.from('blocks').select().eq('page_id', pageId).order('position', ascending: true),
        supa.from('block_types').select().eq('active', true).order('position', ascending: true),
      ]);
      final data = await loadFormData();
      if (!mounted) return;
      setState(() {
        _pageId = pageId;
        _blocks = results[0].map(PageBlock.fromMap).toList();
        _types = {for (final row in results[1]) row['type'] as String: BlockType.fromMap(row)};
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _label(PageBlock b) => _types[b.type]?.label ?? b.type;

  String _summary(PageBlock b) {
    for (final key in ['title', 'text', 'body']) {
      final value = b.props[key];
      if (value is String && value.trim().isNotEmpty) {
        final text = value.trim().replaceAll('\n', ' ');
        return text.length > 60 ? '${text.substring(0, 60)}…' : text;
      }
    }
    if (b.type == 'featured_product') {
      final product = _data.products.where((p) => p.id == b.props['product_id']).firstOrNull;
      if (product != null) return product.title;
    }
    return t.blockDescription(b.type);
  }

  /// Esegue una modifica (in bozza) e ricarica.
  Future<void> _run(String note, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      notifyDraftSaved();
      _snack(t.savedDraft);
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _move(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _blocks.length) return;
    final reordered = [..._blocks];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    await _run(t.noteSectionsOrder, () async {
      for (var i = 0; i < reordered.length; i++) {
        if (reordered[i].position != i) {
          await supa.from('blocks').update({'position': i}).eq('id', reordered[i].id);
        }
      }
    });
  }

  Future<void> _toggle(PageBlock b) =>
      _run(t.noteSectionVisibility(_label(b)), () => supa.from('blocks').update({'visible': !b.visible}).eq('id', b.id));

  Future<void> _delete(PageBlock b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.sectionDeleteTitle),
        content: Text(t.sectionDeleteBody(_label(b))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(t.noteSectionRemoved(_label(b)), () => supa.from('blocks').delete().eq('id', b.id));
  }

  Future<void> _edit(PageBlock b) async {
    final type = _types[b.type];
    if (type == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BlockEditScreen(block: b, blockType: type, data: _data)),
    );
    if (saved == true) {
      _snack(t.savedDraft);
      await _load();
    }
  }

  Future<void> _add() async {
    final type = await showModalBottomSheet<BlockType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(t.addSectionTitle, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final type in _types.values)
              ListTile(
                leading: Icon(blockIcon(type.type)),
                title: Text(type.label),
                subtitle: Text(t.blockDescription(type.type)),
                onTap: () => Navigator.pop(context, type),
              ),
          ],
        ),
      ),
    );
    if (type == null || _pageId == null) return;
    setState(() => _busy = true);
    try {
      final defaults = await supa.rpc('block_defaults', params: {'p_type': type.type});
      final position = _blocks.isEmpty ? 0 : _blocks.map((b) => b.position).reduce((a, b) => a > b ? a : b) + 1;
      final row = await supa
          .from('blocks')
          .insert({
            'page_id': _pageId,
            'type': type.type,
            'position': position,
            'props': Map<String, dynamic>.from((defaults as Map?) ?? const {}),
          })
          .select()
          .single();
      notifyDraftSaved();
      if (!mounted) return;
      setState(() => _busy = false);
      // Si apre subito il modulo della sezione nuova
      await _edit(PageBlock.fromMap(row));
      await _load();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _snack(friendlyError(e));
    }
  }

  Widget _tile(int i) {
    final b = _blocks[i];
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        leading: Icon(blockIcon(b.type), color: b.visible ? theme.colorScheme.primary : theme.disabledColor),
        title: Text(_label(b), style: b.visible ? null : TextStyle(color: theme.disabledColor)),
        subtitle: Text(b.visible ? _summary(b) : '${t.sectionHidden} · ${_summary(b)}', maxLines: 2),
        onTap: _busy ? null : () => _edit(b),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: t.categoryMoveUp,
              onPressed: i == 0 || _busy ? null : () => _move(i, -1),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: t.categoryMoveDown,
              onPressed: i == _blocks.length - 1 || _busy ? null : () => _move(i, 1),
              icon: const Icon(Icons.arrow_downward),
            ),
            PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (action) => switch (action) {
                'edit' => _edit(b),
                'toggle' => _toggle(b),
                _ => _delete(b),
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(t.sectionEdit)),
                PopupMenuItem(value: 'toggle', child: Text(b.visible ? t.sectionHide : t.sectionShow)),
                PopupMenuItem(value: 'delete', child: Text(t.delete)),
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
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: _load, child: Text(t.retry))),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(t.homeIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (var i = 0; i < _blocks.length; i++) _tile(i),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.homeTitle),
        bottom: _busy ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
      ),
      body: RefreshIndicator(onRefresh: _load, child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || _loading ? null : _add,
        icon: const Icon(Icons.add),
        label: Text(t.addSection),
      ),
    );
  }
}

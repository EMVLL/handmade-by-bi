import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_theme.dart';
import '../form_data.dart';
import '../models.dart';
import '../supa.dart';
import '../texts/app_texts.dart';
import '../utils.dart';
import 'block_edit_screen.dart';
import 'category_edit_screen.dart';

/// Categorie del negozio: crea, rinomina, ordina, elimina.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<ShopCategory> _items = [];
  Map<String, int> _counts = {};
  int _readyCount = 0;
  int _otherCount = 0;
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
      final results = await Future.wait([
        supa.from('collections').select().order('position', ascending: true).order('name', ascending: true),
        supa
            .from('products')
            .select('id, status, product_collections(collection_id)')
            .isFilter('deleted_at', null)
            .neq('status', 'nascosto'),
      ]);
      final counts = <String, int>{};
      var ready = 0;
      var other = 0;
      for (final row in results[1]) {
        final links = (row['product_collections'] as List?) ?? const [];
        if (row['status'] == 'disponibile') ready++;
        if (links.isEmpty) other++;
        for (final link in links) {
          final id = (link as Map)['collection_id'] as String;
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      if (!mounted) return;
      setState(() {
        _items = results[0].map(ShopCategory.fromMap).toList();
        _counts = counts;
        _readyCount = ready;
        _otherCount = other;
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

  /// Esegue una modifica, poi ricarica l'elenco.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _snack(t.categorySaved);
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<String?> _askName({String initial = '', required String title}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final name = controller.text.trim();
              if (name.isEmpty) {
                setDialogState(() => error = t.categoryNameRequired);
              } else if (name.length > 60) {
                setDialogState(() => error = t.maxChars(60));
              } else if (reservedCategorySlugs.contains(slugify(name))) {
                setDialogState(() => error = t.categoryReserved);
              } else {
                Navigator.pop(context, name);
              }
            }

            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(labelText: t.categoryNameField, errorText: error),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
                FilledButton(onPressed: submit, child: Text(t.save)),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _create() async {
    final name = await _askName(title: t.categoryNew);
    if (name == null) return;
    await _run(() async {
      final base = slugify(name);
      final next = _items.isEmpty ? 0 : _items.map((c) => c.position).reduce((a, b) => a > b ? a : b) + 1;
      for (var attempt = 0; attempt < 5; attempt++) {
        final slug = attempt == 0 ? base : '$base-${randomDigits(3)}';
        try {
          await supa.from('collections').insert({'slug': slug, 'name': name, 'position': next});
          return;
        } on PostgrestException catch (e) {
          if (e.code != '23505') rethrow; // indirizzo già usato: riprovo
        }
      }
      throw Exception(t.errSlug);
    });
  }

  Future<void> _openEdit(ShopCategory category) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CategoryEditScreen(category: category)),
    );
    if (saved == true) {
      _snack(t.categorySaved);
      await _load();
    }
  }

  /// Apre il modulo del "Menu categorie" della pagina iniziale.
  Future<void> _openMenuLook() async {
    try {
      final page = await supa.from('pages').select('id').eq('is_home', true).single();
      final rows = await supa.from('blocks').select().eq('page_id', page['id']).eq('type', 'category_menu').limit(1);
      if (rows.isEmpty) {
        _snack(t.categoryMenuMissing);
        return;
      }
      final type = await supa.from('block_types').select().eq('type', 'category_menu').single();
      final data = await loadFormData();
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => BlockEditScreen(block: PageBlock.fromMap(rows.first), blockType: BlockType.fromMap(type), data: data),
        ),
      );
      if (saved == true) _snack(t.savedDraft);
    } catch (e) {
      _snack(friendlyError(e));
    }
  }

  Widget _cover(ShopCategory c) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: SizedBox(
        width: 48,
        height: 48,
        child: c.coverPath == null
            ? ColoredBox(color: scheme.surfaceContainerHighest, child: const Icon(Icons.category_outlined))
            : Image.network(
                mediaUrl(c.coverPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }

  Future<void> _rename(ShopCategory category) async {
    final name = await _askName(initial: category.name, title: t.categoryRename);
    if (name == null || name == category.name) return;
    // Il nome cambia, l'indirizzo della pagina resta lo stesso.
    await _run(() => supa.from('collections').update({'name': name}).eq('id', category.id));
  }

  Future<void> _move(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _items.length) return;
    final reordered = [..._items];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    await _run(() async {
      for (var i = 0; i < reordered.length; i++) {
        if (reordered[i].position != i) {
          await supa.from('collections').update({'position': i}).eq('id', reordered[i].id);
        }
      }
    });
  }

  Future<void> _delete(ShopCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.categoryDeleteTitle),
        content: Text(t.categoryDeleteBody(category.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => supa.from('collections').delete().eq('id', category.id));
  }

  Widget _autoCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 20),
                const SizedBox(width: 8),
                Text(t.categoriesAutoTitle, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text('• ${t.categoriesAutoReady(_readyCount)}'),
            const SizedBox(height: 4),
            Text('• ${t.categoriesAutoOther(_otherCount)}'),
            const SizedBox(height: 8),
            Text(t.categoriesAutoNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: _load, child: Text(t.retry))),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _autoCard(),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(t.categoryMenuLook),
            subtitle: Text(t.categoryMenuLookHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _openMenuLook,
          ),
        ),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(t.categoriesEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ),
        for (var i = 0; i < _items.length; i++)
          ListTile(
            leading: _cover(_items[i]),
            title: Text(_items[i].name),
            subtitle: Text(t.productsCount(_counts[_items[i].id] ?? 0)),
            onTap: () => _openEdit(_items[i]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: t.categoryMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: i == 0 || _busy ? null : () => _move(i, -1),
                ),
                IconButton(
                  tooltip: t.categoryMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: i == _items.length - 1 || _busy ? null : () => _move(i, 1),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => switch (action) {
                    'edit' => _openEdit(_items[i]),
                    'rename' => _rename(_items[i]),
                    _ => _delete(_items[i]),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(t.sectionEdit)),
                    PopupMenuItem(value: 'rename', child: Text(t.categoryRename)),
                    PopupMenuItem(value: 'delete', child: Text(t.delete)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.categoriesTitle)),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _create,
        icon: const Icon(Icons.add),
        label: Text(t.categoryNew),
      ),
    );
  }
}

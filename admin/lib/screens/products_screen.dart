import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models.dart';
import '../supa.dart';
import 'product_edit_screen.dart';
import '../app_theme.dart';
import '../texts/app_texts.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _items = [];
  bool _loading = true;
  bool _trash = false;
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
      var query = supa.from('products').select();
      query = _trash ? query.not('deleted_at', 'is', null) : query.isFilter('deleted_at', null);
      final rows = await query
          .order('position', ascending: true)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _items = rows.map(Product.fromMap).toList();
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

  Future<void> _update(Product p, Map<String, dynamic> changes, String done) async {
    try {
      await supa.from('products').update(changes).eq('id', p.id);
      _snack(done);
      await _load();
    } catch (e) {
      _snack(friendlyError(e));
    }
  }

  Future<void> _deleteForever(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteForeverTitle),
        content: Text(t.deleteForeverBody(p.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await supa.from('products').delete().eq('id', p.id);
      if (p.photos.isNotEmpty) {
        try {
          await supa.storage.from('media').remove(p.photos);
        } catch (_) {
          // Le foto rimaste non danno fastidio: il pezzo è già eliminato.
        }
      }
      _snack(t.doneDeleted);
      await _load();
    } catch (e) {
      _snack(friendlyError(e));
    }
  }

  Future<void> _onAction(Product p, String action) async {
    switch (action) {
      case 'sold':
        await _update(p, {'status': 'venduto'}, t.doneSold);
      case 'available':
        await _update(p, {'status': 'disponibile'}, t.doneAvailable);
      case 'hide':
        await _update(p, {'status': 'nascosto'}, t.doneHidden);
      case 'trash':
        await _update(
          p,
          {'deleted_at': DateTime.now().toUtc().toIso8601String()},
          t.doneTrashed,
        );
      case 'restore':
        await _update(p, {'deleted_at': null}, t.doneRestored);
      case 'delete':
        await _deleteForever(p);
    }
  }

  Future<void> _open(Product? p) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)),
    );
    if (changed == true) {
      _snack(p == null ? t.doneAdded : t.doneSaved);
      await _load();
    }
  }

  List<PopupMenuEntry<String>> _menu(Product p) {
    if (_trash) {
      return [
        PopupMenuItem(value: 'restore', child: Text(t.actionRestore)),
        PopupMenuItem(value: 'delete', child: Text(t.actionDeleteForever)),
      ];
    }
    return [
      if (p.status != 'venduto') PopupMenuItem(value: 'sold', child: Text(t.actionSold)),
      if (p.status != 'disponibile')
        PopupMenuItem(value: 'available', child: Text(t.actionAvailable)),
      if (p.status != 'nascosto') PopupMenuItem(value: 'hide', child: Text(t.actionHide)),
      PopupMenuItem(value: 'trash', child: Text(t.actionTrash)),
    ];
  }

  Widget _thumb(Product p) {
    final cover = p.photos.isEmpty ? null : mediaUrl(p.photos.first);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: SizedBox(
        width: 56,
        height: 56,
        child: cover == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_outlined),
              )
            : Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined),
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
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(
            _trash ? t.emptyTrash : t.emptyProducts,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = _items[i];
        return ListTile(
          leading: _thumb(p),
          title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${t.price(p.price)} · ${t.statusLabel(p.status)}'),
          onTap: _trash ? null : () => _open(p),
          trailing: PopupMenuButton<String>(
            onSelected: (action) => _onAction(p, action),
            itemBuilder: (context) => _menu(p),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_trash ? t.trashTitle : t.productsTitle),
        actions: [
          IconButton(
            tooltip: t.viewSite,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => launchUrl(Uri.parse(Config.siteUrl)),
          ),
          IconButton(
            tooltip: _trash ? t.closeTrash : t.openTrash,
            icon: Icon(_trash ? Icons.close : Icons.delete_outline),
            onPressed: () {
              setState(() => _trash = !_trash);
              _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
      floatingActionButton: _trash
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _open(null),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(t.newProduct),
            ),
    );
  }
}

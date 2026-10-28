import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models.dart';
import '../supa.dart';
import '../utils.dart';
import 'product_edit_screen.dart';

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
        title: const Text('Eliminare per sempre?'),
        content: Text('"${p.title}" e le sue foto verranno cancellati definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
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
      _snack('Pezzo eliminato');
      await _load();
    } catch (e) {
      _snack(friendlyError(e));
    }
  }

  Future<void> _onAction(Product p, String action) async {
    switch (action) {
      case 'sold':
        await _update(p, {'status': 'venduto'}, 'Segnato come venduto');
      case 'available':
        await _update(p, {'status': 'disponibile'}, 'Di nuovo disponibile');
      case 'hide':
        await _update(p, {'status': 'nascosto'}, 'Nascosto dal sito');
      case 'trash':
        await _update(
          p,
          {'deleted_at': DateTime.now().toUtc().toIso8601String()},
          'Spostato nel cestino',
        );
      case 'restore':
        await _update(p, {'deleted_at': null}, 'Ripristinato');
      case 'delete':
        await _deleteForever(p);
    }
  }

  Future<void> _open(Product? p) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)),
    );
    if (changed == true) {
      _snack(p == null ? 'Pezzo aggiunto: sul sito entro un minuto' : 'Modifiche salvate');
      await _load();
    }
  }

  List<PopupMenuEntry<String>> _menu(Product p) {
    if (_trash) {
      return const [
        PopupMenuItem(value: 'restore', child: Text('Ripristina')),
        PopupMenuItem(value: 'delete', child: Text('Elimina per sempre')),
      ];
    }
    return [
      if (p.status != 'venduto') const PopupMenuItem(value: 'sold', child: Text('Segna come venduto')),
      if (p.status != 'disponibile')
        const PopupMenuItem(value: 'available', child: Text('Rimetti disponibile')),
      if (p.status != 'nascosto') const PopupMenuItem(value: 'hide', child: Text('Nascondi dal sito')),
      const PopupMenuItem(value: 'trash', child: Text('Sposta nel cestino')),
    ];
  }

  Widget _thumb(Product p) {
    final cover = p.photos.isEmpty ? null : mediaUrl(p.photos.first);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
          Center(child: FilledButton(onPressed: _load, child: const Text('Riprova'))),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(
            _trash ? 'Il cestino è vuoto.' : 'Nessun pezzo ancora.\nPremi "Nuovo pezzo" per aggiungere il primo!',
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
          subtitle: Text('${formatPrice(p.price)} · ${statusLabel(p.status)}'),
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
        title: Text(_trash ? 'Cestino' : 'I miei pezzi'),
        actions: [
          IconButton(
            tooltip: 'Vedi il sito',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => launchUrl(Uri.parse(Config.siteUrl)),
          ),
          IconButton(
            tooltip: _trash ? 'Torna ai pezzi' : 'Cestino',
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
              label: const Text('Nuovo pezzo'),
            ),
    );
  }
}

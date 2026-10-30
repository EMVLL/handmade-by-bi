import 'package:flutter/material.dart';

import '../models.dart';
import '../supa.dart';
import '../texts/app_texts.dart';
import '../widgets/schema_form.dart';

/// Nome, descrizione e copertina di una categoria.
class CategoryEditScreen extends StatefulWidget {
  const CategoryEditScreen({super.key, required this.category});

  final ShopCategory category;

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _values = {
    'name': widget.category.name,
    if (widget.category.description.isNotEmpty) 'description': widget.category.description,
    if (widget.category.coverPath != null) 'cover_path': widget.category.coverPath,
  };
  bool _saving = false;

  Map<String, dynamic> get _schema => {
        'required': ['name'],
        'x-order': ['name', 'cover_path', 'description'],
        'properties': {
          'name': {'type': 'string', 'maxLength': 60, 'x-label': t.categoryNameField},
          'cover_path': {'type': 'string', 'x-widget': 'image', 'x-label': t.categoryCover},
          'description': {'type': 'string', 'maxLength': 1000, 'x-widget': 'textarea', 'x-label': t.categoryDescription},
        },
      };

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      // Il nome cambia, l'indirizzo della pagina resta lo stesso.
      await supa.from('collections').update({
        'name': _values['name'],
        'description': (_values['description'] as String?) ?? '',
        'cover_path': _values['cover_path'],
      }).eq('id', widget.category.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.categoryEditTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SchemaForm(schema: _schema, values: _values),
            Text(t.categoryCoverHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.save),
          ),
        ),
      ),
    );
  }
}

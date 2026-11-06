import 'package:flutter/material.dart';

import '../supa.dart';
import '../texts/app_texts.dart';
import '../widgets/schema_form.dart';
import '../draft.dart';

/// Nome del negozio, logo e come appare su Google / nelle anteprime dei link.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final _form = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, dynamic> _header = {};
  Map<String, dynamic>? _headerSchema;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Lo stesso modulo automatico delle sezioni, con uno schema scritto qui.
  Map<String, dynamic> get _schema => {
        'required': ['site_name'],
        'x-order': ['site_name', 'logo_path', 'seo_title', 'seo_description', 'seo_image'],
        'x-groups': {
          'brand': {'label': t.identityBrandSection, 'hint': t.logoHint},
          'seo': {'label': t.seoSection},
        },
        'properties': {
          'site_name': {'type': 'string', 'maxLength': 60, 'x-label': t.siteName, 'x-group': 'brand'},
          'logo_path': {'type': 'string', 'x-widget': 'image', 'x-label': t.logo, 'x-group': 'brand'},
          'seo_title': {'type': 'string', 'maxLength': 70, 'x-label': t.seoTitle, 'x-group': 'seo'},
          'seo_description': {
            'type': 'string',
            'maxLength': 160,
            'x-widget': 'textarea',
            'x-label': t.seoDescription,
            'x-group': 'seo',
          },
          'seo_image': {'type': 'string', 'x-widget': 'image', 'x-label': t.seoImage, 'x-group': 'seo'},
        },
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await supa.from('site_settings').select('site_name, logo_path, seo, header').eq('id', 1).single();
      final schemaRow = await supa.from('setting_schemas').select('schema').eq('key', 'header').maybeSingle();
      _headerSchema = schemaRow == null ? null : Map<String, dynamic>.from(schemaRow['schema'] as Map);
      _header.addAll(Map<String, dynamic>.from((row['header'] as Map?) ?? const {}));
      // Valori di sempre: il logo si vede; il nome solo se non c'è un logo.
      _header.putIfAbsent('show_logo', () => true);
      _header.putIfAbsent('show_name', () => row['logo_path'] == null);
      final seo = Map<String, dynamic>.from((row['seo'] as Map?) ?? const {});
      void put(String key, dynamic value) {
        if (value is String && value.isNotEmpty) _values[key] = value;
      }

      put('site_name', row['site_name']);
      put('logo_path', row['logo_path']);
      put('seo_title', seo['title']);
      put('seo_description', seo['description']);
      put('seo_image', seo['image']);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.checkFields)));
      return;
    }
    setState(() => _saving = true);
    try {
      await supa.from('site_settings').update({
        'site_name': _values['site_name'],
        'logo_path': _values['logo_path'],
        if (_headerSchema != null) 'header': _header,
        'seo': {
          if (_values['seo_title'] != null) 'title': _values['seo_title'],
          if (_values['seo_description'] != null) 'description': _values['seo_description'],
          if (_values['seo_image'] != null) 'image': _values['seo_image'],
        },
      }).eq('id', 1);
      notifyDraftSaved();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    } else {
      body = Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SchemaForm(schema: _schema, values: _values),
            if (_headerSchema != null) ...[
              const SizedBox(height: 16),
              SchemaForm(
                schema: _headerSchema!,
                values: _header,
                title: t.headerSection,
                hint: t.headerHint,
              ),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.identityTitle)),
      body: body,
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
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

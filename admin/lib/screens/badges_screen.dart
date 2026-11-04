import 'package:flutter/material.dart';

import '../draft.dart';
import '../supa.dart';
import '../texts/app_texts.dart';
import '../widgets/schema_form.dart';

/// Etichette sulle foto dei pezzi: il modulo nasce dallo schema "badges" del database.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _form = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  Map<String, dynamic>? _schema;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await supa.from('site_settings').select('badges').eq('id', 1).single();
      final schemaRow = await supa.from('setting_schemas').select('schema').eq('key', 'badges').single();
      _values.addAll(Map<String, dynamic>.from((row['badges'] as Map?) ?? const {}));
      if (!mounted) return;
      setState(() {
        _schema = Map<String, dynamic>.from(schemaRow['schema'] as Map);
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

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.checkFields)));
      return;
    }
    setState(() => _saving = true);
    try {
      await supa.from('site_settings').update({'badges': _values}).eq('id', 1);
      notifyDraftSaved();
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
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null || _schema == null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? '')));
    } else {
      body = Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(t.badgesHint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            SchemaForm(schema: _schema!, values: _values),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.badgesTitle)),
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

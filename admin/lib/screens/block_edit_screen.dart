import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../form_data.dart';
import '../models.dart';
import '../supa.dart';
import '../texts/app_texts.dart';
import '../widgets/schema_form.dart';
import '../draft.dart';

/// Modifica di una sezione: il modulo nasce dallo schema del database.
class BlockEditScreen extends StatefulWidget {
  const BlockEditScreen({super.key, required this.block, required this.blockType, required this.data});

  final PageBlock block;
  final BlockType blockType;
  final SchemaFormData data;

  @override
  State<BlockEditScreen> createState() => _BlockEditScreenState();
}

class _BlockEditScreenState extends State<BlockEditScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _values = deepCopy(widget.block.props);
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    if (!(_form.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.checkFields)));
      return;
    }
    setState(() => _saving = true);
    try {
      await supa.from('blocks').update({'props': _values}).eq('id', widget.block.id);
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
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.blockType.label)),
        body: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(t.blockDescription(widget.blockType.type), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                SchemaForm(schema: widget.blockType.schema, values: _values, data: widget.data),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16 + AppTheme.badgeSpace),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.save),
            ),
          ),
        ),
      ),
    );
  }
}

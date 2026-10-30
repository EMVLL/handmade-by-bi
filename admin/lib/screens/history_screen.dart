import 'package:flutter/material.dart';

import '../supa.dart';
import '../texts/app_texts.dart';
import '../draft.dart';

String _when(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Versioni pubblicate del sito: si torna indietro con un tocco.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _versions = [];
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
      final rows = await supa
          .from('site_versions')
          .select('id, note, is_live, published_at')
          .order('id', ascending: false)
          .limit(50);
      if (!mounted) return;
      setState(() {
        _versions = rows;
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

  Future<void> _restore(Map<String, dynamic> version) async {
    final when = _when(version['published_at'] as String);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.historyRestoreTitle),
        content: Text(t.historyRestoreBody(when)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.historyRestore)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await supa.rpc('load_version_to_draft', params: {'p_version_id': version['id']});
      notifyDraftSaved();
      if (mounted) Navigator.of(context).pop(true);
      return;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _load();
      }
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
      body = ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(t.historyIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final v in _versions)
            ListTile(
              leading: Icon(v['is_live'] == true ? Icons.public : Icons.history),
              title: Text((v['note'] as String?) ?? '—'),
              subtitle: Text(_when(v['published_at'] as String)),
              trailing: v['is_live'] == true
                  ? Chip(label: Text(t.historyLive))
                  : const Icon(Icons.chevron_right),
              onTap: v['is_live'] == true || _busy ? null : () => _restore(v),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.historyTitle),
        bottom: _busy ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
      ),
      body: RefreshIndicator(onRefresh: _load, child: body),
    );
  }
}

import 'package:flutter/material.dart';

import '../supa.dart';
import '../texts/app_texts.dart';

final _phonePattern = RegExp(r'^[1-9][0-9]{7,14}$');
final _templatePattern = RegExp(r'^([^{}]|\{(prodotto|prezzo|opzione|link)\})*$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _vintedPattern = RegExp(r'^https://(www\.)?vinted\.[a-z.]+/');
final _instagramPattern = RegExp(r'^https://(www\.)?instagram\.com/');

/// Segnaposto dei messaggi: sono parole chiave lette dal sito e dal database,
/// quindi NON vanno tradotte.
const _placeholders = ['{prodotto}', '{prezzo}', '{opzione}', '{link}'];

/// "+39 333 123 4567" / "0039..." / "3331234567" -> "393331234567"
String normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 10 && digits.startsWith('3')) digits = '39$digits';
  return digits;
}

/// Canali con cui i clienti ordinano: WhatsApp, email, Vinted, Instagram.
class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  final _form = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _waOn = false;
  bool _mailOn = false;
  bool _vintedOn = false;
  bool _igOn = false;
  final _waNumber = TextEditingController();
  final _waTemplate = TextEditingController();
  final _mailAddress = TextEditingController();
  final _mailSubject = TextEditingController();
  final _mailBody = TextEditingController();
  final _vintedUrl = TextEditingController();
  final _igUrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_waNumber, _waTemplate, _mailAddress, _mailSubject, _mailBody, _vintedUrl, _igUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final row = await supa.from('site_settings').select('contacts').eq('id', 1).single();
      final contacts = Map<String, dynamic>.from((row['contacts'] as Map?) ?? const {});
      Map<String, dynamic> channel(String key) =>
          Map<String, dynamic>.from((contacts[key] as Map?) ?? const {});
      String text(Map<String, dynamic> c, String key) => (c[key] as String?) ?? '';

      final wa = channel('whatsapp');
      final mail = channel('email');
      final vinted = channel('vinted');
      final ig = channel('instagram');
      if (!mounted) return;
      setState(() {
        _waOn = wa['enabled'] == true;
        _waNumber.text = text(wa, 'number');
        _waTemplate.text = text(wa, 'template');
        _mailOn = mail['enabled'] == true;
        _mailAddress.text = text(mail, 'address');
        _mailSubject.text = text(mail, 'subject_template');
        _mailBody.text = text(mail, 'body_template');
        _vintedOn = vinted['enabled'] == true;
        _vintedUrl.text = text(vinted, 'profile_url');
        _igOn = ig['enabled'] == true;
        _igUrl.text = text(ig, 'profile_url');
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

  Map<String, dynamic> _channel(bool enabled, Map<String, String> fields) => {
        'enabled': enabled,
        for (final entry in fields.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      };

  Future<void> _save() async {
    if (_saving) return;
    if (!(_form.currentState?.validate() ?? false)) {
      _snack(t.checkFields);
      return;
    }
    setState(() => _saving = true);
    try {
      final contacts = {
        'whatsapp': _channel(_waOn, {
          'number': normalizePhone(_waNumber.text),
          'template': _waTemplate.text,
        }),
        'email': _channel(_mailOn, {
          'address': _mailAddress.text,
          'subject_template': _mailSubject.text,
          'body_template': _mailBody.text,
        }),
        'vinted': _channel(_vintedOn, {'profile_url': _vintedUrl.text}),
        'instagram': _channel(_igOn, {'profile_url': _igUrl.text}),
      };
      await supa.from('site_settings').update({'contacts': contacts}).eq('id', 1);
      // I contatti fanno parte del sito pubblicato: li pubblichiamo subito.
      await supa.rpc('publish_site', params: {'p_note': t.channelsPublishNote});
      _snack(t.channelsSaved);
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------ validazioni

  String? Function(String?) _required(bool Function() isOn, String message,
      String? Function(String) check) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return isOn() ? message : null;
      return check(text);
    };
  }

  String? _checkTemplate(String? value) {
    final text = value ?? '';
    if (text.length > 1000) return t.templateTooLong;
    if (!_templatePattern.hasMatch(text)) {
      return t.templateInvalid(_placeholders.join(' '));
    }
    return null;
  }

  // ------------------------------------------------------------------ interfaccia

  void _insertPlaceholder(TextEditingController controller, String placeholder) {
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, placeholder),
      selection: TextSelection.collapsed(offset: start + placeholder.length),
    );
  }

  Widget _placeholderChips(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in _placeholders)
            ActionChip(label: Text(p), onPressed: () => _insertPlaceholder(controller, p)),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(title),
              subtitle: Text(subtitle),
              value: value,
              onChanged: onChanged,
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(t.retry)),
            ],
          ),
        ),
      );
    }
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            t.channelsIntro(_placeholders.join(', ')),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _card(
            title: t.whatsapp,
            subtitle: t.whatsappSubtitle,
            value: _waOn,
            onChanged: (v) => setState(() => _waOn = v),
            children: [
              TextFormField(
                controller: _waNumber,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t.phoneField,
                  helperText: t.phoneHelp,
                ),
                validator: _required(() => _waOn, t.phoneRequired, (text) {
                  return _phonePattern.hasMatch(normalizePhone(text)) ? null : t.phoneInvalid;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _waTemplate,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: t.templateField),
                validator: _checkTemplate,
              ),
              _placeholderChips(_waTemplate),
            ],
          ),
          _card(
            title: t.emailChannel,
            subtitle: t.emailSubtitle,
            value: _mailOn,
            onChanged: (v) => setState(() => _mailOn = v),
            children: [
              TextFormField(
                controller: _mailAddress,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: t.emailField),
                validator: _required(() => _mailOn, t.emailRequired, (text) {
                  return _emailPattern.hasMatch(text) && text.length <= 200
                      ? null
                      : t.emailInvalid;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mailSubject,
                decoration: InputDecoration(labelText: t.emailSubject),
                validator: (v) => (v ?? '').length > 150 ? t.maxChars(150) : _checkTemplate(v),
              ),
              _placeholderChips(_mailSubject),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mailBody,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(labelText: t.emailBody),
                validator: _checkTemplate,
              ),
              _placeholderChips(_mailBody),
            ],
          ),
          _card(
            title: t.vintedChannel,
            subtitle: t.vintedSubtitle,
            value: _vintedOn,
            onChanged: (v) => setState(() => _vintedOn = v),
            children: [
              TextFormField(
                controller: _vintedUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(labelText: t.profileLink),
                validator: _required(() => _vintedOn, t.linkRequired, (text) {
                  return _vintedPattern.hasMatch(text) && text.length <= 300
                      ? null
                      : t.vintedInvalid;
                }),
              ),
            ],
          ),
          _card(
            title: t.instagramChannel,
            subtitle: t.instagramSubtitle,
            value: _igOn,
            onChanged: (v) => setState(() => _igOn = v),
            children: [
              TextFormField(
                controller: _igUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(labelText: t.profileLink),
                validator: _required(() => _igOn, t.linkRequired, (text) {
                  return _instagramPattern.hasMatch(text) && text.length <= 300
                      ? null
                      : t.instagramInvalid;
                }),
              ),
            ],
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.saveAndPublish),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.channelsTitle),
        actions: [
          IconButton(
            tooltip: t.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => supa.auth.signOut(),
          ),
        ],
      ),
      body: _body(),
    );
  }
}

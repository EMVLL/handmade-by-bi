import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../config.dart';
import '../supa.dart';
import '../draft.dart';
import '../texts/app_texts.dart';

final _phonePattern = RegExp(r'^[1-9][0-9]{7,14}$');
final _templatePattern = RegExp(r'^([^{}]|\{(prodotto|prezzo|opzione|link)\})*$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _vintedPattern = RegExp(r'^https://(www\.)?vinted\.[a-z.]+/');
final _instagramPattern = RegExp(r'^https://(www\.)?instagram\.com/');
final _instagramUser = RegExp(r'^@?([A-Za-z0-9._]{1,30})$');

/// Segnaposto dei messaggi: parole chiave lette dal sito e dal database,
/// quindi NON vanno tradotte. Benedetta vede solo le etichette di [_tokenLabel].
const _tokens = ['{prodotto}', '{prezzo}', '{opzione}', '{link}'];

String _tokenLabel(String token) => switch (token) {
  '{prodotto}' => t.tokenProduct,
  '{prezzo}' => t.tokenPrice,
  '{opzione}' => t.tokenOption,
  _ => t.tokenLink,
};

/// "+39 333 123 4567" / "0039..." / "3331234567" -> "393331234567"
String normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 10 && digits.startsWith('3')) digits = '39$digits';
  return digits;
}

/// "www.vinted.it/member/1" -> "https://www.vinted.it/member/1"
String normalizeUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return value;
  if (value.startsWith('http://')) value = value.substring(7);
  if (!value.startsWith('https://')) value = 'https://$value';
  return value;
}

/// "@handmadebybi" / "handmadebybi" / link -> link al profilo Instagram
String normalizeInstagram(String raw) {
  final value = raw.trim();
  final user = _instagramUser.firstMatch(value);
  if (user != null) return 'https://www.instagram.com/${user[1]}/';
  return normalizeUrl(value);
}

/// Stessa sostituzione che fa il sito quando il cliente preme il pulsante.
String fillTemplate(String template, Map<String, String> values) => template
    .replaceAllMapped(RegExp(r'\{(prodotto|prezzo|opzione|link)\}'), (m) => values[m[1]] ?? '')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .replaceAll(RegExp(r'\(\s*\)'), '')
    .trim();

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
  bool _justSaved = false;
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
      Map<String, dynamic> channel(String key) => Map<String, dynamic>.from((contacts[key] as Map?) ?? const {});
      String text(Map<String, dynamic> c, String key, [String fallback = '']) {
        final value = (c[key] as String?) ?? '';
        return value.isEmpty ? fallback : value;
      }

      final wa = channel('whatsapp');
      final mail = channel('email');
      final vinted = channel('vinted');
      final ig = channel('instagram');
      if (!mounted) return;
      setState(() {
        _waOn = wa['enabled'] == true;
        _waNumber.text = text(wa, 'number');
        _waTemplate.text = text(wa, 'template', t.defaultWhatsappTemplate);
        _mailOn = mail['enabled'] == true;
        _mailAddress.text = text(mail, 'address');
        _mailSubject.text = text(mail, 'subject_template', t.defaultEmailSubject);
        _mailBody.text = text(mail, 'body_template', t.defaultEmailBody);
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

  // ------------------------------------------------------------------ salvataggio

  /// Un campo viene salvato solo se è valido: così un canale spento con
  /// un valore sbagliato non blocca il salvataggio degli altri.
  String? _ifValid(String value, bool Function(String) isValid) => value.isNotEmpty && isValid(value) ? value : null;

  bool _isTemplate(String value, int max) => value.length <= max && _templatePattern.hasMatch(value);

  Map<String, dynamic> _channel(bool enabled, Map<String, String?> fields) => {
    'enabled': enabled,
    for (final entry in fields.entries)
      if (entry.value != null) entry.key: entry.value,
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
          'number': _ifValid(normalizePhone(_waNumber.text), _phonePattern.hasMatch),
          'template': _ifValid(_waTemplate.text.trim(), (v) => _isTemplate(v, 500)),
        }),
        'email': _channel(_mailOn, {
          'address': _ifValid(_mailAddress.text.trim(), (v) => v.length <= 200 && _emailPattern.hasMatch(v)),
          'subject_template': _ifValid(_mailSubject.text.trim(), (v) => _isTemplate(v, 150)),
          'body_template': _ifValid(_mailBody.text.trim(), (v) => _isTemplate(v, 1000)),
        }),
        'vinted': _channel(_vintedOn, {
          'profile_url': _ifValid(normalizeUrl(_vintedUrl.text), (v) => v.length <= 300 && _vintedPattern.hasMatch(v)),
        }),
        'instagram': _channel(_igOn, {
          'profile_url': _ifValid(
            normalizeInstagram(_igUrl.text),
            (v) => v.length <= 300 && _instagramPattern.hasMatch(v),
          ),
        }),
      };
      await supa.from('site_settings').update({'contacts': contacts}).eq('id', 1);
      // I contatti fanno parte dell'aspetto del sito: vanno online con "Pubblica".
      notifyDraftSaved();
      if (mounted) setState(() => _justSaved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _justSaved = false);
      });
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------ validazioni

  FormFieldValidator<String> _required(String message, String? Function(String) check) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return message;
      return check(text);
    };
  }

  FormFieldValidator<String> _templateValidator(int max) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.length > max) return t.templateTooLong;
      if (!_templatePattern.hasMatch(text)) return t.templateInvalid;
      return null;
    };
  }

  // ------------------------------------------------------------------ messaggi precompilati

  /// Inserisce un dato del pezzo dove si trova il cursore, con gli spazi giusti.
  void _insertToken(TextEditingController controller, String token) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final before = text.substring(0, start);
    final after = text.substring(end);
    final spaceBefore = before.isNotEmpty && !RegExp(r'[\s(]$').hasMatch(before) ? ' ' : '';
    final spaceAfter = after.isNotEmpty && !RegExp(r'^[\s).,!?]').hasMatch(after) ? ' ' : '';
    final insert = '$spaceBefore$token$spaceAfter';
    controller.value = TextEditingValue(
      text: before + insert + after,
      selection: TextSelection.collapsed(offset: before.length + insert.length),
    );
  }

  Widget _tokenButtons(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final token in _tokens)
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(_tokenLabel(token)),
              onPressed: () => _insertToken(controller, token),
            ),
        ],
      ),
    );
  }

  /// Anteprima del messaggio con un pezzo di esempio, aggiornata mentre si scrive.
  Widget _preview(TextEditingController controller, String fallback) {
    final theme = Theme.of(context);
    final sample = {
      'prodotto': t.sampleProduct,
      'prezzo': t.price(35),
      'opzione': t.sampleOption,
      'link': '${Config.siteUrl}/prodotti/borsa-margherita',
    };
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final template = value.text.trim().isEmpty ? fallback : value.text;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.previewTitle, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(fillTemplate(template, sample)),
            ],
          ),
        );
      },
    );
  }

  /// Sezione richiudibile: chi non vuole cambiare il messaggio non la apre mai.
  Widget _messageEditor({required String title, required List<Widget> fields, required VoidCallback onReset}) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(title),
      children: [
        Text(t.messageHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        ...fields,
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: onReset, icon: const Icon(Icons.restart_alt), label: Text(t.resetMessage)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ interfaccia

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
            // I campi compaiono solo quando il canale è attivo.
            if (value) ...[const SizedBox(height: 4), ...children, const SizedBox(height: 8)],
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
          Text(t.channelsIntro, style: Theme.of(context).textTheme.bodyLarge),
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
                decoration: InputDecoration(labelText: t.phoneField, helperText: t.phoneHelp),
                validator: _required(t.phoneRequired, (text) {
                  return _phonePattern.hasMatch(normalizePhone(text)) ? null : t.phoneInvalid;
                }),
              ),
              _messageEditor(
                title: t.messageSectionWhatsapp,
                onReset: () => _waTemplate.text = t.defaultWhatsappTemplate,
                fields: [
                  TextFormField(
                    controller: _waTemplate,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: t.templateField),
                    validator: _templateValidator(500),
                  ),
                  _tokenButtons(_waTemplate),
                  _preview(_waTemplate, t.defaultWhatsappTemplate),
                ],
              ),
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
                validator: _required(t.emailRequired, (text) {
                  return _emailPattern.hasMatch(text) && text.length <= 200 ? null : t.emailInvalid;
                }),
              ),
              _messageEditor(
                title: t.messageSectionEmail,
                onReset: () {
                  _mailSubject.text = t.defaultEmailSubject;
                  _mailBody.text = t.defaultEmailBody;
                },
                fields: [
                  TextFormField(
                    controller: _mailSubject,
                    decoration: InputDecoration(labelText: t.emailSubject),
                    validator: _templateValidator(150),
                  ),
                  _tokenButtons(_mailSubject),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mailBody,
                    minLines: 2,
                    maxLines: 6,
                    decoration: InputDecoration(labelText: t.emailBody),
                    validator: _templateValidator(1000),
                  ),
                  _tokenButtons(_mailBody),
                  _preview(_mailBody, t.defaultEmailBody),
                ],
              ),
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
                decoration: InputDecoration(labelText: t.profileLink, helperText: t.vintedLinkHelp, helperMaxLines: 2),
                validator: _required(t.linkRequired, (text) {
                  final url = normalizeUrl(text);
                  return _vintedPattern.hasMatch(url) && url.length <= 300 ? null : t.vintedInvalid;
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
                decoration: InputDecoration(
                  labelText: t.profileLink,
                  helperText: t.instagramLinkHelp,
                  helperMaxLines: 2,
                ),
                validator: _required(t.linkRequired, (text) {
                  final url = normalizeInstagram(text);
                  return _instagramPattern.hasMatch(url) && url.length <= 300 ? null : t.instagramInvalid;
                }),
              ),
            ],
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : _justSaved
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [const Icon(Icons.check), const SizedBox(width: 8), Text(t.saved)],
                  )
                : Text(t.save),
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
        actions: [IconButton(tooltip: t.signOut, icon: const Icon(Icons.logout), onPressed: () => supa.auth.signOut())],
      ),
      body: _body(),
    );
  }
}

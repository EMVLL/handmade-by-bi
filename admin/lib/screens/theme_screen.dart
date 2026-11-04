import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../fonts_preview.dart';
import '../supa.dart';
import '../texts/app_texts.dart';
import '../widgets/color_picker.dart';
import '../draft.dart';

Color _color(String hex) => hexColor(hex);

const _radius = {'none': 0.0, 'small': 6.0, 'medium': 12.0, 'large': 24.0};
const _radiusKeys = ['none', 'small', 'medium', 'large'];

/// Stili pronti: un tocco e il sito cambia aspetto in modo armonioso.
const _presets = <String, Map<String, String>>{
  'rosa': {'primary': '#B5838D', 'accent': '#6D9773', 'background': '#FFF8F3', 'text': '#3D3033',
           'font_heading': 'Fraunces', 'font_body': 'Nunito', 'radius': 'medium'},
  'salvia': {'primary': '#7C9473', 'accent': '#D9A05B', 'background': '#F7F5EE', 'text': '#2F3A2C',
             'font_heading': 'Lora', 'font_body': 'Lato', 'radius': 'medium'},
  'lavanda': {'primary': '#8E7CC3', 'accent': '#E8A0BF', 'background': '#FAF7FF', 'text': '#2E2A3B',
              'font_heading': 'Playfair Display', 'font_body': 'Quicksand', 'radius': 'large'},
  'mare': {'primary': '#3D7EA6', 'accent': '#F2A65A', 'background': '#F5FAFC', 'text': '#1F2D3A',
           'font_heading': 'DM Serif Display', 'font_body': 'DM Sans', 'radius': 'small'},
  'terracotta': {'primary': '#C0673E', 'accent': '#4F6D7A', 'background': '#FFF6EF', 'text': '#3A2A22',
                 'font_heading': 'Fraunces', 'font_body': 'Lato', 'radius': 'small'},
  'cioccolato': {'primary': '#8B5E3C', 'accent': '#C9A227', 'background': '#FFFBF2', 'text': '#3B2A1E',
                 'font_heading': 'DM Serif Display', 'font_body': 'Nunito', 'radius': 'none'},
};

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  Map<String, String> _theme = Map.of(_presets['rosa']!);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    for (final f in allSiteFonts) {
      loadPreviewFont(f);
    }
  }

  Future<void> _load() async {
    try {
      final row = await supa.from('site_settings').select('theme').eq('id', 1).single();
      final theme = Map<String, dynamic>.from((row['theme'] as Map?) ?? const {});
      if (!mounted) return;
      setState(() {
        _theme = {..._theme, for (final e in theme.entries) e.key: '${e.value}'};
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
    setState(() => _saving = true);
    try {
      await supa.from('site_settings').update({'theme': _theme}).eq('id', 1);
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

  Future<void> _pickColor(String key, String title) async {
    final chosen = await showColorPicker(context, title: title, current: _theme[key]);
    if (chosen != null) setState(() => _theme[key] = chosen);
  }

  Widget _preview() {
    final bg = _color(_theme['background']!);
    final text = _color(_theme['text']!);
    final primary = _color(_theme['primary']!);
    final accent = _color(_theme['accent']!);
    final radius = _radius[_theme['radius']] ?? 12;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.swatchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(radius)),
            child: FontPreviewText(t.stylePreviewTag, font: _theme['font_body']!,
                style: TextStyle(color: bg, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          FontPreviewText(t.stylePreviewTitle, font: _theme['font_heading']!, style: TextStyle(color: text, fontSize: 30)),
          const SizedBox(height: 6),
          FontPreviewText(t.stylePreviewText, font: _theme['font_body']!, style: TextStyle(color: text, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(radius)),
            child: FontPreviewText(t.stylePreviewButton, font: _theme['font_body']!,
                style: TextStyle(color: bg, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _presetCard(String key, Map<String, String> preset) {
    final selected = _presets[key]!.entries.every((e) => _theme[e.key] == e.value);
    return InkWell(
      onTap: () => setState(() => _theme = Map.of(preset)),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _color(preset['background']!),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : AppColors.swatchBorder,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final k in ['primary', 'accent', 'text'])
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(color: _color(preset[k]!), shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FontPreviewText(t.presetName(key), font: preset['font_heading']!,
                style: TextStyle(color: _color(preset['text']!), fontSize: 17)),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(String key, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(_theme[key] ?? ''),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _color(_theme[key]!),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.swatchBorder),
        ),
      ),
      onTap: () => _pickColor(key, label),
    );
  }

  Widget _fontChoice(String key, String label, List<String> fonts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in fonts)
              ChoiceChip(
                label: FontPreviewText(f, font: f, style: const TextStyle(fontSize: 17)),
                selected: _theme[key] == f,
                onSelected: (_) => setState(() => _theme[key] = f),
              ),
          ],
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _preview(),
          _section(t.stylePresets),
          // In griglia: si vedono tutti, senza scorrere di lato
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final e in _presets.entries) _presetCard(e.key, e.value)],
          ),
          _section(t.styleColors),
          _colorRow('primary', t.colorPrimary),
          _colorRow('accent', t.colorAccent),
          _colorRow('background', t.colorBackground),
          _colorRow('text', t.colorText),
          const SizedBox(height: 16),
          _fontChoice('font_heading', t.styleHeadingFont, headingFonts),
          const SizedBox(height: 20),
          _fontChoice('font_body', t.styleBodyFont, bodyFonts),
          const SizedBox(height: 20),
          Text(t.styleCorners, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _radiusKeys.length; i++)
                ChoiceChip(
                  label: Text(t.cornerLabels[i]),
                  selected: _theme['radius'] == _radiusKeys[i],
                  onSelected: (_) => setState(() => _theme['radius'] = _radiusKeys[i]),
                ),
            ],
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.styleTitle)),
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

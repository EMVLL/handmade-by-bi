import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../fonts_preview.dart';
import '../media.dart';
import '../models.dart';
import '../supa.dart';
import '../texts/app_texts.dart';

final _linkPattern = RegExp(r'^(https://|/)\S{0,299}$');

/// Un collegamento pronto da proporre nei campi "link".
class LinkSuggestion {
  const LinkSuggestion(this.label, this.url);
  final String label;
  final String url;
}

/// Dati che servono ad alcuni campi (categorie, pezzi, link).
class SchemaFormData {
  const SchemaFormData({
    this.categories = const [],
    this.products = const [],
    this.links = const [],
  });
  final List<ShopCategory> categories;
  final List<Product> products;
  final List<LinkSuggestion> links;
}

/// Modulo costruito automaticamente dallo schema di una sezione.
///
/// Lo schema è lo stesso che il database usa per validare: qui decide quali
/// campi mostrare e come (testo, foto, scelte, interruttori, liste).
/// [values] viene modificata direttamente; va messa in un [Form] per la validazione.
class SchemaForm extends StatefulWidget {
  const SchemaForm({super.key, required this.schema, required this.values, this.data = const SchemaFormData()});

  final Map<String, dynamic> schema;
  final Map<String, dynamic> values;
  final SchemaFormData data;

  @override
  State<SchemaForm> createState() => _SchemaFormState();
}

class _SchemaFormState extends State<SchemaForm> {
  final _controllers = <String, TextEditingController>{};
  final _uploading = <String>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _id(Map<String, dynamic> values, String key) => '${identityHashCode(values)}:$key';

  TextEditingController _controller(Map<String, dynamic> values, String key) =>
      _controllers.putIfAbsent(_id(values, key), () => TextEditingController(text: (values[key] as String?) ?? ''));

  static List<String> orderedKeys(Map<String, dynamic> schema) {
    final props = Map<String, dynamic>.from((schema['properties'] as Map?) ?? const {});
    final order = ((schema['x-order'] as List?) ?? const []).whereType<String>().where(props.containsKey).toList();
    final rest = props.keys.where((k) => !order.contains(k)).toList()..sort();
    return [...order, ...rest];
  }

  // ------------------------------------------------------------------ campi

  Widget _field(String key, Map<String, dynamic> spec, Map<String, dynamic> values, Set<String> required) {
    final label = (spec['x-label'] as String?) ?? key;
    final widgetType = spec['x-widget'] as String?;
    final isRequired = required.contains(key);

    if (spec['enum'] is List) return _enumField(key, spec, values, label, widgetType == 'font');

    switch (spec['type']) {
      case 'boolean':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: (values[key] as bool?) ?? (spec['default'] as bool?) ?? false,
          onChanged: (v) => setState(() => values[key] = v),
        );
      case 'integer':
        return _intField(key, spec, values, label);
      case 'array':
        if (widgetType == 'images') return _imagesField(key, spec, values, label);
        final items = spec['items'];
        if (items is Map && items['type'] == 'object') {
          return _objectListField(key, spec, Map<String, dynamic>.from(items), values, label);
        }
        return const SizedBox.shrink();
      case 'string':
        return switch (widgetType) {
          'image' => _imageField(key, values, label),
          'collection' => _collectionField(key, values, label),
          'product' => _productField(key, values, label),
          _ => _textField(key, spec, values, label, isRequired,
              multiline: widgetType == 'textarea', link: widgetType == 'link'),
        };
    }
    return const SizedBox.shrink();
  }

  Widget _textField(
    String key,
    Map<String, dynamic> spec,
    Map<String, dynamic> values,
    String label,
    bool isRequired, {
    bool multiline = false,
    bool link = false,
  }) {
    final controller = _controller(values, key);
    final maxLength = spec['maxLength'] as int?;
    void store(String text) {
      final value = text.trim();
      if (value.isEmpty && !isRequired) {
        values.remove(key);
      } else {
        values[key] = value;
      }
    }

    final field = TextFormField(
      controller: controller,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 10 : 1,
      keyboardType: link ? TextInputType.url : null,
      autocorrect: !link,
      textCapitalization: link ? TextCapitalization.none : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        alignLabelWithHint: multiline,
        helperText: link ? t.linkHelp : null,
        helperMaxLines: 3,
      ),
      onChanged: store,
      validator: (value) {
        final text = (value ?? '').trim();
        if (isRequired && text.isEmpty) return t.fieldRequired;
        if (maxLength != null && text.length > maxLength) return t.maxChars(maxLength);
        if (link && text.isNotEmpty && !_linkPattern.hasMatch(text)) return t.linkInvalid;
        return null;
      },
    );
    if (!link || widget.data.links.isEmpty) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in widget.data.links)
              ActionChip(
                label: Text(s.label),
                onPressed: () {
                  controller.text = s.url;
                  store(s.url);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _enumField(String key, Map<String, dynamic> spec, Map<String, dynamic> values, String label, bool fonts) {
    final options = spec['enum'] as List;
    final labels = (spec['x-enum-labels'] as List?)?.map((e) => e.toString()).toList();
    final current = values[key] ?? spec['default'];
    return _Labeled(
      label: label,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < options.length; i++)
            ChoiceChip(
              label: fonts && options[i] != 'theme'
                  ? FontPreviewText(labels?[i] ?? '${options[i]}', font: '${options[i]}', style: const TextStyle(fontSize: 16))
                  : Text(labels != null && i < labels.length ? labels[i] : '${options[i]}'),
              selected: current == options[i],
              onSelected: (_) => setState(() => values[key] = options[i]),
            ),
        ],
      ),
    );
  }

  Widget _intField(String key, Map<String, dynamic> spec, Map<String, dynamic> values, String label) {
    final min = (spec['minimum'] as num?)?.toInt() ?? 0;
    final max = (spec['maximum'] as num?)?.toInt() ?? 999;
    final value = ((values[key] ?? spec['default'] ?? min) as num).toInt().clamp(min, max);
    return _Labeled(
      label: label,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: value > min ? () => setState(() => values[key] = value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 56,
            child: Text('$value', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton.filledTonal(
            onPressed: value < max ? () => setState(() => values[key] = value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickAndUpload(String uploadId) async {
    final picked = await pickPhotos();
    if (picked.photos.isEmpty) {
      if (picked.skipped > 0) _snack(t.photosSkipped(picked.skipped));
      return null;
    }
    setState(() => _uploading.add(uploadId));
    try {
      return await uploadPhoto(picked.photos.first, 'site');
    } catch (e) {
      _snack(friendlyError(e));
      return null;
    } finally {
      if (mounted) setState(() => _uploading.remove(uploadId));
    }
  }

  Widget _thumb(String? path, {double size = 72}) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: SizedBox(
        width: size,
        height: size,
        child: path == null
            ? ColoredBox(color: scheme.surfaceContainerHighest, child: const Icon(Icons.image_outlined))
            : Image.network(
                mediaUrl(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }

  Widget _imageField(String key, Map<String, dynamic> values, String label) {
    final path = values[key] as String?;
    final id = _id(values, key);
    final busy = _uploading.contains(id);
    return _Labeled(
      label: label,
      child: Row(
        children: [
          _thumb(path),
          const SizedBox(width: 12),
          if (busy)
            Text(t.uploading)
          else
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final uploaded = await _pickAndUpload(id);
                      if (uploaded != null && mounted) setState(() => values[key] = uploaded);
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(path == null ? t.choosePhoto : t.changePhoto),
                  ),
                  if (path != null)
                    TextButton(onPressed: () => setState(() => values.remove(key)), child: Text(t.removePhoto)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagesField(String key, Map<String, dynamic> spec, Map<String, dynamic> values, String label) {
    final list = ((values[key] as List?) ?? const []).whereType<String>().toList();
    final max = (spec['maxItems'] as int?) ?? 24;
    final id = _id(values, key);
    final busy = _uploading.contains(id);
    return _Labeled(
      label: label,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < list.length; i++)
            Stack(
              children: [
                _thumb(list[i], size: 88),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    onPressed: () => setState(() => values[key] = [...list]..removeAt(i)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          if (busy)
            SizedBox(width: 88, height: 88, child: Center(child: Text(t.uploading, textAlign: TextAlign.center)))
          else if (list.length < max)
            SizedBox(
              width: 88,
              height: 88,
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await pickPhotos(multiple: true);
                  if (picked.skipped > 0) _snack(t.photosSkipped(picked.skipped));
                  if (picked.photos.isEmpty) return;
                  setState(() => _uploading.add(id));
                  try {
                    final added = <String>[];
                    for (final photo in picked.photos.take(max - list.length)) {
                      added.add(await uploadPhoto(photo, 'site'));
                    }
                    if (mounted) setState(() => values[key] = [...list, ...added]);
                  } catch (e) {
                    _snack(friendlyError(e));
                  } finally {
                    if (mounted) setState(() => _uploading.remove(id));
                  }
                },
                child: const Icon(Icons.add_a_photo_outlined),
              ),
            ),
        ],
      ),
    );
  }

  Widget _collectionField(String key, Map<String, dynamic> values, String label) {
    final current = values[key] as String?;
    return _Labeled(
      label: label,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text(t.allCategories),
            selected: current == null,
            onSelected: (_) => setState(() => values.remove(key)),
          ),
          for (final c in widget.data.categories)
            ChoiceChip(
              label: Text(c.name),
              selected: current == c.id,
              onSelected: (_) => setState(() => values[key] = c.id),
            ),
        ],
      ),
    );
  }

  Widget _productField(String key, Map<String, dynamic> values, String label) {
    final current = widget.data.products.where((p) => p.id == values[key]).firstOrNull;
    return _Labeled(
      label: label,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _thumb(current?.photos.firstOrNull, size: 48),
        title: Text(current?.title ?? t.noProduct),
        trailing: FilledButton.tonal(
          onPressed: () async {
            final chosen = await showModalBottomSheet<Product>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7,
                builder: (context, scroll) => ListView(
                  controller: scroll,
                  children: [
                    for (final p in widget.data.products)
                      ListTile(
                        leading: _thumb(p.photos.firstOrNull, size: 48),
                        title: Text(p.title),
                        subtitle: Text(t.statusLabel(p.status)),
                        onTap: () => Navigator.pop(context, p),
                      ),
                  ],
                ),
              ),
            );
            if (chosen != null) setState(() => values[key] = chosen.id);
          },
          child: Text(t.chooseProduct),
        ),
      ),
    );
  }

  Widget _objectListField(
    String key,
    Map<String, dynamic> spec,
    Map<String, dynamic> itemSchema,
    Map<String, dynamic> values,
    String label,
  ) {
    final list = ((values[key] as List?) ?? <dynamic>[])
        .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
        .toList();
    values[key] = list;
    final max = (spec['maxItems'] as int?) ?? 20;
    final itemKeys = orderedKeys(itemSchema);
    final itemRequired = ((itemSchema['required'] as List?) ?? const []).whereType<String>().toSet();
    final itemProps = Map<String, dynamic>.from((itemSchema['properties'] as Map?) ?? const {});

    void move(int from, int to) => setState(() {
          final item = list.removeAt(from);
          list.insert(to, item);
        });

    return _Labeled(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < list.length; i++)
            Card(
              key: ObjectKey(list[i]),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final k in itemKeys)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _field(k, Map<String, dynamic>.from(itemProps[k] as Map), list[i], itemRequired),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: i > 0 ? () => move(i, i - 1) : null,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          onPressed: i < list.length - 1 ? () => move(i, i + 1) : null,
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => list.removeAt(i)),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(t.removeItem),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (list.length < max)
            OutlinedButton.icon(
              onPressed: () => setState(() => list.add(<String, dynamic>{})),
              icon: const Icon(Icons.add),
              label: Text(t.addItem),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ insieme

  @override
  Widget build(BuildContext context) {
    final props = Map<String, dynamic>.from((widget.schema['properties'] as Map?) ?? const {});
    final required = ((widget.schema['required'] as List?) ?? const []).whereType<String>().toSet();
    final keys = orderedKeys(widget.schema);
    Map<String, dynamic> spec(String k) => Map<String, dynamic>.from(props[k] as Map);
    bool isStyle(String k) => spec(k)['x-group'] == 'style';

    final main = keys.where((k) => !isStyle(k)).toList();
    final style = keys.where(isStyle).toList();

    Widget padded(String k) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _field(k, spec(k), widget.values, required),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final k in main) padded(k),
        if (style.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.palette_outlined),
              title: Text(t.formStyleSection),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final k in style) padded(k)],
            ),
          ),
      ],
    );
  }
}

/// Etichetta sopra un campo che non ha una sua etichetta (scelte, foto, liste).
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

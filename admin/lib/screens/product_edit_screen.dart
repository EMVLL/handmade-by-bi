import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../supa.dart';
import '../utils.dart';
import '../app_theme.dart';
import '../texts/app_texts.dart';

/// Una foto del pezzo: già caricata (path) oppure appena scelta (bytes).
class _Photo {
  _Photo.saved(String this.path)
      : bytes = null,
        mime = null;
  _Photo.fresh(Uint8List this.bytes, String this.mime) : path = null;

  final String? path;
  final Uint8List? bytes;
  final String? mime;
}

class _OptionDraft {
  _OptionDraft({String name = '', String values = ''})
      : name = TextEditingController(text: name),
        values = TextEditingController(text: values);

  final TextEditingController name;
  final TextEditingController values;

  void dispose() {
    name.dispose();
    values.dispose();
  }
}

final _vintedPattern = RegExp(r'^https://(www\.)?vinted\.[a-z.]+/', caseSensitive: false);

class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({super.key, this.product});

  /// null = nuovo pezzo
  final Product? product;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _compare;
  late final TextEditingController _vinted;
  late String _status;
  final List<_Photo> _photos = [];
  final List<_OptionDraft> _options = [];
  final List<_OptionDraft> _removedOptions = [];
  final List<String> _removedPaths = [];
  bool _saving = false;
  String _progress = '';

  bool get _isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price == null ? '' : formatNumber(p!.price!));
    _compare = TextEditingController(
        text: p?.compareAtPrice == null ? '' : formatNumber(p!.compareAtPrice!));
    _vinted = TextEditingController(text: p?.vintedUrl ?? '');
    _status = p?.status ?? 'disponibile';
    _photos.addAll((p?.photos ?? const <String>[]).map(_Photo.saved));
    _options.addAll((p?.options ?? const <ProductOption>[])
        .map((o) => _OptionDraft(name: o.name, values: o.values.join(', '))));
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _compare, _vinted]) {
      c.dispose();
    }
    for (final o in [..._options, ..._removedOptions]) {
      o.dispose();
    }
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------------------------------------------------------ foto

  Future<void> _addPhotos() async {
    final free = Config.maxPhotos - _photos.length;
    if (free <= 0) {
      _snack(t.photosMax(Config.maxPhotos));
      return;
    }
    // Su iPhone si apre il menu: Libreria foto / Scatta foto / Scegli file.
    // Le foto vengono ridimensionate prima del caricamento.
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
    } catch (e) {
      _snack(t.photosOpenError(friendlyError(e)));
      return;
    }
    if (picked.isEmpty) return;

    var skipped = 0;
    for (final file in picked.take(free)) {
      final bytes = await file.readAsBytes();
      final mime = detectImageMime(bytes);
      if (mime == null || bytes.length > Config.maxPhotoBytes) {
        skipped++;
        continue;
      }
      _photos.add(_Photo.fresh(bytes, mime));
    }
    if (!mounted) return;
    setState(() {});
    if (picked.length > free) {
      _snack(t.photosPartiallyAdded(free, Config.maxPhotos));
    } else if (skipped > 0) {
      _snack(t.photosSkipped(skipped));
    }
  }

  void _movePhoto(int from, int to) {
    setState(() {
      final item = _photos.removeAt(from);
      _photos.insert(to, item);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      final item = _photos.removeAt(index);
      if (item.path != null) _removedPaths.add(item.path!);
    });
  }

  Future<void> _photoMenu(int index) async {
    final last = _photos.length - 1;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(t.photoMakeCover),
                onTap: () => Navigator.pop(context, 'cover'),
              ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: Text(t.photoMoveLeft),
                onTap: () => Navigator.pop(context, 'left'),
              ),
            if (index < last)
              ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text(t.photoMoveRight),
                onTap: () => Navigator.pop(context, 'right'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t.photoRemove),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'cover':
        _movePhoto(index, 0);
      case 'left':
        _movePhoto(index, index - 1);
      case 'right':
        _movePhoto(index, index + 1);
      case 'remove':
        _removePhoto(index);
    }
  }

  Widget _photoTile(int index) {
    final item = _photos[index];
    final image = item.bytes != null
        ? Image.memory(item.bytes!, fit: BoxFit.cover)
        : Image.network(
            mediaUrl(item.path!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _photoMenu(index),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (index == 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: AppColors.photoLabelBackground,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          t.photoCover,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.photoLabelText, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addPhotoTile() {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _addPhotos,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: scheme.primary),
            const SizedBox(height: 6),
            Text(t.photoAdd, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _photoStrip() {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _photos.length; i++) _photoTile(i),
          if (_photos.length < Config.maxPhotos) _addPhotoTile(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ opzioni

  Widget _optionsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in _options)
          Card(
            key: ObjectKey(option),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: option.name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(labelText: t.optionName),
                          validator: _validateOptionName,
                        ),
                      ),
                      IconButton(
                        tooltip: t.optionRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() {
                          _options.remove(option);
                          _removedOptions.add(option);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextFormField(
                      controller: option.values,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: t.optionValues,
                        hintText: t.optionValuesHint,
                      ),
                      validator: _validateOptionValues,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_options.length < Config.maxOptions)
          OutlinedButton.icon(
            onPressed: () => setState(() => _options.add(_OptionDraft())),
            icon: const Icon(Icons.add),
            label: Text(t.optionAdd),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ validazioni

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return t.errTitleRequired;
    if (text.length > 120) return t.maxChars(120);
    return null;
  }

  String? _validateDescription(String? value) =>
      (value ?? '').trim().length > 5000 ? t.maxChars(5000) : null;

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final price = parsePrice(text);
    if (price == null) return t.errPriceFormat;
    if (price < 0 || price > 100000) return t.errPriceInvalid;
    return null;
  }

  String? _validateCompare(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final compare = parsePrice(text);
    if (compare == null) return t.errPriceFormat;
    final price = parsePrice(_price.text.trim());
    if (price == null) return t.errCompareNeedsPrice;
    if (compare <= price) return t.errCompareTooLow;
    if (compare > 100000) return t.errPriceInvalid;
    return null;
  }

  String? _validateVinted(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 300 || !_vintedPattern.hasMatch(text)) {
      return t.errVintedLink;
    }
    return null;
  }

  String? _validateOptionName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return t.errOptionName;
    if (text.length > 30) return t.maxChars(30);
    return null;
  }

  String? _validateOptionValues(String? value) {
    final values = splitValues(value ?? '');
    if (values.isEmpty) return t.errOptionValuesEmpty;
    if (values.length > Config.maxOptionValues) {
      return t.errOptionValuesMax(Config.maxOptionValues);
    }
    if (values.any((v) => v.length > 30)) return t.errOptionValueLength(30);
    return null;
  }

  // ------------------------------------------------------------------ salvataggio

  Future<void> _insertWithUniqueSlug(Map<String, dynamic> data) async {
    final base = slugify(data['title'] as String);
    for (var attempt = 0; attempt < 5; attempt++) {
      final slug = attempt == 0 ? base : '$base-${randomDigits(4)}';
      try {
        await supa.from('products').insert({...data, 'slug': slug});
        return;
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow; // 23505 = indirizzo già usato
      }
    }
    throw Exception(t.errSlug);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_form.currentState?.validate() ?? false)) {
      _snack(t.checkFields);
      return;
    }
    setState(() {
      _saving = true;
      _progress = t.progressSaving;
    });

    final uploaded = <String>[];
    try {
      final paths = <String>[];
      final toUpload = _photos.where((p) => p.bytes != null).length;
      var done = 0;
      for (final photo in _photos) {
        if (photo.path != null) {
          paths.add(photo.path!);
          continue;
        }
        done++;
        if (mounted) setState(() => _progress = t.progressUploading(done, toUpload));
        final path = newPhotoPath(photo.mime!);
        await supa.storage.from('media').uploadBinary(
              path,
              photo.bytes!,
              fileOptions: FileOptions(contentType: photo.mime!, cacheControl: '31536000'),
            );
        uploaded.add(path);
        paths.add(path);
      }

      if (mounted) setState(() => _progress = t.progressSaving);
      final vinted = _vinted.text.trim();
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'price': parsePrice(_price.text.trim()),
        'compare_at_price': parsePrice(_compare.text.trim()),
        'status': _status,
        'photos': paths,
        'options': [
          for (final o in _options)
            {'name': o.name.text.trim(), 'values': splitValues(o.values.text)},
        ],
        'vinted_url': vinted.isEmpty ? null : vinted,
      };

      if (_isNew) {
        await _insertWithUniqueSlug(data);
      } else {
        await supa.from('products').update(data).eq('id', widget.product!.id);
      }

      if (_removedPaths.isNotEmpty) {
        try {
          await supa.storage.from('media').remove(_removedPaths);
        } catch (_) {
          // Una foto rimasta nel bucket non è un problema.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (uploaded.isNotEmpty) {
        try {
          await supa.storage.from('media').remove(uploaded);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _progress = '';
      });
      _snack(friendlyError(e));
    }
  }

  // ------------------------------------------------------------------ interfaccia

  Widget _section(String title, [String? hint]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(hint, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(_isNew ? t.editNewTitle : t.editTitle)),
        body: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _section(t.photosSection, t.photosHint),
                _photoStrip(),
                _section(t.productSection),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: t.fieldName),
                  validator: _validateTitle,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 10,
                  decoration: InputDecoration(labelText: t.fieldDescription, alignLabelWithHint: true),
                  validator: _validateDescription,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: decimal,
                        decoration: InputDecoration(
                          labelText: t.fieldPrice,
                          helperText: t.fieldPriceHelp,
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _compare,
                        keyboardType: decimal,
                        decoration: InputDecoration(
                          labelText: t.fieldCompare,
                          helperText: t.fieldCompareHelp,
                        ),
                        validator: _validateCompare,
                      ),
                    ),
                  ],
                ),
                _section(t.statusSection),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in productStatuses)
                      ChoiceChip(
                        label: Text(t.statusLabel(s)),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                  ],
                ),
                _section(t.optionsSection, t.optionsHint),
                _optionsEditor(),
                _section(t.vintedSection, t.vintedHint),
                TextFormField(
                  controller: _vinted,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: t.vintedField),
                  validator: _validateVinted,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(_progress),
                      ],
                    )
                  : Text(t.save),
            ),
          ),
        ),
      ),
    );
  }
}

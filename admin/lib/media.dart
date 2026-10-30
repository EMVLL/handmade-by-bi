import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'supa.dart';
import 'utils.dart';

/// Foto scelta dal telefono, già ridimensionata e controllata.
class PickedPhoto {
  const PickedPhoto(this.bytes, this.mime);
  final Uint8List bytes;
  final String mime;
}

/// Apre la scelta delle foto (su iPhone: Libreria / Scatta foto / File).
/// Restituisce le foto valide e quante sono state scartate.
Future<({List<PickedPhoto> photos, int skipped})> pickPhotos({bool multiple = false}) async {
  final picker = ImagePicker();
  final files = multiple
      ? await picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 82)
      : [?await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 82)];
  final photos = <PickedPhoto>[];
  var skipped = 0;
  for (final file in files) {
    final bytes = await file.readAsBytes();
    final mime = detectImageMime(bytes);
    if (mime == null || bytes.length > Config.maxPhotoBytes) {
      skipped++;
    } else {
      photos.add(PickedPhoto(bytes, mime));
    }
  }
  return (photos: photos, skipped: skipped);
}

/// Carica una foto nel bucket "media" e ne restituisce il percorso.
Future<String> uploadPhoto(PickedPhoto photo, String folder) async {
  final ext = switch (photo.mime) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };
  final path = '$folder/${DateTime.now().millisecondsSinceEpoch}-${randomHex(6)}.$ext';
  await supa.storage.from('media').uploadBinary(
        path,
        photo.bytes,
        fileOptions: FileOptions(contentType: photo.mime, cacheControl: '31536000'),
      );
  return path;
}

/// Pubblica il sito: le modifiche alle pagine vanno online subito.
Future<void> publishSite(String note) => supa.rpc('publish_site', params: {'p_note': note});

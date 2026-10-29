import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'texts/app_texts.dart';

/// Client Supabase condiviso da tutta l'app.
SupabaseClient get supa => Supabase.instance.client;

/// Indirizzo pubblico di una foto salvata nel bucket "media".
String mediaUrl(String path) =>
    '${Config.supabaseUrl}/storage/v1/object/public/media/$path';

/// Messaggio d'errore comprensibile per chi usa l'app.
String friendlyError(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return t.errorWrongCredentials;
    }
    if (m.contains('email not confirmed')) {
      return t.errorEmailNotConfirmed;
    }
    return t.errorLogin(error.message);
  }
  if (error is PostgrestException) {
    return error.message;
  }
  if (error is StorageException) {
    return t.errorPhotoUpload(error.message);
  }
  final text = error.toString();
  if (text.contains('Failed to fetch') ||
      text.contains('ClientException') ||
      text.contains('SocketException')) {
    return t.errorOffline;
  }
  return text;
}

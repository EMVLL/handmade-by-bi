import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// Client Supabase condiviso da tutta l'app.
SupabaseClient get supa => Supabase.instance.client;

/// Indirizzo pubblico di una foto salvata nel bucket "media".
String mediaUrl(String path) =>
    '${Config.supabaseUrl}/storage/v1/object/public/media/$path';

/// Messaggio d'errore comprensibile per Benedetta.
String friendlyError(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email o password non corretti';
    }
    if (m.contains('email not confirmed')) {
      return 'Email non ancora confermata';
    }
    return 'Accesso non riuscito: ${error.message}';
  }
  if (error is PostgrestException) {
    return error.message;
  }
  if (error is StorageException) {
    return 'Caricamento foto non riuscito: ${error.message}';
  }
  final text = error.toString();
  if (text.contains('Failed to fetch') ||
      text.contains('ClientException') ||
      text.contains('SocketException')) {
    return 'Connessione assente: controlla internet e riprova';
  }
  return text;
}

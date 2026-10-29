import 'package:shared_preferences/shared_preferences.dart';

import 'supa.dart';

const _rememberKey = 'remember_me';

/// Ricorda la scelta "Rimani connesso" fatta al login.
Future<void> setRememberMe(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_rememberKey, value);
}

Future<bool> getRememberMe() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_rememberKey) ?? true;
}

/// All'apertura dell'app: se l'ultima volta non era stato chiesto di
/// rimanere connessi, chiude la sessione rimasta salvata.
Future<void> applyRememberMe() async {
  if (supa.auth.currentSession == null) return;
  if (await getRememberMe()) return;
  try {
    await supa.auth.signOut();
  } catch (_) {
    // Senza rete la sessione verrà comunque chiusa al prossimo tentativo.
  }
}

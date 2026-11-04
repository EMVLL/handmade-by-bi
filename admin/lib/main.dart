import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/admin_gate.dart';
import 'screens/login_screen.dart';
import 'session.dart';
import 'app_theme.dart';
import 'texts/app_texts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Config.supabaseUrl, publishableKey: Config.supabaseKey);
  await applyRememberMe();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: t.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: t.locale,
      supportedLocales: [t.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Tutta l'app sta sopra il badge "Powered by Netlify": pulsanti, menu e messaggi compresi.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1)),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.badgeSpace),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                child: child,
              ),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Mostra il login o l'app, a seconda che ci sia una sessione attiva.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final session = auth.currentSession;
        if (session == null) return const LoginScreen();
        return AdminGate(key: ValueKey(session.user.id));
      },
    );
  }
}

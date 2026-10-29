import 'package:flutter/material.dart';

import '../supa.dart';
import '../texts/app_texts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = t.loginMissingFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supa.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.appName,
                        textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(t.loginSubtitle,
                        textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: InputDecoration(labelText: t.loginEmail),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: t.loginPassword,
                        suffixIcon: IconButton(
                          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _hidden = !_hidden),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _signIn,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(t.loginButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../supa.dart';
import 'home_screen.dart';

/// Controlla che l'account sia tra gli amministratori del negozio.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late Future<bool> _check = _isAdmin();

  Future<bool> _isAdmin() async {
    final result = await supa.rpc('is_admin');
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return _Message(
            text: friendlyError(snapshot.error!),
            action: 'Riprova',
            onAction: () => setState(() => _check = _isAdmin()),
          );
        }
        if (snapshot.data != true) {
          return _Message(
            text: 'Questo account non è autorizzato a gestire il negozio.',
            action: 'Esci',
            onAction: () => supa.auth.signOut(),
          );
        }
        return const HomeScreen();
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.action, required this.onAction});

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                FilledButton(onPressed: onAction, child: Text(action)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

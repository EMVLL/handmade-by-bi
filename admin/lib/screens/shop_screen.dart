import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../texts/app_texts.dart';
import 'history_screen.dart';
import 'identity_screen.dart';
import 'page_blocks_screen.dart';
import 'theme_screen.dart';

/// "Il mio negozio": tutto ciò che riguarda l'aspetto del sito.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget entry(IconData icon, String title, String subtitle, Widget Function() page) => Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(title, style: theme.textTheme.titleMedium),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page())),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.shopTitle),
        actions: [
          IconButton(
            tooltip: t.viewSite,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => launchUrl(Uri.parse(Config.siteUrl)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(t.shopIntro, style: theme.textTheme.bodyMedium),
          ),
          entry(Icons.web_outlined, t.shopHome, t.shopHomeHint, () => const PageBlocksScreen()),
          entry(Icons.palette_outlined, t.shopStyle, t.shopStyleHint, () => const ThemeScreen()),
          entry(Icons.badge_outlined, t.shopIdentity, t.shopIdentityHint, () => const IdentityScreen()),
          entry(Icons.history, t.shopHistory, t.shopHistoryHint, () => const HistoryScreen()),
        ],
      ),
    );
  }
}

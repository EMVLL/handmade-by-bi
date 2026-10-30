import 'package:flutter/material.dart';

import 'categories_screen.dart';
import 'channels_screen.dart';
import '../draft.dart';
import 'preview_screen.dart';
import 'products_screen.dart';
import 'shop_screen.dart';
import '../texts/app_texts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    refreshDraftStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [ProductsScreen(), CategoriesScreen(), ShopScreen(), ChannelsScreen(), PreviewScreen()],
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: draftChanged,
        builder: (context, changed, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) {
            setState(() => _tab = i);
            if (i == 4) refreshDraftStatus();
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: t.tabProducts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.category_outlined),
              selectedIcon: const Icon(Icons.category),
              label: t.tabCategories,
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront),
              label: t.tabShop,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_outlined),
              selectedIcon: const Icon(Icons.chat),
              label: t.tabChannels,
            ),
            NavigationDestination(
              icon: Badge(isLabelVisible: changed, child: const Icon(Icons.visibility_outlined)),
              selectedIcon: Badge(isLabelVisible: changed, child: const Icon(Icons.visibility)),
              label: t.tabPreview,
            ),
          ],
        ),
      ),
    );
  }
}

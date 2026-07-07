import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../consulenza/consulenza_page.dart';
import '../creative/chef_page.dart';
import '../import/import_page.dart';
import '../meal_plan/meal_plan_page.dart';
import '../recipes/recipe_list_page.dart';
import '../settings/settings_page.dart';
import '../shopping/shopping_page.dart';

/// Contenitore con navigazione a tab (equivalente della TabView SwiftUI),
/// più la nuova scheda "Chef" (Chef creativo).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    RecipeListPage(),
    ImportPage(),
    ChefPage(),
    MealPlanPage(),
    ShoppingPage(),
    ConsulenzaPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: l.navRecipes),
          NavigationDestination(
              icon: const Icon(Icons.download_outlined),
              selectedIcon: const Icon(Icons.download),
              label: l.navImport),
          NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome),
              label: l.navChef),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: l.navPlan),
          NavigationDestination(
              icon: const Icon(Icons.shopping_cart_outlined),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: l.navShopping),
          NavigationDestination(
              icon: const Icon(Icons.health_and_safety_outlined),
              selectedIcon: const Icon(Icons.health_and_safety),
              label: l.navConsulenza),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.navSettings),
        ],
      ),
    );
  }
}

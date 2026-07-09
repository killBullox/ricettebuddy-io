import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../consulenza/consulenza_page.dart';
import '../creative/chef_page.dart';
import '../import/import_page.dart';
import '../meal_plan/meal_plan_page.dart';
import '../recipes/recipe_list_page.dart';
import '../settings/settings_page.dart';
import '../shopping/shopping_page.dart';

/// Navigazione a tab snella: in basso solo le voci principali (Ricette, Importa,
/// Consulenza) + "Altro", una tendina con le funzioni secondarie (Chef creativo,
/// Piano pasti, Spesa, Impostazioni). Così la barra resta leggibile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // 0..2 = voci principali (in barra); 3..6 = funzioni nella tendina "Altro".
  static const _pages = [
    RecipeListPage(), // 0
    ImportPage(), // 1
    ConsulenzaPage(), // 2
    ChefPage(), // 3
    MealPlanPage(), // 4
    ShoppingPage(), // 5
    SettingsPage(), // 6
  ];

  Future<void> _openMore() async {
    final l = AppLocalizations.of(context);
    final sel = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _moreTile(3, Icons.auto_awesome, l.navChef),
            _moreTile(4, Icons.calendar_month, l.navPlan),
            _moreTile(5, Icons.shopping_cart, l.navShopping),
            _moreTile(6, Icons.settings, l.navSettings),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (sel != null) setState(() => _index = sel);
  }

  Widget _moreTile(int i, IconData icon, String label) => ListTile(
        leading: Icon(icon,
            color: _index == i ? const Color(0xFFB5326B) : null),
        title: Text(label,
            style: TextStyle(
                fontWeight: _index == i ? FontWeight.w800 : FontWeight.w500,
                color: _index == i ? const Color(0xFFB5326B) : null)),
        onTap: () => Navigator.of(context).pop(i),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index <= 2 ? _index : 3, // >2 → evidenzia "Altro"
        onDestinationSelected: (i) {
          if (i <= 2) {
            setState(() => _index = i);
          } else {
            _openMore();
          }
        },
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
              icon: const Icon(Icons.health_and_safety_outlined),
              selectedIcon: const Icon(Icons.health_and_safety),
              label: l.navConsulenza),
          const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Altro'),
        ],
      ),
    );
  }
}

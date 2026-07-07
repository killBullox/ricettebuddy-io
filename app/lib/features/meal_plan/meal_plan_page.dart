import 'package:flutter/material.dart';
import '../../common/cooking_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/meal_plan_entry.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';
import '../../l10n/app_localizations.dart';

final _weekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
});

class MealPlanPage extends ConsumerWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(_weekStartProvider);
    final entries = ref.watch(mealPlanWeekProvider(weekStart));
    final days = [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mealPlanTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(_weekStartProvider.notifier).state =
              weekStart.subtract(const Duration(days: 7)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(_weekStartProvider.notifier).state =
                weekStart.add(const Duration(days: 7)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.shopping_cart_checkout),
        label: Text(l.generateShopping),
        onPressed: () async {
          final n = await ref
              .read(mealPlanRepositoryProvider)
              .generateShoppingFromWeek(weekStart);
          ref.invalidate(shoppingListProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(n == 0
                  ? 'Nessuna ricetta pianificata questa settimana.'
                  : 'Aggiunte $n voci alla spesa dai pasti della settimana.'),
            ));
          }
        },
      ),
      body: entries.when(
        loading: () => const Center(child: CookingLoader(size: 96)),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final day in days)
              _DaySection(day: day, entries: list, weekStart: weekStart),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DateTime day;
  final DateTime weekStart;
  final List<MealPlanEntry> entries;
  const _DaySection({
    required this.day,
    required this.entries,
    required this.weekStart,
  });

  List<MealPlanEntry> _entriesFor(MealSlot slot) => [
        for (final e in entries)
          if (e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day &&
              e.slot == slot)
            e,
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = DateFormat('EEEE d MMMM').format(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final slot in MealSlot.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: 82,
                    child: Text(slot.labelIt,
                        style: TextStyle(color: Theme.of(context).hintColor)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in _entriesFor(slot))
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEDE6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(e.recipeTitle ?? 'Ricetta',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () async {
                                  await ref
                                      .read(mealPlanRepositoryProvider)
                                      .removeEntry(e.id!);
                                  ref.invalidate(mealPlanWeekProvider(weekStart));
                                },
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Aggiungi'),
                          onPressed: () => _pickRecipe(context, ref, slot),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 12),
      ],
    );
  }

  Future<void> _pickRecipe(
      BuildContext context, WidgetRef ref, MealSlot slot) async {
    final recipes = await ref.read(recipeRepositoryProvider).list();
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<(String, String)>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Scegli una ricetta',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final r in recipes)
              ListTile(
                title: Text(r.title),
                onTap: () => Navigator.pop(context, (r.id!, r.title)),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await ref.read(mealPlanRepositoryProvider).setSlot(
          date: day,
          slot: slot,
          recipeId: chosen.$1,
          recipeTitle: chosen.$2,
        );
    ref.invalidate(mealPlanWeekProvider(weekStart));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/meal_plan_entry.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piano pasti'),
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
        label: const Text('Genera spesa'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
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

  MealPlanEntry? _entry(MealSlot slot) {
    for (final e in entries) {
      if (e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day &&
          e.slot == slot) {
        return e;
      }
    }
    return null;
  }

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
          ListTile(
            dense: true,
            leading: SizedBox(
              width: 90,
              child: Text(slot.labelIt,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ),
            title: Text(_entry(slot)?.recipeTitle ?? '—'),
            trailing: _entry(slot) != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () async {
                      await ref
                          .read(mealPlanRepositoryProvider)
                          .clearSlot(date: day, slot: slot);
                      ref.invalidate(mealPlanWeekProvider(weekStart));
                    },
                  )
                : const Icon(Icons.add, size: 18),
            onTap: () => _pickRecipe(context, ref, slot),
          ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/meal_plan_entry.dart';
import '../../data/repositories/meal_plan_repository.dart';

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
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (list) => ListView(
          children: [
            for (final day in days) _DaySection(day: day, entries: list),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<MealPlanEntry> entries;
  const _DaySection({required this.day, required this.entries});

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
  Widget build(BuildContext context) {
    // Locale esplicito ('it') richiederebbe initializeDateFormatting: per ora
    // usiamo il locale di default. TODO(F8): inizializzare i dati locale.
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
            // TODO(F4): tap → scegli ricetta (setSlot) + regola porzioni.
          ),
      ],
    );
  }
}

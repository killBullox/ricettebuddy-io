import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../common/cooking_loader.dart';
import '../../data/models/enums.dart';
import '../../data/models/meal_plan_entry.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/plan_push_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';
import '../../l10n/app_localizations.dart';
import '../recipes/recipe_detail_page.dart';
import 'auto_planner.dart';
import 'plan_generate_sheet.dart';

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
    final recipes = ref.watch(recipeListProvider);
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
            icon: const Icon(Icons.auto_awesome),
            tooltip: l.planHowTitle,
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => PlanGenerateSheet(weekStart: weekStart),
              );
              ref.invalidate(mealPlanWeekProvider(weekStart));
            },
          ),
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
        loading: () => const Center(
            child: CookingLoader(size: 96, style: BeetLoaderStyle.bounce)),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (list) {
          // Mappa id → ricetta per kcal, tap e replacement.
          final byId = <String, Recipe>{
            for (final r in recipes.valueOrNull ?? <Recipe>[])
              if (r.id != null) r.id!: r,
          };
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              const _PendingPlansBanner(),
              for (final day in days)
                _DaySection(
                  day: day,
                  entries: list,
                  weekStart: weekStart,
                  recipesById: byId,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DateTime day;
  final DateTime weekStart;
  final List<MealPlanEntry> entries;
  final Map<String, Recipe> recipesById;
  const _DaySection({
    required this.day,
    required this.entries,
    required this.weekStart,
    required this.recipesById,
  });

  List<MealPlanEntry> _entriesFor(MealSlot slot) => [
        for (final e in entries)
          if (e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day &&
              e.slot == slot)
            e,
      ];

  double? _entryKcal(MealPlanEntry e) {
    final r = e.recipeId == null ? null : recipesById[e.recipeId!];
    return r == null ? null : kcalOf(r);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final title = DateFormat('EEEE d MMMM').format(day);

    // Totale calorico del giorno (per porzione). "≥" se qualche dato manca.
    final dayEntries = [
      for (final s in MealSlot.values) ..._entriesFor(s),
    ];
    var kcalSum = 0.0;
    var missing = false;
    for (final e in dayEntries) {
      final k = _entryKcal(e);
      if (k == null) {
        missing = true;
      } else {
        kcalSum += k;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (dayEntries.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7E4EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${missing ? '≥ ' : ''}${kcalSum.round()} kcal',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B1A4A)),
                  ),
                ),
            ],
          ),
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
                        _EntryTile(
                          entry: e,
                          kcal: _entryKcal(e),
                          onTap: e.recipeId == null
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailPage(
                                          recipeId: e.recipeId!),
                                    ),
                                  ),
                          onReplace: () =>
                              _replace(context, ref, e, slot),
                          onRemove: () async {
                            await ref
                                .read(mealPlanRepositoryProvider)
                                .removeEntry(e.id!);
                            ref.invalidate(mealPlanWeekProvider(weekStart));
                          },
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l.add),
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

  /// Sostituisce una ricetta del piano con un'altra della STESSA portata.
  Future<void> _replace(BuildContext context, WidgetRef ref, MealPlanEntry e,
      MealSlot slot) async {
    final l = AppLocalizations.of(context);
    final all = await ref.read(recipeRepositoryProvider).list();
    final current = e.recipeId == null ? null : recipesById[e.recipeId!];
    final course = current == null ? null : courseOf(current);
    var candidates = all
        .where((r) => r.id != null && r.id != e.recipeId)
        .where((r) => course == null || courseOf(r) == course)
        .toList();
    if (candidates.isEmpty) {
      candidates =
          all.where((r) => r.id != null && r.id != e.recipeId).toList();
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l.planReplaceTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final r in candidates)
              ListTile(
                title: Text(r.title),
                trailing: kcalOf(r) == null
                    ? null
                    : Text('${kcalOf(r)!.round()} kcal',
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12)),
                onTap: () => Navigator.pop(context, (r.id!, r.title)),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    final repo = ref.read(mealPlanRepositoryProvider);
    await repo.removeEntry(e.id!);
    await repo.setSlot(
        date: day, slot: slot, recipeId: chosen.$1, recipeTitle: chosen.$2);
    ref.invalidate(mealPlanWeekProvider(weekStart));
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

/// Riga di una ricetta pianificata: tap → dettaglio; azioni sostituisci/rimuovi.
class _EntryTile extends StatelessWidget {
  final MealPlanEntry entry;
  final double? kcal;
  final VoidCallback? onTap;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  const _EntryTile({
    required this.entry,
    required this.kcal,
    required this.onTap,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDE6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(entry.recipeTitle ?? 'Ricetta',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 1),
                      child: Text(
                        kcal == null ? '—' : '${kcal!.round()} kcal',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).hintColor),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.swap_horiz, size: 19),
                tooltip: l.planReplace,
                onPressed: onReplace,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner in cima al piano: elenca i piani inviati dal nutrizionista ancora da
/// importare. Importare copia le ricette base nella libreria dell'utente e
/// riempie la settimana (via Edge Function `piano`).
class _PendingPlansBanner extends ConsumerWidget {
  const _PendingPlansBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(pendingPlansProvider);
    return plans.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final df = DateFormat('d MMM', 'it');
        return Column(
          children: [
            for (final p in list)
              Card(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                color: const Color(0xFFEAF5EB),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety,
                          color: Color(0xFF3B8C43)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Piano dal nutrizionista',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              [
                                if (p.weekStart != null)
                                  'Settimana del ${df.format(p.weekStart!)}',
                                '${p.nItems} piatti',
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if ((p.note ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('“${p.note}”',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ImportButton(plan: p),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ImportButton extends ConsumerStatefulWidget {
  final PushedPlan plan;
  const _ImportButton({required this.plan});

  @override
  ConsumerState<_ImportButton> createState() => _ImportButtonState();
}

class _ImportButtonState extends ConsumerState<_ImportButton> {
  bool _busy = false;

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final n = await ref
          .read(planPushRepositoryProvider)
          .importPlan(widget.plan.id);
      // La settimana del piano potrebbe non essere quella visualizzata: porta
      // la vista sulla settimana importata e aggiorna tutto.
      if (widget.plan.weekStart != null) {
        ref.read(_weekStartProvider.notifier).state = widget.plan.weekStart!;
      }
      ref.invalidate(pendingPlansProvider);
      ref.invalidate(recipeListProvider);
      final ws = ref.read(_weekStartProvider);
      ref.invalidate(mealPlanWeekProvider(ws));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Piano importato: $n piatti aggiunti alla settimana.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import non riuscito: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3B8C43)),
      onPressed: _busy ? null : _import,
      child: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Text('Importa'),
    );
  }
}

import 'dart:math';

import '../../data/models/enums.dart';
import '../../data/models/meal_plan_entry.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/recipe_repository.dart';

/// Opzioni del piano automatico (modalità 2).
class AutoPlanOptions {
  final int? maxKcalPerDay; // tetto calorico giornaliero (null = nessun tetto)
  final Set<String> excludeAllergens; // es. {'glutine','soia'}
  final Set<String> labels; // es. {'LOW CARB'}
  final bool includeSnack;

  const AutoPlanOptions({
    this.maxKcalPerDay,
    this.excludeAllergens = const {},
    this.labels = const {},
    this.includeSnack = false,
  });
}

class AutoPlanResult {
  final int filled;
  final int total;
  const AutoPlanResult(this.filled, this.total);
  bool get complete => filled == total;
}

// Quota indicativa del budget calorico per pasto.
const _share = {
  MealSlot.breakfast: 0.25,
  MealSlot.lunch: 0.35,
  MealSlot.snack: 0.10,
  MealSlot.dinner: 0.30,
};

final _breakfastRe = RegExp(
  r'colazion|breakfast|porridge|pancake|crep|smoothie|frullat|muffin|granola|'
  r'biscott|torta|plumcake|crostata|budino|chia|yogurt|overnight',
  caseSensitive: false,
);

bool _isBreakfasty(Recipe r) {
  final hay = '${r.category ?? ''} ${r.tags.join(' ')} ${r.title}';
  return _breakfastRe.hasMatch(hay);
}

double? _kcal(Recipe r) => (r.nutrition?['kcal'] as num?)?.toDouble();

/// Genera il piano della settimana [weekStart] riempiendo colazione/pranzo/cena
/// (+ spuntino) con le ricette dell'utente che rispettano filtri e tetto
/// calorico. Sostituisce il piano esistente della settimana.
Future<AutoPlanResult> generateAutoPlan({
  required MealPlanRepository planRepo,
  required List<Recipe> recipes,
  required List<MealPlanEntry> existing,
  required DateTime weekStart,
  required AutoPlanOptions opts,
}) async {
  final filters = RecipeFilters(
    excludeAllergens: opts.excludeAllergens,
    labels: opts.labels,
  );
  // Candidati: rispettano i filtri; se c'è un tetto kcal servono dati kcal
  // (onestà: senza dati non possiamo garantire il tetto).
  final pool = recipes
      .where((r) =>
          r.id != null &&
          filters.matches(r) &&
          (opts.maxKcalPerDay == null || _kcal(r) != null))
      .toList();

  final breakfasts = pool.where(_isBreakfasty).toList();
  final mains = pool.where((r) => !_isBreakfasty(r)).toList();
  final snacks = pool
      .where((r) => (_kcal(r) ?? 0) <= 300 || _isBreakfasty(r))
      .toList();

  List<Recipe> poolFor(MealSlot s) => switch (s) {
        MealSlot.breakfast => breakfasts.isNotEmpty ? breakfasts : pool,
        MealSlot.snack => snacks.isNotEmpty ? snacks : pool,
        _ => mains.isNotEmpty ? mains : pool,
      };

  // Sostituisce il piano esistente della settimana.
  for (final e in existing) {
    if (e.id != null) await planRepo.removeEntry(e.id!);
  }

  final slots = [
    MealSlot.breakfast,
    MealSlot.lunch,
    if (opts.includeSnack) MealSlot.snack,
    MealSlot.dinner,
  ];
  final rng = Random(weekStart.millisecondsSinceEpoch);
  final used = <String>{};
  var filled = 0;
  final total = 7 * slots.length;

  for (var d = 0; d < 7; d++) {
    final day = weekStart.add(Duration(days: d));
    double remaining = opts.maxKcalPerDay?.toDouble() ?? double.infinity;
    for (final slot in slots) {
      final slotCap = opts.maxKcalPerDay == null
          ? double.infinity
          : (_share[slot]! * opts.maxKcalPerDay! * 1.4);
      var candidates = poolFor(slot)
          .where((r) =>
              (opts.maxKcalPerDay == null ||
                  (_kcal(r)! <= remaining && _kcal(r)! <= slotCap)))
          .toList();
      if (candidates.isEmpty) continue;
      // Preferisci ricette non ancora usate in settimana (varietà).
      final fresh = candidates.where((r) => !used.contains(r.id)).toList();
      if (fresh.isNotEmpty) candidates = fresh;
      final pick = candidates[rng.nextInt(candidates.length)];
      await planRepo.setSlot(
        date: day,
        slot: slot,
        recipeId: pick.id!,
        recipeTitle: pick.title,
      );
      used.add(pick.id!);
      remaining -= _kcal(pick) ?? 0;
      filled++;
    }
  }
  return AutoPlanResult(filled, total);
}

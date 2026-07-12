import 'dart:math';

import '../../data/models/enums.dart';
import '../../data/models/meal_plan_entry.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/meal_plan_repository.dart';
import '../../data/repositories/recipe_repository.dart';

/// Opzioni del piano automatico (modalità 2).
class AutoPlanOptions {
  final int? maxKcalPerDay; // tetto calorico giornaliero (null = nessun tetto)
  final Set<String> excludeAllergens;
  final Set<String> labels;
  final bool includeSnack;
  final bool includeDessert; // dolce a fine pranzo/cena se il budget lo consente

  const AutoPlanOptions({
    this.maxKcalPerDay,
    this.excludeAllergens = const {},
    this.labels = const {},
    this.includeSnack = false,
    this.includeDessert = false,
  });
}

class AutoPlanResult {
  final int filled; // slot pasto riempiti (un pasto = 1 anche se più portate)
  final int total;
  const AutoPlanResult(this.filled, this.total);
  bool get complete => filled == total;
}

/// Portata di una ricetta (per comporre pasti sensati).
enum Course { breakfast, antipasto, primo, secondo, piattoUnico, dolce, snack }

final _reBreakfast = RegExp(
    r'colazion|breakfast|porridge|pancake|crep|smoothie|frullat|granola|overnight|chia|yogurt',
    caseSensitive: false);
final _reDolce = RegExp(
    r'dolce|dessert|tort[ae]|muffin|biscott|budino|crostat|plumcake|gelato|mousse|cioccolat|tiramis',
    caseSensitive: false);
final _reAntipasto = RegExp(
    r'antipast|contorn|insalat|starter|side|bruschett|hummus|crostin|vellutata leggera',
    caseSensitive: false);
final _rePrimo = RegExp(
    r'\bprim[oi]\b|past[a]\b|spaghett|penne|rigaton|risott|gnocch|lasagn|zupp|minestr|vellutat|ramen|noodle',
    caseSensitive: false);
final _reSecondo = RegExp(
    r'\bsecond[oi]\b|polpett|burger|cotolett|arrost|spezzatin|seitan|tempeh|tofu alla|scaloppin|involtin',
    caseSensitive: false);
final _rePiattoUnico = RegExp(
    r'piatto unico|bowl|buddha|poke|one[- ]pot|curry|chili|paella|couscous|cous cous',
    caseSensitive: false);

double? kcalOf(Recipe r) => (r.nutrition?['kcal'] as num?)?.toDouble();

/// Classifica la ricetta in una portata usando categoria, tag e titolo.
Course courseOf(Recipe r) {
  final hay = '${r.category ?? ''} ${r.tags.join(' ')} ${r.title}';
  if (_reBreakfast.hasMatch(hay)) return Course.breakfast;
  if (_reDolce.hasMatch(hay)) return Course.dolce;
  if (_rePiattoUnico.hasMatch(hay)) return Course.piattoUnico;
  if (_rePrimo.hasMatch(hay)) return Course.primo;
  if (_reSecondo.hasMatch(hay)) return Course.secondo;
  if (_reAntipasto.hasMatch(hay)) return Course.antipasto;
  // Fallback sui numeri: piatti sostanziosi = piatto unico, leggeri = antipasto.
  final k = kcalOf(r);
  if (k != null && k >= 350) return Course.piattoUnico;
  return Course.antipasto;
}

// Quota indicativa del budget calorico per pasto.
const _share = {
  MealSlot.breakfast: 0.22,
  MealSlot.lunch: 0.38,
  MealSlot.snack: 0.08,
  MealSlot.dinner: 0.32,
};

/// Combinazioni "normate" per pranzo/cena, in ordine di preferenza casuale:
/// piatto unico | antipasto+primo | antipasto+secondo | primo+secondo |
/// antipasto+primo+secondo.
const _mealCombos = [
  [Course.piattoUnico],
  [Course.primo, Course.secondo],
  [Course.antipasto, Course.primo],
  [Course.antipasto, Course.secondo],
  [Course.antipasto, Course.primo, Course.secondo],
];

/// Genera il piano della settimana [weekStart]: colazione, pranzo e cena
/// composti con criteri da ricettario (piatto unico o combinazioni di portate),
/// dessert e spuntino opzionali, tetto calorico A PERSONA (i valori
/// nutrizionali delle ricette sono per porzione).
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
  final pool = recipes
      .where((r) =>
          r.id != null &&
          filters.matches(r) &&
          (opts.maxKcalPerDay == null || kcalOf(r) != null))
      .toList();

  // Indice per portata.
  final byCourse = <Course, List<Recipe>>{};
  for (final r in pool) {
    byCourse.putIfAbsent(courseOf(r), () => []).add(r);
  }
  // La colazione può attingere anche ai dolci; lo spuntino a dolci leggeri.
  List<Recipe> forCourse(Course c) => switch (c) {
        Course.breakfast => <Recipe>[
            ...?byCourse[Course.breakfast],
            ...?byCourse[Course.dolce],
          ],
        Course.snack => <Recipe>[
            ...(byCourse[Course.dolce] ?? const []),
            ...(byCourse[Course.antipasto] ?? const []),
          ].where((r) => (kcalOf(r) ?? 999) <= 300).toList(),
        _ => byCourse[c] ?? const <Recipe>[],
      };

  // Sostituisce il piano esistente della settimana.
  for (final e in existing) {
    if (e.id != null) await planRepo.removeEntry(e.id!);
  }

  final rng = Random(weekStart.millisecondsSinceEpoch);
  final used = <String>{};
  var filled = 0;
  final slots = [
    MealSlot.breakfast,
    MealSlot.lunch,
    if (opts.includeSnack) MealSlot.snack,
    MealSlot.dinner,
  ];
  final total = 7 * slots.length;

  // Sceglie una ricetta per portata: preferisce le non usate, entro budget.
  Recipe? pick(Course c, double budget) {
    var cands =
        forCourse(c).where((r) => (kcalOf(r) ?? 0) <= budget).toList();
    if (cands.isEmpty) return null;
    final fresh = cands.where((r) => !used.contains(r.id)).toList();
    if (fresh.isNotEmpty) cands = fresh;
    return cands[rng.nextInt(cands.length)];
  }

  Future<bool> place(DateTime day, MealSlot slot, List<Recipe> dishes) async {
    if (dishes.isEmpty) return false;
    for (final r in dishes) {
      await planRepo.setSlot(
          date: day, slot: slot, recipeId: r.id!, recipeTitle: r.title);
      used.add(r.id!);
    }
    return true;
  }

  for (var d = 0; d < 7; d++) {
    final day = weekStart.add(Duration(days: d));
    double remaining = opts.maxKcalPerDay?.toDouble() ?? double.infinity;

    for (final slot in slots) {
      final slotBudget = opts.maxKcalPerDay == null
          ? double.infinity
          : min(remaining, _share[slot]! * opts.maxKcalPerDay! * 1.35);
      var placed = false;

      if (slot == MealSlot.breakfast || slot == MealSlot.snack) {
        final r = pick(
            slot == MealSlot.breakfast ? Course.breakfast : Course.snack,
            slotBudget);
        if (r != null) {
          await place(day, slot, [r]);
          remaining -= kcalOf(r) ?? 0;
          placed = true;
        }
      } else {
        // Pranzo/cena: prova le combinazioni normate in ordine casuale.
        final combos = [..._mealCombos]..shuffle(rng);
        for (final combo in combos) {
          final dishes = <Recipe>[];
          var budget = slotBudget;
          var ok = true;
          for (final course in combo) {
            final r = pick(course, budget);
            if (r == null) {
              ok = false;
              break;
            }
            dishes.add(r);
            budget -= kcalOf(r) ?? 0;
          }
          if (!ok) continue;
          // Dessert opzionale se il budget lo consente.
          if (opts.includeDessert) {
            final dolce = pick(Course.dolce, budget);
            if (dolce != null) dishes.add(dolce);
          }
          await place(day, slot, dishes);
          remaining -=
              dishes.fold<double>(0, (s, r) => s + (kcalOf(r) ?? 0));
          placed = true;
          break;
        }
      }
      if (placed) filled++;
    }
  }
  return AutoPlanResult(filled, total);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
import '../local_api.dart';
import '../models/enums.dart';
import '../models/meal_plan_entry.dart';

class MealPlanRepository {
  final SupabaseClient? _db;
  MealPlanRepository(this._db);

  bool get _demo => Config.demo;
  DemoStore get _store => DemoStore.instance;
  String get _uid => _db!.auth.currentUser!.id;

  Future<List<MealPlanEntry>> forWeek(DateTime weekStart) async {
    final start = _dateOnly(weekStart);
    if (_demo) return _store.mealPlanForWeek(start);
    final end = start.add(const Duration(days: 7));
    final rows = await _db!
        .from('meal_plan_entries')
        .select('*, recipes(title)')
        .gte('date', _fmt(start))
        .lt('date', _fmt(end));
    return (rows as List)
        .map((r) => MealPlanEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Aggiunge una ricetta a uno slot giorno/pasto. Più ricette per pasto sono
  /// permesse (es. primo + secondo + dolce).
  Future<void> setSlot({
    required DateTime date,
    required MealSlot slot,
    required String recipeId,
    String recipeTitle = '',
    int servings = 2,
  }) async {
    if (_demo) return _store.setSlot(date, slot, recipeId, servings, recipeTitle);
    await _db!.from('meal_plan_entries').insert({
      'user_id': _uid,
      'date': _fmt(_dateOnly(date)),
      'slot': slot.name,
      'recipe_id': recipeId,
      'servings': servings,
    });
  }

  /// Rimuove una singola voce (una ricetta) dal piano.
  Future<void> removeEntry(String id) async {
    if (_demo) return _store.removeEntry(id);
    await _db!.from('meal_plan_entries').delete().eq('id', id);
  }

  Future<void> clearSlot({required DateTime date, required MealSlot slot}) async {
    if (_demo) return _store.clearSlotByDaySlot(date, slot);
    await _db!
        .from('meal_plan_entries')
        .delete()
        .eq('date', _fmt(_dateOnly(date)))
        .eq('slot', slot.name);
  }

  /// Genera/aggiorna la spesa a partire dai pasti pianificati nella settimana.
  /// Ritorna il numero di voci aggiunte.
  Future<int> generateShoppingFromWeek(DateTime weekStart) async {
    if (_demo) {
      final ids = _store.plannedRecipeIds(_dateOnly(weekStart));
      var added = 0;
      for (final id in ids) {
        try {
          final r = await localApi.getRecipe(id);
          _store.addShoppingFromRecipe(r);
          added += r.ingredients.length;
        } catch (_) {}
      }
      return added;
    }
    // Reale: gestito lato server / o iterando le ricette; TODO fase backend.
    return 0;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _fmt(DateTime d) => d.toIso8601String().split('T').first;
}

final mealPlanRepositoryProvider = Provider<MealPlanRepository>(
  (ref) =>
      MealPlanRepository(Config.demo ? null : Supabase.instance.client),
);

final mealPlanWeekProvider = FutureProvider.autoDispose
    .family<List<MealPlanEntry>, DateTime>((ref, weekStart) {
  return ref.watch(mealPlanRepositoryProvider).forWeek(weekStart);
});

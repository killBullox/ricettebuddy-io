import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
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

  /// Assegna (o sostituisce) una ricetta a uno slot giorno/pasto.
  Future<void> setSlot({
    required DateTime date,
    required MealSlot slot,
    required String recipeId,
    int servings = 2,
  }) async {
    if (_demo) return; // gestione slot demo non necessaria per il test UI
    await _db!.from('meal_plan_entries').upsert({
      'user_id': _uid,
      'date': _fmt(_dateOnly(date)),
      'slot': slot.name,
      'recipe_id': recipeId,
      'servings': servings,
    }, onConflict: 'user_id,date,slot');
  }

  Future<void> clearSlot(String id) async {
    if (_demo) return;
    await _db!.from('meal_plan_entries').delete().eq('id', id);
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

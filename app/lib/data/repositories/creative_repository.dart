import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_step.dart';

/// Una ricetta del ricettario fattibile con la dispensa attuale.
class DoableRecipe {
  final String recipeId;
  final String title;
  final int totalNamed;
  final int haveCount;
  final double coverage; // 0..1
  final List<String> missing;

  const DoableRecipe({
    required this.recipeId,
    required this.title,
    required this.totalNamed,
    required this.haveCount,
    required this.coverage,
    required this.missing,
  });

  factory DoableRecipe.fromMap(Map<String, dynamic> m) => DoableRecipe(
        recipeId: m['recipe_id'] as String,
        title: m['title'] as String? ?? '',
        totalNamed: (m['total_named'] as int?) ?? 0,
        haveCount: (m['have_count'] as int?) ?? 0,
        coverage: (m['coverage'] as num?)?.toDouble() ?? 0,
        missing: (m['missing_names'] as List?)?.cast<String>() ?? const [],
      );
}

/// "Chef creativo": ricette fattibili dal ricettario + idee nuove generate.
class CreativeRepository {
  final SupabaseClient? _db;
  CreativeRepository(this._db);

  bool get _demo => Config.demo;
  DemoStore get _store => DemoStore.instance;

  /// Sezione "Puoi già farle" — via RPC su Postgres (nessun costo AI).
  Future<List<DoableRecipe>> doableFromPantry({double minCoverage = 0.6}) async {
    if (_demo) return _store.doableFromPantry(minCoverage: minCoverage);
    final rows = await _db!.rpc(
      'recipes_doable_from_pantry',
      params: {'min_coverage': minCoverage},
    );
    return (rows as List)
        .map((r) => DoableRecipe.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Sezione "Idee nuove" — Edge Function server-side (usa dispensa + gusti +
  /// vincoli; l'AI e le API key stanno sul server). Ritorna bozze non salvate
  /// con `source = generated`.
  Future<List<Recipe>> generateIdeas({
    int count = 3,
    int? maxMinutes,
    List<String> diet = const [],
    List<String> excludeAllergens = const [],
  }) async {
    if (_demo) return _store.generateIdeas(count: count);
    final res = await _db!.functions.invoke('creative-generate', body: {
      'count': count,
      'max_minutes': maxMinutes,
      'diet': diet,
      'exclude_allergens': excludeAllergens,
    });
    final data = res.data as Map<String, dynamic>;
    final list = (data['recipes'] as List?) ?? const [];
    return list.map((r) {
      final m = r as Map<String, dynamic>;
      return Recipe.fromMap(
        {...m, 'source_type': 'generated'},
        ingredients: ((m['ingredients'] as List?) ?? const [])
            .map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
            .toList(),
        steps: ((m['steps'] as List?) ?? const [])
            .map((e) => RecipeStep.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
  }
}

final creativeRepositoryProvider = Provider<CreativeRepository>(
  (ref) =>
      CreativeRepository(Config.demo ? null : Supabase.instance.client),
);

final doableRecipesProvider =
    FutureProvider.autoDispose<List<DoableRecipe>>((ref) {
  return ref.watch(creativeRepositoryProvider).doableFromPantry();
});

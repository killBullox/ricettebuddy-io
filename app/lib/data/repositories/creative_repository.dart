import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
import '../local_api.dart';
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

  /// Sezione "Puoi già farle" — ricette (reali) fattibili con la dispensa.
  Future<List<DoableRecipe>> doableFromPantry({double minCoverage = 0.6}) async {
    if (_demo) {
      final recipes = await localApi.listRecipes();
      final have = _store.pantry
          .map((p) => p.normalizedName.toLowerCase())
          .toSet();
      final out = <DoableRecipe>[];
      for (final r in recipes) {
        // usa i nomi normalizzati se presenti, altrimenti il testo grezzo
        final names = r.ingredients
            .map((i) => (i.normalizedName ?? i.rawText).toLowerCase())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        if (names.isEmpty) continue;
        final missing = names
            .where((n) => !have.any((h) => n.contains(h) || h.contains(n)))
            .toSet()
            .toList();
        final haveCount = names.length - missing.length;
        final coverage = haveCount / names.length;
        if (coverage >= minCoverage && r.id != null) {
          out.add(DoableRecipe(
            recipeId: r.id!,
            title: r.title,
            totalNamed: names.length,
            haveCount: haveCount,
            coverage: double.parse(coverage.toStringAsFixed(2)),
            missing: missing,
          ));
        }
      }
      out.sort((a, b) => b.coverage.compareTo(a.coverage));
      return out;
    }
    final rows = await _db!.rpc(
      'recipes_doable_from_pantry',
      params: {'min_coverage': minCoverage},
    );
    return (rows as List)
        .map((r) => DoableRecipe.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Sezione "Idee nuove" — generazione AI server-side (usa dispensa + gusti +
  /// vincoli; l'AI e le API key stanno sul server). Ritorna bozze non salvate
  /// con `source = generated`.
  Future<List<Recipe>> generateIdeas({
    int count = 3,
    int? maxMinutes,
    List<String> labels = const [],
    List<String> excludeAllergens = const [],
  }) async {
    if (_demo) {
      final pantry = _store.pantry
          .map((p) => p.normalizedName)
          .where((s) => s.trim().isNotEmpty)
          .toList();
      return localApi.chefGenerate(
        pantry: pantry,
        maxMinutes: maxMinutes,
        labels: labels,
        excludeAllergens: excludeAllergens,
        count: count,
      );
    }
    final res = await _db!.functions.invoke('creative-generate', body: {
      'count': count,
      'max_minutes': maxMinutes,
      'labels': labels,
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

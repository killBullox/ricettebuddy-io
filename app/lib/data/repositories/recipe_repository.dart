import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../features/recipes/recipe_course.dart';
import '../local_api.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_step.dart';

class RecipeRepository {
  final SupabaseClient? _db;
  RecipeRepository(this._db);

  bool get _demo => Config.demo;
  String get _uid => _db!.auth.currentUser!.id;

  /// Elenco ricette (senza relazioni, per la lista).
  Future<List<Recipe>> list({String? search}) async {
    if (_demo) return localApi.listRecipes(search: search);
    var query = _db!.from('recipes').select();
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }
    final rows = await query.order('updated_at', ascending: false);
    return (rows as List)
        .map((r) => Recipe.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Ricetta completa con ingredienti e passi.
  Future<Recipe> getFull(String id) async {
    if (_demo) return localApi.getRecipe(id);
    final row = await _db!.from('recipes').select().eq('id', id).single();
    final ing = await _db
        .from('ingredients')
        .select()
        .eq('recipe_id', id)
        .order('position');
    final steps = await _db
        .from('steps')
        .select()
        .eq('recipe_id', id)
        .order('position');
    return Recipe.fromMap(
      row,
      ingredients: (ing as List)
          .map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
          .toList(),
      steps: (steps as List)
          .map((e) => RecipeStep.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Inserisce ricetta + ingredienti + passi. Ritorna l'id creato.
  Future<String> create(Recipe recipe) async {
    if (_demo) return localApi.createRecipe(recipe);
    final inserted = await _db!
        .from('recipes')
        .insert({...recipe.toMap(), 'user_id': _uid})
        .select('id')
        .single();
    final id = inserted['id'] as String;

    if (recipe.ingredients.isNotEmpty) {
      await _db.from('ingredients').insert([
        for (final (i, ing) in recipe.ingredients.indexed)
          {...ing.toMap(), 'recipe_id': id, 'user_id': _uid, 'position': i}
      ]);
    }
    if (recipe.steps.isNotEmpty) {
      await _db.from('steps').insert([
        for (final (i, s) in recipe.steps.indexed)
          {...s.toMap(), 'recipe_id': id, 'user_id': _uid, 'position': i}
      ]);
    }
    return id;
  }

  /// Aggiorna una ricetta esistente con i suoi ingredienti e passi.
  Future<void> update(String id, Recipe recipe) async {
    if (_demo) return localApi.updateRecipe(id, recipe);
    await _db!.from('recipes').update(recipe.toMap()).eq('id', id);
    // Sostituisce ingredienti e passi.
    await _db.from('ingredients').delete().eq('recipe_id', id);
    await _db.from('steps').delete().eq('recipe_id', id);
    if (recipe.ingredients.isNotEmpty) {
      await _db.from('ingredients').insert([
        for (final (i, ing) in recipe.ingredients.indexed)
          {...ing.toMap(), 'recipe_id': id, 'user_id': _uid, 'position': i}
      ]);
    }
    if (recipe.steps.isNotEmpty) {
      await _db.from('steps').insert([
        for (final (i, s) in recipe.steps.indexed)
          {...s.toMap(), 'recipe_id': id, 'user_id': _uid, 'position': i}
      ]);
    }
  }

  Future<void> setFavorite(String id, bool value) async {
    if (_demo) return localApi.setFavorite(id, value);
    await _db!.from('recipes').update({'is_favorite': value}).eq('id', id);
  }

  Future<void> setServings(String id, int servings) async {
    if (_demo) return localApi.setServings(id, servings);
    await _db!.from('recipes').update({'servings': servings}).eq('id', id);
  }

  Future<void> delete(String id) async {
    if (_demo) return localApi.deleteRecipe(id);
    await _db!.from('recipes').delete().eq('id', id);
  }

  /// Rielabora la ricetta dalla fonte (foto, label, CO2, img ingredienti).
  Future<void> refreshFromSource(String id) async {
    if (_demo) {
      await localApi.refreshRecipe(id);
      return;
    }
    // Con Supabase il refresh avverrà nella Edge Function (non ancora attivo).
  }
}

RecipeRepository _make() =>
    RecipeRepository(Config.demo ? null : Supabase.instance.client);

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) => _make());

/// Lista ricette filtrata per testo di ricerca.
final recipeSearchProvider = StateProvider<String>((ref) => '');

final recipeListProvider = FutureProvider.autoDispose<List<Recipe>>((ref) {
  final search = ref.watch(recipeSearchProvider);
  return ref.watch(recipeRepositoryProvider).list(search: search);
});

/// Filtri avanzati per la ricerca ricette: regimi (glutine/soia/lattosio…),
/// label nutrizionali (HIGH PROTEIN, LOW CARB…) e soglie nutrizionali PER
/// PORZIONE (kcal max, proteine min).
class RecipeFilters {
  final Set<String> diets; // Diet.name richiesti
  final Set<String> excludeAllergens; // allergeni da escludere (es. "soia")
  final Set<String> labels; // label nutrizionali richieste
  final Set<String> courses; // portate richieste (OR): Primi, Antipasti, ...
  final Set<String> traits; // caratteristiche (AND): Facile, Veloce, Di stagione
  final int? maxKcal; // per porzione
  final int? minProtein; // g per porzione

  const RecipeFilters({
    this.diets = const {},
    this.excludeAllergens = const {},
    this.labels = const {},
    this.courses = const {},
    this.traits = const {},
    this.maxKcal,
    this.minProtein,
  });

  bool get isEmpty =>
      diets.isEmpty &&
      excludeAllergens.isEmpty &&
      labels.isEmpty &&
      courses.isEmpty &&
      traits.isEmpty &&
      maxKcal == null &&
      minProtein == null;

  int get count =>
      diets.length +
      excludeAllergens.length +
      labels.length +
      courses.length +
      traits.length +
      (maxKcal != null ? 1 : 0) +
      (minProtein != null ? 1 : 0);

  RecipeFilters copyWith({
    Set<String>? diets,
    Set<String>? excludeAllergens,
    Set<String>? labels,
    Set<String>? courses,
    Set<String>? traits,
    int? maxKcal,
    int? minProtein,
    bool clearMaxKcal = false,
    bool clearMinProtein = false,
  }) =>
      RecipeFilters(
        diets: diets ?? this.diets,
        excludeAllergens: excludeAllergens ?? this.excludeAllergens,
        labels: labels ?? this.labels,
        courses: courses ?? this.courses,
        traits: traits ?? this.traits,
        maxKcal: clearMaxKcal ? null : (maxKcal ?? this.maxKcal),
        minProtein: clearMinProtein ? null : (minProtein ?? this.minProtein),
      );

  bool matches(Recipe r) {
    for (final d in diets) {
      if (!r.dietTags.contains(d)) return false;
    }
    if (excludeAllergens.isNotEmpty) {
      final all = r.allergens.map((a) => a.toLowerCase()).toList();
      for (final ex in excludeAllergens) {
        if (all.any((a) => a.contains(ex))) return false;
      }
    }
    if (labels.isNotEmpty) {
      final have = r.nutritionLabels.toSet();
      for (final l in labels) {
        if (!have.contains(l)) return false;
      }
    }
    // Portata: la ricetta passa se rientra in ALMENO una portata selezionata.
    if (courses.isNotEmpty && !courses.any((c) => recipeInCourse(r, c))) {
      return false;
    }
    // Caratteristiche: devono valere TUTTE quelle selezionate (facile E veloce…).
    for (final t in traits) {
      if (!recipeHasTrait(r, t)) return false;
    }
    final kcal = (r.nutrition?['kcal'] as num?)?.toDouble();
    if (maxKcal != null && (kcal == null || kcal > maxKcal!)) return false;
    final protein = (r.nutrition?['protein_g'] as num?)?.toDouble();
    if (minProtein != null && (protein == null || protein < minProtein!)) {
      return false;
    }
    return true;
  }
}

final recipeFiltersProvider =
    StateProvider<RecipeFilters>((ref) => const RecipeFilters());

/// Ordinamento della lista ricette.
enum RecipeSort { recenti, kcalAsc, kcalDesc, nomeAZ }

final recipeSortProvider = StateProvider<RecipeSort>((ref) => RecipeSort.recenti);

/// Lista finale mostrata: testo (server) + filtri avanzati + ordinamento (client).
final filteredRecipeListProvider =
    FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final list = await ref.watch(recipeListProvider.future);
  final f = ref.watch(recipeFiltersProvider);
  final sort = ref.watch(recipeSortProvider);
  var out = f.isEmpty ? list : list.where(f.matches).toList();
  if (sort != RecipeSort.recenti) {
    double kc(Recipe r) => (r.nutrition?['kcal'] as num?)?.toDouble() ?? -1;
    out = [...out];
    switch (sort) {
      case RecipeSort.kcalAsc:
        // le ricette senza kcal (-1) finiscono in fondo
        out.sort((a, b) {
          final ka = kc(a), kb = kc(b);
          if (ka < 0 && kb < 0) return 0;
          if (ka < 0) return 1;
          if (kb < 0) return -1;
          return ka.compareTo(kb);
        });
      case RecipeSort.kcalDesc:
        out.sort((a, b) => kc(b).compareTo(kc(a)));
      case RecipeSort.nomeAZ:
        out.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case RecipeSort.recenti:
        break;
    }
  }
  return out;
});

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe, String>((ref, id) {
  return ref.watch(recipeRepositoryProvider).getFull(id);
});

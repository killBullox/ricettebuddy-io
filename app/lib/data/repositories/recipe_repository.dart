import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
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

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe, String>((ref, id) {
  return ref.watch(recipeRepositoryProvider).getFull(id);
});

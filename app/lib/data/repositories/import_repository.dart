import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_step.dart';

/// Import ricette. L'estrazione robusta (JSON-LD, fallback euristico,
/// structuring AI di video/foto, traduzione) avviene nella Edge Function
/// `import-recipe`, così le API key restano lato server e i parser si
/// aggiornano senza rilasciare una nuova build.
class ImportRepository {
  final SupabaseClient? _db;
  ImportRepository(this._db);

  bool get _demo => Config.demo;
  String get _uid => _db!.auth.currentUser!.id;

  /// Importa da un URL (web o social) e salva la ricetta. Ritorna l'id.
  Future<String> importFromUrl(String url) async {
    if (_demo) return DemoStore.instance.importFromUrl(url);
    final res = await _db!.functions.invoke('import-recipe', body: {'url': url});
    final data = res.data as Map<String, dynamic>;
    final recipe = _parse(data);
    return _save(recipe);
  }

  Recipe _parse(Map<String, dynamic> m) => Recipe.fromMap(
        m,
        ingredients: ((m['ingredients'] as List?) ?? const [])
            .map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
            .toList(),
        steps: ((m['steps'] as List?) ?? const [])
            .map((e) => RecipeStep.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Future<String> _save(Recipe recipe) async {
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
}

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) =>
      ImportRepository(Config.demo ? null : Supabase.instance.client),
);

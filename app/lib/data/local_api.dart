import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/diet.dart';
import 'models/recipe.dart';

/// Client per il backend locale (server Node): import reale da GialloZafferano
/// con persistenza su file. Attivo in modalità locale/demo.
class LocalApi {
  /// Base URL: sul web usa la stessa origine da cui è servita l'app.
  static Uri _u(String path) => Uri.base.resolve(path);

  Future<List<Recipe>> listRecipes({String? search}) async {
    final res = await http.get(_u('api/recipes'));
    final list = (jsonDecode(res.body) as List)
        .map((e) => Recipe.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      return list.where((r) => r.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<Recipe> getRecipe(String id) async {
    final res = await http.get(_u('api/recipes/$id'));
    return Recipe.fromMap(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

  Future<String> createRecipe(Recipe r) async {
    final res = await http.post(_u('api/recipes'),
        headers: _json, body: jsonEncode(r.toApiMap()));
    return (jsonDecode(res.body) as Map)['id'].toString();
  }

  Future<void> updateRecipe(String id, Recipe r) =>
      http.put(_u('api/recipes/$id'),
          headers: _json, body: jsonEncode(r.toApiMap()));

  Future<void> deleteRecipe(String id) => http.delete(_u('api/recipes/$id'));

  Future<void> setFavorite(String id, bool value) => http.put(
      _u('api/recipes/$id'),
      headers: _json,
      body: jsonEncode({'is_favorite': value}));

  Future<void> setServings(String id, int servings) => http.put(
      _u('api/recipes/$id'),
      headers: _json,
      body: jsonEncode({'servings': servings}));

  Future<Recipe> importUrl(String url) async {
    final res = await http.post(_u('api/import-url'),
        headers: _json, body: jsonEncode({'url': url}));
    if (res.statusCode >= 400) {
      throw Exception((jsonDecode(res.body) as Map)['error'] ?? 'Import fallito');
    }
    return Recipe.fromMap(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

  /// Analizza le sorgenti e importa le ricette conformi ai regimi. Ritorna
  /// le ricette importate.
  Future<List<Recipe>> analyze(Set<Diet> diets, {int limit = 24}) async {
    final res = await http
        .post(_u('api/analyze'),
            headers: _json,
            body: jsonEncode({'diets': Diet.toNames(diets), 'limit': limit}))
        .timeout(const Duration(seconds: 120));
    final data = jsonDecode(res.body) as Map;
    return ((data['imported'] as List?) ?? [])
        .map((e) => Recipe.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static const _json = {'Content-Type': 'application/json'};
}

final localApi = LocalApi();

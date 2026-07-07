import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'models/diet.dart';
import 'models/feed_source.dart';
import 'models/recipe.dart';

/// Client per il backend locale (server Node): import reale da GialloZafferano
/// con persistenza su file. Attivo in modalità locale/demo.
class LocalApi {
  /// Base URL: su mobile usa `API_BASE` (backend pubblico); sul web la stessa
  /// origine da cui è servita l'app.
  static Uri _u(String path) => Config.apiBase.isNotEmpty
      ? Uri.parse('${Config.apiBase}/$path')
      : Uri.base.resolve(path);

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

  Future<({Recipe recipe, bool duplicate})> importUrl(String url) async {
    final res = await http.post(_u('api/import-url'),
        headers: _json, body: jsonEncode({'url': url}));
    if (res.statusCode >= 400) {
      throw Exception((jsonDecode(res.body) as Map)['error'] ?? 'Import fallito');
    }
    final m = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    return (recipe: Recipe.fromMap(m), duplicate: m['duplicate'] == true);
  }

  /// Analizza una sorgente e importa le ricette conformi ai regimi. Ritorna
  /// le ricette importate. Lancia un'eccezione col messaggio se la sorgente
  /// non è supportata (es. social).
  Future<List<Recipe>> analyze(FeedSource source, Set<Diet> diets,
      {int limit = 30}) async {
    final res = await http
        .post(_u('api/analyze'),
            headers: _json,
            body: jsonEncode({
              'type': source.type.name,
              'reference': source.reference,
              'diets': Diet.toNames(diets),
              'limit': limit,
            }))
        .timeout(const Duration(seconds: 180));
    final data = jsonDecode(res.body) as Map;
    if (data['unsupported'] == true) {
      throw Exception(data['message'] ?? 'Sorgente non supportata');
    }
    return ((data['imported'] as List?) ?? [])
        .map((e) => Recipe.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static const _json = {'Content-Type': 'application/json'};
}

final localApi = LocalApi();

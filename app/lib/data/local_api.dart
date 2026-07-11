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
  static Uri _u(String path) => Config.backendUri(path);

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

  /// Scansione dispensa: foto (jpeg base64) → alimenti riconosciuti dall'AI.
  Future<List<Map<String, dynamic>>> scanPantry(String base64Jpeg) async {
    final res = await http
        .post(_u('api/scan-pantry'),
            headers: _json, body: jsonEncode({'image': base64Jpeg}))
        .timeout(const Duration(seconds: 90));
    if (res.statusCode >= 400) {
      throw Exception(
          (jsonDecode(res.body) as Map)['error'] ?? 'Scansione non riuscita');
    }
    return (((jsonDecode(res.body) as Map)['items'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Chef AI: genera ricette originali (bozze non salvate) dalla dispensa e
  /// dai vincoli scelti. Operazione AI lunga (~1-2 minuti per 3 ricette).
  Future<List<Recipe>> chefGenerate({
    required List<String> pantry,
    int? maxMinutes,
    List<String> labels = const [],
    List<String> excludeAllergens = const [],
    int count = 3,
  }) async {
    final res = await http
        .post(_u('api/chef'),
            headers: _json,
            body: jsonEncode({
              'pantry': pantry,
              'max_minutes': maxMinutes,
              'labels': labels,
              'exclude_allergens': excludeAllergens,
              'count': count,
            }))
        .timeout(const Duration(seconds: 240));
    if (res.statusCode >= 400) {
      throw Exception(
          (jsonDecode(res.body) as Map)['error'] ?? 'Generazione non riuscita');
    }
    final data = jsonDecode(res.body) as Map;
    return ((data['recipes'] as List?) ?? const [])
        .map((e) => Recipe.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Aggiorna la FOTO della ricetta: il server la ri-estrae dalla fonte e la
  /// salva in cache locale (veloce, pochi secondi).
  Future<Recipe> refreshRecipe(String id) async {
    final res = await http
        .post(_u('api/recipes/$id/refresh'))
        .timeout(const Duration(seconds: 60));
    if (res.statusCode >= 400) {
      throw Exception((jsonDecode(res.body) as Map)['error'] ?? 'Aggiornamento fallito');
    }
    return Recipe.fromMap(Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

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

  /// Enrich AI su testo GIÀ estratto sul dispositivo (social). Il server fa solo
  /// veganizzazione/struttura/quantità e **streamma** le fasi REALI (SSE): via
  /// [onPhase] arrivano man mano che l'AI genera davvero i campi.
  Future<({Recipe recipe, bool duplicate})> enrichExtracted({
    required String title,
    required String text,
    String? imageUrl,
    required String sourceUrl,
    void Function(String phase)? onPhase,
  }) async {
    final req = http.Request('POST', _u('api/enrich'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'title': title,
        'text': text,
        'image_url': imageUrl,
        'source_url': sourceUrl,
      });
    final client = http.Client();
    try {
      final resp =
          await client.send(req).timeout(const Duration(seconds: 60));
      if (resp.statusCode >= 400) {
        throw Exception('Import fallito (${resp.statusCode})');
      }
      Map<String, dynamic>? done;
      String? error;
      var buffer = '';
      String? event;
      // Il server manda un heartbeat ogni 10s: gap lunghi = connessione morta.
      await for (final chunk
          in resp.stream.transform(utf8.decoder).timeout(
        const Duration(seconds: 90),
      )) {
        buffer += chunk;
        int nl;
        while ((nl = buffer.indexOf('\n')) >= 0) {
          final line = buffer.substring(0, nl).trimRight();
          buffer = buffer.substring(nl + 1);
          if (line.isEmpty) {
            event = null;
          } else if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            final d = line.substring(5).trim();
            if (event == 'phase') {
              try {
                onPhase?.call((jsonDecode(d) as Map)['phase'].toString());
              } catch (_) {}
            } else if (event == 'done') {
              done = Map<String, dynamic>.from(jsonDecode(d) as Map);
            } else if (event == 'error') {
              try {
                error = (jsonDecode(d) as Map)['error']?.toString();
              } catch (_) {
                error = d;
              }
            }
          }
        }
      }
      if (error != null) throw Exception(error);
      if (done == null) throw Exception('Import fallito');
      return (recipe: Recipe.fromMap(done), duplicate: done['duplicate'] == true);
    } finally {
      client.close();
    }
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

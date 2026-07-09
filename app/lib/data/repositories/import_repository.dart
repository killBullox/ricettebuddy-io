import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../features/import/social_extractor.dart';
import '../local_api.dart';
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

  /// Importa da un URL (web o social) e salva la ricetta. Ritorna l'id e se era
  /// un doppione (ricetta già presente in libreria).
  static final _socialRe = RegExp(
    r'instagram\.com|facebook\.com|fb\.watch|tiktok\.com|youtube\.com|youtu\.be|pinterest\.',
    caseSensitive: false,
  );

  /// True se l'URL è un social (estrazione sul dispositivo).
  static bool isSocial(String url) => _socialRe.hasMatch(url);

  /// True se è un link Facebook (gestito con webview di login dedicata).
  static bool isFacebook(String url) =>
      RegExp(r'facebook\.com|fb\.watch', caseSensitive: false).hasMatch(url);

  /// Enrich AI a partire da un post GIÀ estratto (es. reel Facebook letto dalla
  /// webview loggata). Streamma le fasi reali via [onPhase].
  Future<({String id, bool duplicate})> importFromExtracted(
    ExtractedPost post, {
    void Function(String phase)? onPhase,
  }) async {
    if (_demo) {
      final r = await localApi.enrichExtracted(
        title: post.title,
        text: post.text,
        imageUrl: post.imageUrl,
        sourceUrl: post.sourceUrl,
        onPhase: onPhase,
      );
      return (id: r.recipe.id!, duplicate: r.duplicate);
    }
    final res =
        await _db!.functions.invoke('import-recipe', body: {'text': post.text});
    final recipe = _parse(res.data as Map<String, dynamic>);
    return (id: await _save(recipe), duplicate: false);
  }

  /// Importa da testo GIÀ disponibile (fallback: l'utente incolla la ricetta,
  /// es. da un reel Facebook non leggibile senza login).
  Future<({String id, bool duplicate})> importFromText({
    required String text,
    String? title,
    String? imageUrl,
    String? sourceUrl,
  }) async {
    if (_demo) {
      final r = await localApi.enrichExtracted(
        title: title ?? '',
        text: text,
        imageUrl: imageUrl,
        sourceUrl: sourceUrl ?? '',
      );
      return (id: r.recipe.id!, duplicate: r.duplicate);
    }
    final res = await _db!.functions.invoke('import-recipe', body: {'text': text});
    final recipe = _parse(res.data as Map<String, dynamic>);
    return (id: await _save(recipe), duplicate: false);
  }

  /// [onPhase] riceve i passi REALI: 'reading' (estrazione sul dispositivo),
  /// poi 'processing' (elaborazione AI). Serve al loader per mostrare fasi vere.
  Future<({String id, bool duplicate})> importFromUrl(String url,
      {void Function(String phase)? onPhase}) async {
    if (_demo) {
      // Social su mobile: estraiamo SUL DISPOSITIVO (connessione/login utente),
      // il server fa solo l'AI. Siti web e web-build: parsing lato server.
      if (!kIsWeb && _socialRe.hasMatch(url)) {
        onPhase?.call('reading'); // fase reale: estrazione sul dispositivo
        final post = await SocialExtractor.extract(url);
        // Da qui le fasi arrivano dallo STREAM dell'AI (reali), via onPhase.
        final r = await localApi.enrichExtracted(
          title: post.title,
          text: post.text,
          imageUrl: post.imageUrl,
          sourceUrl: post.sourceUrl,
          onPhase: onPhase,
        );
        return (id: r.recipe.id!, duplicate: r.duplicate);
      }
      onPhase?.call('processing');
      final r = await localApi.importUrl(url);
      return (id: r.recipe.id!, duplicate: r.duplicate);
    }
    onPhase?.call('processing');
    final res = await _db!.functions.invoke('import-recipe', body: {'url': url});
    final data = res.data as Map<String, dynamic>;
    final recipe = _parse(data);
    return (id: await _save(recipe), duplicate: false);
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

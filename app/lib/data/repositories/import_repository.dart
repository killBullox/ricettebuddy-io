import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../features/import/social_extractor.dart';
import '../local_api.dart';

/// Import ricette. L'estrazione robusta (JSON-LD, fallback euristico,
/// structuring AI di video/foto, traduzione) avviene nella Edge Function
/// `import-recipe`, così le API key restano lato server e i parser si
/// aggiornano senza rilasciare una nuova build.
class ImportRepository {
  final SupabaseClient? _db;
  ImportRepository(this._db);

  bool get _demo => Config.demo;

  /// Invoca la Edge Function import-recipe (che salva la ricetta) e ne ricava
  /// l'id. Apre l'errore vero della funzione se fallisce.
  Future<({String id, bool duplicate})> _invokeImport(
      Map<String, dynamic> body) async {
    try {
      final res = await _db!.functions.invoke('import-recipe', body: body);
      final data = res.data as Map<String, dynamic>;
      return (id: data['id'] as String, duplicate: data['duplicate'] == true);
    } on FunctionException catch (e) {
      final d = e.details;
      final msg = (d is Map && d['error'] != null) ? d['error'].toString() : null;
      throw Exception(msg ?? 'Import non riuscito (${e.status})');
    }
  }

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
    return _invokeImport({
      'text': post.text,
      'title': post.title,
      if (post.imageUrl != null) 'image_url': post.imageUrl,
      'source_url': post.sourceUrl,
    });
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
    return _invokeImport({
      'text': text,
      if (title != null) 'title': title,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sourceUrl != null) 'source_url': sourceUrl,
    });
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
    // Social (il percorso che funzionava): PRIMA il server (yt-dlp sul VPS,
    // /api/extract-social) — legge la didascalia di FB/IG/TikTok/YT senza login;
    // se il server non ce la fa, ripiego ON-DEVICE (YouTube InnerTube, ecc.).
    // Poi enrich+salvataggio su Supabase (import-recipe {text}).
    if (!kIsWeb && isSocial(url)) {
      onPhase?.call('reading');
      ExtractedPost? post;
      try {
        post = await SocialExtractor.extractViaServer(url);
      } catch (_) {
        post = null;
      }
      if (post == null || post.text.trim().length < 40) {
        try {
          post = await SocialExtractor.extract(url);
        } catch (_) {
          post = null;
        }
      }
      if (post == null || post.text.trim().length < 20) {
        throw Exception(
            'Non riesco a leggere la ricetta da questo link. Prova a condividere '
            'il post dall\'app (Condividi → Beet It!) o incolla il testo.');
      }
      onPhase?.call('processing');
      return _invokeImport({
        'text': post.text,
        'title': post.title,
        if (post.imageUrl != null) 'image_url': post.imageUrl,
        'source_url': post.sourceUrl,
      });
    }
    onPhase?.call('processing');
    return _invokeImport({'url': url});
  }
}

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) =>
      ImportRepository(Config.demo ? null : Supabase.instance.client),
);

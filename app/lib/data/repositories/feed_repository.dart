import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
import '../local_api.dart';
import '../models/diet.dart';
import '../models/feed_source.dart';
import '../models/recipe.dart';

/// Gestione sorgenti/feed e analisi con auto-import filtrato per regime.
/// Reale: tabella `feed_sources` + Edge Function `analyze-feed`.
class FeedRepository {
  final SupabaseClient? _db;
  FeedRepository(this._db);

  bool get _demo => Config.demo;
  DemoStore get _store => DemoStore.instance;
  String get _uid => _db!.auth.currentUser!.id;

  Future<List<FeedSource>> list() async {
    if (_demo) return [..._store.sources];
    final rows = await _db!.from('feed_sources').select().order('name');
    return (rows as List)
        .map((r) => FeedSource.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(FeedSource s) async {
    if (_demo) {
      _store.addSource(s);
      return;
    }
    await _db!.from('feed_sources').insert({...s.toMap(), 'user_id': _uid});
  }

  Future<void> delete(String id) async {
    if (_demo) return _store.deleteSource(id);
    await _db!.from('feed_sources').delete().eq('id', id);
  }

  Future<void> setAutoImport(String id, bool value) async {
    if (_demo) return _store.toggleSourceAuto(id, value);
    await _db!.from('feed_sources').update({'auto_import': value}).eq('id', id);
  }

  /// Analizza una sorgente e importa le ricette conformi ai regimi attivi.
  /// Ritorna le ricette importate.
  Future<List<Recipe>> analyze(String sourceId, Set<Diet> diets) async {
    if (_demo) return localApi.analyze(diets);
    final res = await _db!.functions.invoke('analyze-feed', body: {
      'source_id': sourceId,
      'diets': Diet.toNames(diets),
    });
    final data = res.data as Map<String, dynamic>;
    final list = (data['imported'] as List?) ?? const [];
    return list
        .map((r) => Recipe.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(Config.demo ? null : Supabase.instance.client),
);

final feedSourcesProvider = FutureProvider.autoDispose<List<FeedSource>>(
  (ref) => ref.watch(feedRepositoryProvider).list(),
);

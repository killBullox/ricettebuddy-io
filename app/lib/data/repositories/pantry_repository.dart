import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../demo/demo_store.dart';
import '../models/pantry_item.dart';

class PantryRepository {
  final SupabaseClient? _db;
  PantryRepository(this._db);

  bool get _demo => Config.demo;
  DemoStore get _store => DemoStore.instance;
  String get _uid => _db!.auth.currentUser!.id;

  Future<List<PantryItem>> list() async {
    if (_demo) return [..._store.pantry];
    final rows =
        await _db!.from('pantry_items').select().order('normalized_name');
    return (rows as List)
        .map((r) => PantryItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(PantryItem item) async {
    if (_demo) return _store.addPantry(item);
    await _db!.from('pantry_items').insert({...item.toMap(), 'user_id': _uid});
  }

  Future<void> delete(String id) async {
    if (_demo) return _store.deletePantry(id);
    await _db!.from('pantry_items').delete().eq('id', id);
  }

  Future<void> update(PantryItem item) async {
    if (_demo) return _store.updatePantry(item);
    await _db!.from('pantry_items').update(item.toMap()).eq('id', item.id!);
  }
}

final pantryRepositoryProvider = Provider<PantryRepository>(
  (ref) =>
      PantryRepository(Config.demo ? null : Supabase.instance.client),
);

final pantryListProvider = FutureProvider.autoDispose<List<PantryItem>>(
  (ref) => ref.watch(pantryRepositoryProvider).list(),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pantry_item.dart';

class PantryRepository {
  final SupabaseClient _db;
  PantryRepository(this._db);

  String get _uid => _db.auth.currentUser!.id;

  Future<List<PantryItem>> list() async {
    final rows =
        await _db.from('pantry_items').select().order('normalized_name');
    return (rows as List)
        .map((r) => PantryItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(PantryItem item) =>
      _db.from('pantry_items').insert({...item.toMap(), 'user_id': _uid});

  Future<void> delete(String id) =>
      _db.from('pantry_items').delete().eq('id', id);
}

final pantryRepositoryProvider = Provider<PantryRepository>(
  (ref) => PantryRepository(Supabase.instance.client),
);

final pantryListProvider = FutureProvider.autoDispose<List<PantryItem>>(
  (ref) => ref.watch(pantryRepositoryProvider).list(),
);

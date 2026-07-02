import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import '../models/shopping_item.dart';

class ShoppingRepository {
  final SupabaseClient _db;
  ShoppingRepository(this._db);

  String get _uid => _db.auth.currentUser!.id;

  Future<List<ShoppingItem>> list() async {
    final rows = await _db.from('shopping_items').select().order('name');
    return (rows as List)
        .map((r) => ShoppingItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setChecked(String id, bool value) =>
      _db.from('shopping_items').update({'is_checked': value}).eq('id', id);

  Future<void> addFree(String name) => _db
      .from('shopping_items')
      .insert({'name': name, 'user_id': _uid});

  /// Aggiunge gli ingredienti di una ricetta e ri-aggrega le voci non spuntate.
  Future<void> addFromRecipe(Recipe recipe) async {
    if (recipe.ingredients.isNotEmpty) {
      await _db.from('shopping_items').insert([
        for (final ing in recipe.ingredients)
          {
            'user_id': _uid,
            'name': ing.normalizedName ?? ing.rawText,
            'quantity': ing.quantity,
            'unit': ing.unit,
            'aisle_category': ing.aisleCategory,
            'source_recipe_id': recipe.id,
          }
      ]);
    }
    await _aggregate();
  }

  /// Fonde le voci non spuntate con stesso nome+unità sommando le quantità.
  /// NB: normalizzazione avanzata delle unità (g/kg, ml/l) demandata al server.
  Future<void> _aggregate() async {
    final items = await list();
    final Map<String, ShoppingItem> merged = {};
    final List<String> toDelete = [];
    final Map<String, double?> sums = {};

    for (final it in items.where((i) => !i.isChecked)) {
      final key = '${it.name.toLowerCase()}|${it.unit ?? ''}';
      if (merged.containsKey(key)) {
        final base = sums[key];
        sums[key] = (base ?? 0) + (it.quantity ?? 0);
        if (it.id != null) toDelete.add(it.id!);
      } else {
        merged[key] = it;
        sums[key] = it.quantity;
      }
    }

    for (final entry in merged.entries) {
      final it = entry.value;
      if (it.id != null && sums[entry.key] != it.quantity) {
        await _db
            .from('shopping_items')
            .update({'quantity': sums[entry.key]}).eq('id', it.id!);
      }
    }
    if (toDelete.isNotEmpty) {
      await _db.from('shopping_items').delete().inFilter('id', toDelete);
    }
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(Supabase.instance.client),
);

final shoppingListProvider = FutureProvider.autoDispose<List<ShoppingItem>>(
  (ref) => ref.watch(shoppingRepositoryProvider).list(),
);

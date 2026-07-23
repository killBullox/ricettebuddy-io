import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';

/// Un piano settimanale inviato dal nutrizionista, ancora da importare.
class PushedPlan {
  final String id;
  final DateTime? weekStart;
  final String? note;
  final int nItems;

  PushedPlan({required this.id, this.weekStart, this.note, this.nItems = 0});

  factory PushedPlan.fromMap(Map<String, dynamic> m) {
    // meal_plan_items(count) torna come lista con un solo elemento {count: N}.
    var n = 0;
    final items = m['meal_plan_items'];
    if (items is List && items.isNotEmpty && items.first is Map) {
      n = (items.first['count'] as num?)?.toInt() ?? 0;
    }
    return PushedPlan(
      id: m['id'] as String,
      weekStart:
          m['week_start'] != null ? DateTime.tryParse(m['week_start'] as String) : null,
      note: m['note'] as String?,
      nItems: n,
    );
  }
}

/// Piani pushati dal nutrizionista: elenco di quelli in attesa e import.
/// L'import (copia ricette base + creazione voci del piano) avviene lato server
/// nella Edge Function `piano`, così il client non deve replicare la logica.
class PlanPushRepository {
  final SupabaseClient? _db;
  PlanPushRepository(this._db);

  bool get _demo => Config.demo;

  Future<List<PushedPlan>> pending() async {
    if (_demo || _db == null) return [];
    // La RLS restringe già ai piani del cliente loggato.
    final rows = await _db
        .from('meal_plans')
        .select('id, week_start, note, status, created_at, meal_plan_items(count)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => PushedPlan.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Importa il piano: la funzione copia le ricette base nella collezione del
  /// cliente e crea le meal_plan_entries. Ritorna quante voci ha creato.
  Future<int> importPlan(String planId) async {
    if (_demo || _db == null) return 0;
    try {
      final res = await _db.functions.invoke('piano', body: {
        'action': 'importa',
        'plan_id': planId,
      });
      final data = res.data;
      return (data is Map ? (data['imported'] as num?)?.toInt() : null) ?? 0;
    } on FunctionException catch (e) {
      // Un 4xx/5xx dalla funzione arriva qui: `details` contiene il body JSON
      // con il nostro messaggio ({error: "..."}).
      final d = e.details;
      final msg = (d is Map && d['error'] != null) ? d['error'].toString() : null;
      throw Exception(msg ?? 'Errore ${e.status}');
    }
  }
}

final planPushRepositoryProvider = Provider<PlanPushRepository>(
  (ref) => PlanPushRepository(Config.demo ? null : Supabase.instance.client),
);

final pendingPlansProvider = FutureProvider.autoDispose<List<PushedPlan>>(
  (ref) => ref.watch(planPushRepositoryProvider).pending(),
);

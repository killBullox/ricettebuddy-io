import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';

/// Richiesta di piano alimentare inviata dal cliente. Se senza videoconsulto,
/// il cliente compila i dati antropometrici (che il team userà per il piano);
/// con videoconsulto i dati li raccoglie il team durante la chiamata.
class PlanRequestRepository {
  final SupabaseClient? _db;
  PlanRequestRepository(this._db);

  bool get _demo => Config.demo;

  /// Invia la richiesta. [data] contiene i campi antropometrici già validati.
  Future<void> submit({required bool wantsVideo, Map<String, dynamic> data = const {}}) async {
    if (_demo || _db == null) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Non sei autenticato.');
    final row = <String, dynamic>{
      'user_id': uid,
      'wants_video': wantsVideo,
      'status': 'pending',
      ...data,
    };
    await _db.from('plan_requests').insert(row);
  }
}

final planRequestRepositoryProvider = Provider<PlanRequestRepository>(
  (ref) => PlanRequestRepository(Config.demo ? null : Supabase.instance.client),
);

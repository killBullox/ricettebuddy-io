import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/cooking_loader.dart';
import '../../data/repositories/import_repository.dart';
import '../../l10n/app_localizations.dart';
import 'social_extractor.dart';

/// Import completo con UI. Per Facebook apre la webview (login una-tantum +
/// lettura del reel), poi mostra il loader con le fasi REALI durante l'enrich.
/// Ritorna il risultato, o null se l'utente annulla la webview Facebook.
Future<({String id, bool duplicate})?> runImport(
    BuildContext context, WidgetRef ref, String url) async {
  final l = AppLocalizations.of(context);
  // NB: i reel Facebook non sono leggibili lato app (FB nasconde didascalia e
  // video senza login). Verranno gestiti da un servizio server dedicato.
  const ExtractedPost? fbPost = null;
  final live = ValueNotifier<String>(l.phaseReading);
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFFFBFAF7),
    useSafeArea: false,
    builder: (_) => Center(
      child: CookingLoader(size: 230, liveMessage: live, payoff: kPayoff),
    ),
  );
  try {
    final repo = ref.read(importRepositoryProvider);
    final res = fbPost != null
        ? await repo.importFromExtracted(fbPost,
            onPhase: (p) => live.value = phaseText(l, p))
        : await repo.importFromUrl(url,
            onPhase: (p) => live.value = phaseText(l, p));
    if (context.mounted) Navigator.of(context).pop();
    return res;
  } catch (_) {
    if (context.mounted) Navigator.of(context).pop();
    rethrow;
  } finally {
    live.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/cooking_loader.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';

/// Payoff del brand mostrato sotto il loader (in inglese, identità Beet-It).
const kPayoff = 'Plant-based nutrition that rocks';

/// Quando un social non è leggibile (tipico dei reel Facebook, che senza login
/// non espongono la didascalia), chiede all'utente di incollare il testo della
/// ricetta — che ha già davanti — e lo importa. Ritorna l'id o null.
Future<String?> showPasteFallback(
    BuildContext context, WidgetRef ref, String sourceUrl) async {
  final l = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.pasteRecipeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.pasteRecipeBody),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 6,
              autofocus: true,
              decoration: InputDecoration(
                  hintText: l.pasteRecipeHint,
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l.importFromLink)),
      ],
    ),
  );
  if (text == null || text.trim().length < 30) return null;
  if (!context.mounted) return null;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFFFBFAF7),
    useSafeArea: false,
    builder: (_) => const Center(child: CookingLoader(size: 230, message: kPayoff)),
  );
  try {
    final res = await ref
        .read(importRepositoryProvider)
        .importFromText(text: text, sourceUrl: sourceUrl);
    ref.invalidate(recipeListProvider);
    if (context.mounted) Navigator.of(context).pop();
    return res.id;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.importFailed('$e'))));
    }
    return null;
  }
}

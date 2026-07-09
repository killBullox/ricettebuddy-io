import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/cooking_loader.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _url = TextEditingController();
  bool _importing = false;

  Future<void> _import() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    final l = AppLocalizations.of(context);
    setState(() => _importing = true);
    // Loader animato a schermo intero, sfondo OPACO (coprente), durante l'attesa.
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFFFBFAF7), // opaco: copre tutta la schermata
      useSafeArea: false,
      builder: (_) => Center(
        child: CookingLoader(
            size: 230, phases: importPhases(l), payoff: kPayoff),
      ),
    );
    try {
      final res = await ref.read(importRepositoryProvider).importFromUrl(url);
      ref.invalidate(recipeListProvider);
      if (!mounted) return;
      Navigator.of(context).pop(); // chiude il loader
      _url.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.duplicate ? l.alreadyInLibrary : l.recipeImported),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.importFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.importTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.importFromWebOrSocial,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: l.pasteLinkHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _importing ? null : _import,
            icon: _importing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label: Text(l.importFromLink),
          ),
          const Divider(height: 40),
          Text(l.fromCamera, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            // TODO(F3): image_picker + google_mlkit_text_recognition (OCR)
            //           poi structuring AI via Edge Function.
            onPressed: null,
            icon: const Icon(Icons.camera_alt),
            label: Text(l.scanRecipeSoon),
          ),
          const SizedBox(height: 24),
          Text(l.shareHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

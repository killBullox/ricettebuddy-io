import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import 'import_flow.dart';

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
    // Fase REALE mostrata nel loader: cambia man mano che il processo avanza
    // davvero (estrazione sul dispositivo → stream dell'AI).
    try {
      final res = await runImport(context, ref, url);
      if (res == null) return; // annullato (es. webview Facebook chiusa)
      ref.invalidate(recipeListProvider);
      if (!mounted) return;
      _url.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.duplicate ? l.alreadyInLibrary : l.recipeImported),
      ));
    } catch (e) {
      if (!mounted) return;
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

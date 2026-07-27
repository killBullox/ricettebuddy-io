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
  final _text = TextEditingController();
  bool _importing = false;

  Future<void> _run(
      Future<({String id, bool duplicate})?> Function() action,
      {VoidCallback? onDone}) async {
    final l = AppLocalizations.of(context);
    setState(() => _importing = true);
    try {
      final res = await action();
      if (res == null) return; // annullato
      ref.invalidate(recipeListProvider);
      if (!mounted) return;
      onDone?.call();
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

  Future<void> _import() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    await _run(() => runImport(context, ref, url), onDone: _url.clear);
  }

  Future<void> _importText() async {
    final text = _text.text.trim();
    if (text.length < 20) return;
    await _run(() => runImportText(context, ref, text), onDone: _text.clear);
  }

  @override
  void dispose() {
    _url.dispose();
    _text.dispose();
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
          Text('Incolla il testo della ricetta',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Se il link non funziona (post privato o social che blocca la lettura), '
            'copia la didascalia dal social e incollala qui: la trasformo in ricetta.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Incolla qui ingredienti e procedimento…',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _importing ? null : _importText,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Crea ricetta dal testo'),
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

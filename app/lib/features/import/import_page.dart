import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/import_repository.dart';
import '../../data/repositories/recipe_repository.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _url = TextEditingController();
  bool _importing = false;

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      await ref.read(importRepositoryProvider).importFromUrl(_url.text.trim());
      ref.invalidate(recipeListProvider);
      _url.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ricetta importata')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import non riuscito: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Importa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Da sito web o social',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Incolla un link…',
              border: OutlineInputBorder(),
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
            label: const Text('Importa da link'),
          ),
          const Divider(height: 40),
          Text('Da fotocamera',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            // TODO(F3): image_picker + google_mlkit_text_recognition (OCR)
            //           poi structuring AI via Edge Function.
            onPressed: null,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scansiona ricetta (in arrivo)'),
          ),
          const SizedBox(height: 24),
          Text(
            'Potrai anche importare dai social col tasto Condividi '
            '(TikTok, Instagram, …) tramite la Share Extension.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

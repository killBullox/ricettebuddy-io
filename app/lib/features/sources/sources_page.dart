import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/feed_source.dart';
import '../../data/prefs.dart';
import '../../data/repositories/feed_repository.dart';
import '../../data/repositories/recipe_repository.dart';

IconData _iconFor(SourceType t) => switch (t) {
      SourceType.web => Icons.language,
      SourceType.instagram => Icons.photo_camera,
      SourceType.tiktok => Icons.music_note,
      SourceType.youtube => Icons.smart_display,
      SourceType.pinterest => Icons.push_pin,
    };

/// Sorgenti/Feed: pagine web o account social da cui l'app importa
/// automaticamente le ricette (filtrate per regime alimentare).
class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(feedSourcesProvider);
    final diets = ref.watch(activeDietsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sorgenti / Feed')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi sorgente'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              diets.isEmpty
                  ? 'Nessun filtro regime attivo: verranno importate tutte le ricette trovate. Imposta i regimi in Impostazioni.'
                  : 'Filtri attivi: ${diets.map((d) => d.label).join(', ')}. '
                      'Verranno importate solo le ricette conformi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: sources.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Nessuna sorgente.\nAggiungi una pagina web o un account social.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _SourceTile(source: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref) async {
    var type = SourceType.web;
    final refCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    var auto = true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nuova sorgente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SourceType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final t in SourceType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) => setState(() => type = v ?? SourceType.web),
                ),
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: type == SourceType.web
                        ? 'URL della pagina'
                        : 'Account (es. @nome)',
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome (etichetta)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Import automatico'),
                  subtitle: const Text('Controlla e importa periodicamente'),
                  value: auto,
                  onChanged: (v) => setState(() => auto = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annulla')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salva')),
          ],
        ),
      ),
    );

    if (saved != true || refCtrl.text.trim().isEmpty) return;
    final name = nameCtrl.text.trim().isEmpty
        ? refCtrl.text.trim()
        : nameCtrl.text.trim();
    await ref.read(feedRepositoryProvider).add(FeedSource(
          type: type,
          reference: refCtrl.text.trim(),
          name: name,
          autoImport: auto,
        ));
    ref.invalidate(feedSourcesProvider);
  }
}

class _SourceTile extends ConsumerStatefulWidget {
  final FeedSource source;
  const _SourceTile({required this.source});

  @override
  ConsumerState<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends ConsumerState<_SourceTile> {
  bool _analyzing = false;

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    try {
      final diets = ref.read(activeDietsProvider);
      final imported =
          await ref.read(feedRepositoryProvider).analyze(widget.source.id!, diets);
      ref.invalidate(recipeListProvider);
      ref.invalidate(feedSourcesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(imported.isEmpty
                ? 'Nessuna nuova ricetta conforme trovata.'
                : 'Importate ${imported.length} ricette: '
                    '${imported.map((r) => r.title).join(', ')}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    return ListTile(
      leading: Icon(_iconFor(s.type)),
      title: Text(s.name),
      subtitle: Text('${s.type.label} · ${s.reference}'
          '${s.autoImport ? ' · auto' : ''}'),
      trailing: _analyzing
          ? const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _analyze,
                  child: const Text('Analizza'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(feedRepositoryProvider).delete(s.id!);
                    ref.invalidate(feedSourcesProvider);
                  },
                ),
              ],
            ),
    );
  }
}

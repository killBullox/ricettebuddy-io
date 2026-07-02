import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pantry_item.dart';
import '../../data/repositories/creative_repository.dart';
import '../../data/repositories/pantry_repository.dart';

/// Dispensa persistente, modificabile al volo. Base per lo "Chef creativo".
class PantryPage extends ConsumerWidget {
  const PantryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pantryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Dispensa vuota.\nAggiungi ciò che hai in casa per ricevere idee.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = list[i];
              return Dismissible(
                key: ValueKey(it.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await ref.read(pantryRepositoryProvider).delete(it.id!);
                  ref.invalidate(pantryListProvider);
                  ref.invalidate(doableRecipesProvider);
                },
                child: ListTile(
                  leading: const Icon(Icons.egg_alt_outlined),
                  title: Text(it.rawText),
                  subtitle: it.expiryDate != null
                      ? Text('Scade il ${it.expiryDate!.day}/${it.expiryDate!.month}')
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aggiungi alla dispensa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Es. 500 g farina, 6 uova…',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Aggiungi')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;

    // Normalizzazione minima lato client; il server rifinisce nome/unità/corsia.
    final raw = text.trim();
    await ref.read(pantryRepositoryProvider).add(
          PantryItem(rawText: raw, normalizedName: _normalize(raw)),
        );
    ref.invalidate(pantryListProvider);
    ref.invalidate(doableRecipesProvider);
  }

  /// Nome normalizzato provvisorio: rimuove quantità/unità comuni.
  /// La normalizzazione seria (sinonimi, plurali, unità) è lato server.
  String _normalize(String raw) {
    var s = raw.toLowerCase();
    s = s.replaceAll(
        RegExp(r'\b\d+([.,]\d+)?\s*(g|kg|ml|l|pz|q\.?b\.?|cucchiai?|tazze?)\b'),
        '');
    s = s.replaceAll(RegExp(r'\b(di|del|della|dei|delle|d\x27)\b'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

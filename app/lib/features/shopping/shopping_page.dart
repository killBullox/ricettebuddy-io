import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shopping_item.dart';
import '../../data/repositories/shopping_repository.dart';

final _groupByAisleProvider = StateProvider<bool>((ref) => true);

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingListProvider);
    final groupByAisle = ref.watch(_groupByAisleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spesa'),
        actions: [
          PopupMenuButton<bool>(
            initialValue: groupByAisle,
            onSelected: (v) => ref.read(_groupByAisleProvider.notifier).state = v,
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Per corsia')),
              PopupMenuItem(value: false, child: Text('In elenco')),
            ],
          ),
        ],
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
                  'Lista vuota.\nAggiungi ricette al piano o usa il carrello in una ricetta.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final sections = _sections(list, groupByAisle);
          return ListView(
            children: [
              for (final s in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(s.title,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final item in s.items)
                  _ShoppingRow(item: item),
              ],
            ],
          );
        },
      ),
    );
  }

  List<({String title, List<ShoppingItem> items})> _sections(
      List<ShoppingItem> items, bool byAisle) {
    if (!byAisle) return [(title: 'Tutti', items: items)];
    final map = <String, List<ShoppingItem>>{};
    for (final it in items) {
      map.putIfAbsent(it.aisleCategory ?? 'Varie', () => []).add(it);
    }
    final keys = map.keys.toList()..sort();
    return [for (final k in keys) (title: k, items: map[k]!)];
  }
}

class _ShoppingRow extends ConsumerWidget {
  final ShoppingItem item;
  const _ShoppingRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = item.quantity == null
        ? null
        : '${_fmt(item.quantity!)}${item.unit != null ? ' ${item.unit}' : ''}';
    return CheckboxListTile(
      value: item.isChecked,
      onChanged: (v) async {
        await ref
            .read(shoppingRepositoryProvider)
            .setChecked(item.id!, v ?? false);
        ref.invalidate(shoppingListProvider);
      },
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isChecked ? TextDecoration.lineThrough : null,
        ),
      ),
      secondary: qty != null ? Text(qty) : null,
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

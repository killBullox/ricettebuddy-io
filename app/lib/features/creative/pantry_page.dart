import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pantry_item.dart';
import '../../data/repositories/creative_repository.dart';
import '../../data/repositories/pantry_repository.dart';
import '../recipes/ingredient_avatar.dart';
import '../recipes/ingredient_icon.dart';

/// Dispensa smart: cosa hai in casa, con quantità modificabili (− / +),
/// icone ingrediente e modifica/eliminazione. Base per lo "Chef creativo".
class PantryPage extends ConsumerWidget {
  const PantryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(pantryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
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
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _PantryTile(item: list[i]),
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
          decoration: const InputDecoration(hintText: 'Es. 500 g pasta, 6 pomodori…'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Aggiungi')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final raw = text.trim();
    final p = parseQtyUnitName(raw);
    await ref.read(pantryRepositoryProvider).add(PantryItem(
          rawText: raw,
          normalizedName: p.name,
          quantity: p.qty,
          unit: p.unit,
        ));
    ref.invalidate(pantryListProvider);
    ref.invalidate(doableRecipesProvider);
  }
}

/// Estrae quantità, unità e nome-prodotto da un testo tipo "500 g pasta".
({double? qty, String? unit, String name}) parseQtyUnitName(String raw) {
  final m = RegExp(
    r'^\s*(\d+(?:[.,]\d+)?)\s*(g|gr|kg|ml|cl|l|pz|pezzi?|cucchiai?|cucchiaini?|tazze?)?\b',
    caseSensitive: false,
  ).firstMatch(raw);
  double? qty;
  String? unit;
  var rest = raw;
  if (m != null) {
    qty = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    final u = m.group(2)?.toLowerCase();
    unit = u == null ? null : (u.startsWith('pezz') || u == 'pz' ? 'pz' : u);
    rest = raw.substring(m.end).trim();
  }
  final name = cleanIngredientName(rest.isEmpty ? raw : rest);
  return (qty: qty, unit: unit, name: name);
}

String _fmtQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : '$q';

double _stepFor(String? unit) {
  if (unit == 'g' || unit == 'gr' || unit == 'ml') return 50;
  return 1; // pz, kg, l, cucchiai, tazze, o unità intere
}

class _PantryTile extends ConsumerWidget {
  final PantryItem item;
  const _PantryTile({required this.item});

  /// Quantità/unità effettive: dai campi strutturati o, per le voci legacy,
  /// ricavate dal testo grezzo.
  ({double? qty, String? unit, String name}) get _eff {
    if (item.quantity != null) {
      return (qty: item.quantity, unit: item.unit, name: _product);
    }
    return parseQtyUnitName(item.rawText);
  }

  String get _product => item.normalizedName.trim().isNotEmpty
      ? item.normalizedName[0].toUpperCase() + item.normalizedName.substring(1)
      : cleanIngredientName(item.rawText);

  Future<void> _setQty(WidgetRef ref, double? newQty, String? unit) async {
    final repo = ref.read(pantryRepositoryProvider);
    if (newQty != null && newQty <= 0) {
      await repo.delete(item.id!);
    } else {
      final label = newQty == null
          ? _product
          : '${_fmtQty(newQty)}${unit != null ? ' $unit' : ''} $_product'.trim();
      await repo.update(item.copyWith(
        rawText: label,
        quantity: newQty,
        unit: unit,
      ));
    }
    ref.invalidate(pantryListProvider);
    ref.invalidate(doableRecipesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eff = _eff;
    final hasQty = eff.qty != null;
    final amount = hasQty
        ? '${_fmtQty(eff.qty!)}${eff.unit != null ? ' ${eff.unit}' : ''}'
        : '';
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(pantryRepositoryProvider).delete(item.id!);
        ref.invalidate(pantryListProvider);
        ref.invalidate(doableRecipesProvider);
      },
      child: ListTile(
        onTap: () => _editDialog(context, ref),
        leading: IngredientAvatar(raw: item.rawText, size: 40),
        title: Text(_product, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: item.expiryDate != null
            ? Text('Scade il ${item.expiryDate!.day}/${item.expiryDate!.month}')
            : null,
        trailing: hasQty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () =>
                        _setQty(ref, eff.qty! - _stepFor(eff.unit), eff.unit),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 52),
                    child: Text(amount,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        _setQty(ref, eff.qty! + _stepFor(eff.unit), eff.unit),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editDialog(context, ref),
              ),
      ),
    );
  }

  Future<void> _editDialog(BuildContext context, WidgetRef ref) async {
    final eff = _eff;
    final qtyCtrl = TextEditingController(
        text: eff.qty != null ? _fmtQty(eff.qty!) : '');
    final nameCtrl = TextEditingController(text: _product);
    String? unit = eff.unit;
    const units = ['g', 'kg', 'ml', 'l', 'pz'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Modifica'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ingrediente'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantità'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: units.contains(unit) ? unit : null,
                    hint: const Text('unità'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      for (final u in units)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) => setState(() => unit = v),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, {'delete': true}),
              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'name': nameCtrl.text.trim(),
                'qty': double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.')),
                'unit': unit,
              }),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final repo = ref.read(pantryRepositoryProvider);
    if (result['delete'] == true) {
      await repo.delete(item.id!);
    } else {
      final name = (result['name'] as String?)?.trim();
      final qty = result['qty'] as double?;
      final u = result['unit'] as String?;
      final label =
          '${qty != null ? '${_fmtQty(qty)}${u != null ? ' $u' : ''} ' : ''}${name ?? _product}'
              .trim();
      await repo.update(item.copyWith(
        rawText: label,
        normalizedName: (name == null || name.isEmpty) ? item.normalizedName : name.toLowerCase(),
        quantity: qty,
        unit: u,
      ));
    }
    ref.invalidate(pantryListProvider);
    ref.invalidate(doableRecipesProvider);
  }
}

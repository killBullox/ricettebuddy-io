import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';

/// Pannello filtri per la ricerca ricette: allergeni da escludere (glutine,
/// soia, …), etichette nutrizionali (HIGH PROTEIN, LOW CARB…) e soglie
/// nutrizionali PER PORZIONE (calorie max, proteine min).
class RecipeFilterSheet extends ConsumerStatefulWidget {
  const RecipeFilterSheet({super.key});

  @override
  ConsumerState<RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends ConsumerState<RecipeFilterSheet> {
  late Set<String> _excl;
  late Set<String> _labels;
  int? _maxKcal;
  int? _minProtein;

  // etichetta mostrata -> chiave allergene cercata (minuscolo, "contains")
  static const _allergens = {
    'Senza glutine': 'glutine',
    'Senza soia': 'soia',
    'Senza frutta a guscio': 'frutta a guscio',
    'Senza lattosio': 'lattosio',
  };

  @override
  void initState() {
    super.initState();
    final f = ref.read(recipeFiltersProvider);
    _excl = {...f.excludeAllergens};
    _labels = {...f.labels};
    _maxKcal = f.maxKcal;
    _minProtein = f.minProtein;
  }

  void _toggle(Set<String> s, String v) =>
      setState(() => s.contains(v) ? s.remove(v) : s.add(v));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            _title('Senza allergeni'),
            Wrap(spacing: 8, children: [
              for (final e in _allergens.entries)
                FilterChip(
                  label: Text(e.key),
                  selected: _excl.contains(e.value),
                  onSelected: (_) => _toggle(_excl, e.value),
                ),
            ]),
            _title('Etichette'),
            Wrap(spacing: 8, children: [
              for (final l in Recipe.nutritionLabelKeys)
                FilterChip(
                  label: Text(l),
                  selected: _labels.contains(l),
                  onSelected: (_) => _toggle(_labels, l),
                ),
            ]),
            _title('Calorie max (a porzione)'),
            Wrap(spacing: 8, children: [
              for (final k in [300, 500, 700])
                ChoiceChip(
                  label: Text('≤ $k kcal'),
                  selected: _maxKcal == k,
                  onSelected: (_) => setState(() => _maxKcal = _maxKcal == k ? null : k),
                ),
            ]),
            _title('Proteine min (a porzione)'),
            Wrap(spacing: 8, children: [
              for (final p in [10, 20, 30])
                ChoiceChip(
                  label: Text('≥ $p g'),
                  selected: _minProtein == p,
                  onSelected: (_) => setState(() => _minProtein = _minProtein == p ? null : p),
                ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              TextButton(
                onPressed: () {
                  ref.read(recipeFiltersProvider.notifier).state =
                      const RecipeFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('Azzera'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref.read(recipeFiltersProvider.notifier).state = RecipeFilters(
                    excludeAllergens: _excl,
                    labels: _labels,
                    maxKcal: _maxKcal,
                    minProtein: _minProtein,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Applica'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      );
}

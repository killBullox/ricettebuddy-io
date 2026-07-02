import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/diet.dart';
import '../../data/models/enums.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/recipe.dart';
import '../../data/models/recipe_step.dart';
import '../../data/repositories/recipe_repository.dart';

/// Editor per creare o modificare una ricetta (titolo, tempi, porzioni,
/// regimi, ingredienti, passaggi).
class RecipeEditorPage extends ConsumerStatefulWidget {
  final Recipe? existing; // null = nuova ricetta
  const RecipeEditorPage({super.key, this.existing});

  @override
  ConsumerState<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends ConsumerState<RecipeEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _prep;
  late final TextEditingController _cook;
  late int _servings;
  late Set<Diet> _diets;
  late List<TextEditingController> _ingredients;
  late List<TextEditingController> _steps;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _title = TextEditingController(text: r?.title ?? '');
    _prep = TextEditingController(text: r?.prepMinutes?.toString() ?? '');
    _cook = TextEditingController(text: r?.cookMinutes?.toString() ?? '');
    _servings = r?.servings ?? 2;
    _diets = Diet.fromNames(r?.dietTags ?? const []);
    _ingredients = [
      for (final i in (r?.ingredients ?? const []))
        TextEditingController(text: i.rawText),
      if ((r?.ingredients ?? const []).isEmpty) TextEditingController(),
    ];
    _steps = [
      for (final s in (r?.steps ?? const []))
        TextEditingController(text: s.text),
      if ((r?.steps ?? const []).isEmpty) TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _prep.dispose();
    _cook.dispose();
    for (final c in _ingredients) {
      c.dispose();
    }
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il titolo è obbligatorio')),
      );
      return;
    }
    setState(() => _saving = true);
    final recipe = Recipe(
      id: widget.existing?.id,
      title: _title.text.trim(),
      source: widget.existing?.source ?? RecipeSource.manual,
      prepMinutes: int.tryParse(_prep.text.trim()),
      cookMinutes: int.tryParse(_cook.text.trim()),
      servings: _servings,
      dietTags: Diet.toNames(_diets),
      ingredients: [
        for (final c in _ingredients)
          if (c.text.trim().isNotEmpty) Ingredient(rawText: c.text.trim()),
      ],
      steps: [
        for (final (i, c) in _steps.indexed)
          if (c.text.trim().isNotEmpty)
            RecipeStep(position: i, text: c.text.trim()),
      ],
    );

    final repo = ref.read(recipeRepositoryProvider);
    if (widget.existing?.id != null) {
      await repo.update(widget.existing!.id!, recipe);
      ref.invalidate(recipeDetailProvider(widget.existing!.id!));
    } else {
      await repo.create(recipe);
    }
    ref.invalidate(recipeListProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nuova ricetta' : 'Modifica'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salva'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Titolo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prep,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Prep (min)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cook,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Cottura (min)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Porzioni'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _servings > 1
                    ? () => setState(() => _servings--)
                    : null,
              ),
              Text('$_servings', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _servings++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Regimi soddisfatti',
              style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final d in Diet.values)
                FilterChip(
                  label: Text(d.label),
                  selected: _diets.contains(d),
                  onSelected: (v) => setState(() =>
                      v ? _diets.add(d) : _diets.remove(d)),
                ),
            ],
          ),
          const Divider(height: 32),

          _EditableList(
            title: 'Ingredienti',
            controllers: _ingredients,
            hint: 'Es. 200 g farina',
            onAdd: () => setState(() => _ingredients.add(TextEditingController())),
            onRemove: (i) => setState(() => _ingredients.removeAt(i).dispose()),
          ),
          const Divider(height: 32),
          _EditableList(
            title: 'Passaggi',
            controllers: _steps,
            hint: 'Descrivi il passaggio',
            numbered: true,
            onAdd: () => setState(() => _steps.add(TextEditingController())),
            onRemove: (i) => setState(() => _steps.removeAt(i).dispose()),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EditableList extends StatelessWidget {
  final String title;
  final List<TextEditingController> controllers;
  final String hint;
  final bool numbered;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _EditableList({
    required this.title,
    required this.controllers,
    required this.hint,
    this.numbered = false,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ],
        ),
        for (final (i, c) in controllers.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (numbered)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('${i + 1}.'),
                  ),
                Expanded(
                  child: TextField(
                    controller: c,
                    decoration: InputDecoration(
                      hintText: hint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onRemove(i),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

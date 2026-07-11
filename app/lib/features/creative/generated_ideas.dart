import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/cooking_loader.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/creative_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../recipes/recipe_labels.dart';

/// Chef AI — "Idee nuove": genera ricette originali (AI server-side) dalla
/// dispensa e dalle preferenze scelte. Le bozze si salvano nel ricettario.
class GeneratedIdeasPage extends ConsumerStatefulWidget {
  const GeneratedIdeasPage({super.key});

  @override
  ConsumerState<GeneratedIdeasPage> createState() => _GeneratedIdeasPageState();
}

class _GeneratedIdeasPageState extends ConsumerState<GeneratedIdeasPage> {
  bool _loading = false;
  String? _error;
  List<Recipe> _ideas = [];

  // Preferenze.
  bool _fast = false;
  final Set<String> _labels = {};
  final Set<String> _excl = {};

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ideas = await ref.read(creativeRepositoryProvider).generateIdeas(
            maxMinutes: _fast ? 30 : null,
            labels: _labels.toList(),
            excludeAllergens: _excl.toList(),
          );
      setState(() => _ideas = ideas);
    } catch (e) {
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(Set<String> s, String v) =>
      setState(() => s.contains(v) ? s.remove(v) : s.add(v));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.chefIdeasTitle)),
      body: Column(
        children: [
          // Preferenze + genera
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                FilterChip(
                  label: Text(l.chefPrefFast),
                  selected: _fast,
                  onSelected: _loading ? null : (v) => setState(() => _fast = v),
                ),
                FilterChip(
                  label: Text(l.labelHighProtein),
                  selected: _labels.contains('HIGH PROTEIN'),
                  onSelected:
                      _loading ? null : (_) => _toggle(_labels, 'HIGH PROTEIN'),
                ),
                FilterChip(
                  label: Text(l.labelLight),
                  selected: _labels.contains('LIGHT'),
                  onSelected: _loading ? null : (_) => _toggle(_labels, 'LIGHT'),
                ),
                FilterChip(
                  label: Text(l.allergenGluten),
                  selected: _excl.contains('glutine'),
                  onSelected: _loading ? null : (_) => _toggle(_excl, 'glutine'),
                ),
                FilterChip(
                  label: Text(l.allergenSoy),
                  selected: _excl.contains('soia'),
                  onSelected: _loading ? null : (_) => _toggle(_excl, 'soia'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: Text(l.chefGenerate),
                onPressed: _loading ? null : _generate,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child:
                        CookingLoader(size: 180, message: l.chefThinking, payoff: kPayoff))
                : _error != null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_error!)))
                    : _ideas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(l.chefHint,
                                  textAlign: TextAlign.center),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              for (final r in _ideas) _IdeaCard(recipe: r)
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _IdeaCard extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _IdeaCard({required this.recipe});

  @override
  ConsumerState<_IdeaCard> createState() => _IdeaCardState();
}

class _IdeaCardState extends ConsumerState<_IdeaCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = widget.recipe;
    final kcal = (r.nutrition?['kcal'] as num?)?.round();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Row(children: [
              if (r.totalMinutes != null) ...[
                Icon(Icons.schedule, size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 3),
                Text('${r.totalMinutes} min',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                const SizedBox(width: 12),
              ],
              if (kcal != null) ...[
                Icon(Icons.local_fire_department,
                    size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 3),
                Text('$kcal kcal',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: RecipeLabels(recipe: r),
            ),
            const SizedBox(height: 10),
            Text(l.ingredientsTitle,
                style: Theme.of(context).textTheme.labelLarge),
            for (final ing in r.ingredients) Text('• ${ing.rawText}'),
            const SizedBox(height: 8),
            Text(l.preparationTitle,
                style: Theme.of(context).textTheme.labelLarge),
            for (final s in r.steps) Text('${s.position + 1}. ${s.text}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: Icon(_saved ? Icons.check : Icons.bookmark_add),
                label: Text(_saved ? l.savedToCookbook : l.saveToCookbook),
                onPressed: _saved
                    ? null
                    : () async {
                        await ref.read(recipeRepositoryProvider).create(r);
                        ref.invalidate(recipeListProvider);
                        if (mounted) setState(() => _saved = true);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

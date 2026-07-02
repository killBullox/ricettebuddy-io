import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';
import 'diet_badges.dart';
import 'recipe_editor_page.dart';
import 'recipe_image.dart';

class RecipeDetailPage extends ConsumerWidget {
  final String recipeId;
  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (recipe) => _Detail(recipe: recipe),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  final Recipe recipe;
  const _Detail({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = [...recipe.steps]..sort((a, b) => a.position - b.position);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: recipe.imageUrl != null ? 220 : kToolbarHeight,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifica',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecipeEditorPage(existing: recipe),
                  ),
                );
                ref.invalidate(recipeDetailProvider(recipe.id!));
                ref.invalidate(recipeListProvider);
              },
            ),
            IconButton(
              icon: Icon(
                recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              onPressed: () async {
                await ref
                    .read(recipeRepositoryProvider)
                    .setFavorite(recipe.id!, !recipe.isFavorite);
                ref.invalidate(recipeDetailProvider(recipe.id!));
                ref.invalidate(recipeListProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'Aggiungi alla spesa',
              onPressed: () async {
                await ref
                    .read(shoppingRepositoryProvider)
                    .addFromRecipe(recipe);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aggiunto alla spesa')),
                  );
                }
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(recipe.title),
            background: recipe.imageUrl != null
                ? RecipeImage(path: recipe.imageUrl, iconSize: 48)
                : null,
          ),
        ),
        SliverList.list(children: [
          if (recipe.source == RecipeSource.generated)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Chip(
                avatar: Icon(Icons.auto_awesome, size: 18),
                label: Text('Idea generata dallo Chef creativo'),
              ),
            ),
          // Porzioni con stepper
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('Porzioni'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: recipe.servings > 1
                      ? () async {
                          await ref
                              .read(recipeRepositoryProvider)
                              .setServings(recipe.id!, recipe.servings - 1);
                          ref.invalidate(recipeDetailProvider(recipe.id!));
                        }
                      : null,
                ),
                Text('${recipe.servings}',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await ref
                        .read(recipeRepositoryProvider)
                        .setServings(recipe.id!, recipe.servings + 1);
                    ref.invalidate(recipeDetailProvider(recipe.id!));
                  },
                ),
              ],
            ),
          ),
          if (recipe.dietTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DietBadges(dietTags: recipe.dietTags),
            ),
          _Section(
            title: 'Ingredienti',
            child: recipe.ingredients.isEmpty
                ? const Text('Nessun ingrediente')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final ing in recipe.ingredients)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• ${ing.rawText}'),
                        ),
                    ],
                  ),
          ),
          _Section(
            title: 'Preparazione',
            child: steps.isEmpty
                ? const Text('Nessun passaggio')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in steps)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${s.position + 1}. ${s.text}'),
                        ),
                    ],
                  ),
          ),
          if (recipe.sourceUrl != null)
            _Section(
              title: 'Fonte',
              child: Text(recipe.sourceUrl!),
            ),
          const SizedBox(height: 32),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

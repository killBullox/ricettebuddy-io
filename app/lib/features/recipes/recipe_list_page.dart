import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/cooking_loader.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';
import 'diet_badges.dart';
import 'recipe_detail_page.dart';
import 'recipe_editor_page.dart';
import 'recipe_image.dart';

class RecipeListPage extends ConsumerWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            SvgPicture.asset('assets/branding/beet_mark.svg', width: 28, height: 28),
            const SizedBox(width: 8),
            const Text('Beet-It'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecipeEditorPage()),
          );
          ref.invalidate(recipeListProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: 'Cerca ricette',
              leading: const Icon(Icons.search),
              onChanged: (v) =>
                  ref.read(recipeSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: recipes.when(
              loading: () =>
                  const Center(child: CookingLoader(size: 96)),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(recipeListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SwipeRecipeTile(recipe: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile con azioni a scorrimento (come le email): Preferiti, Spesa, Elimina.
class _SwipeRecipeTile extends ConsumerWidget {
  final Recipe recipe;
  const _SwipeRecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(recipe.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.75,
        children: [
          SlidableAction(
            onPressed: (_) async {
              await ref.read(recipeRepositoryProvider)
                  .setFavorite(recipe.id!, !recipe.isFavorite);
              ref.invalidate(recipeListProvider);
            },
            backgroundColor: const Color(0xFFB5326B),
            foregroundColor: Colors.white,
            icon: recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: 'Preferiti',
          ),
          SlidableAction(
            onPressed: (_) async {
              await ref.read(shoppingRepositoryProvider).addFromRecipe(recipe);
              ref.invalidate(shoppingListProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('"${recipe.title}" aggiunta alla lista della spesa'),
                ));
              }
            },
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            icon: Icons.add_shopping_cart,
            label: 'Spesa',
          ),
          SlidableAction(
            onPressed: (_) async {
              await ref.read(recipeRepositoryProvider).delete(recipe.id!);
              ref.invalidate(recipeListProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('"${recipe.title}" eliminata'),
                ));
              }
            },
            backgroundColor: const Color(0xFFD1495B),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Elimina',
          ),
        ],
      ),
      child: _RecipeTile(recipe: recipe),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final kcal = recipe.nutrition?['kcal'];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeDetailPage(recipeId: recipe.id!)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: RecipeImage(path: recipe.imageUrl, width: 76, height: 76),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (recipe.totalMinutes != null) ...[
                        Icon(Icons.schedule, size: 14, color: Theme.of(context).hintColor),
                        const SizedBox(width: 3),
                        Text('${recipe.totalMinutes} min',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                        const SizedBox(width: 12),
                      ],
                      if (kcal != null) ...[
                        Icon(Icons.local_fire_department, size: 14, color: Theme.of(context).hintColor),
                        const SizedBox(width: 3),
                        Text('${(kcal as num).round()} kcal',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                      ],
                    ]),
                    if (recipe.dietTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: DietBadges(dietTags: recipe.dietTags),
                      ),
                  ],
                ),
              ),
              if (recipe.isFavorite)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.favorite, color: Color(0xFFB5326B), size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48),
            SizedBox(height: 12),
            Text('Nessuna ricetta',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Importa la tua prima ricetta dalla scheda Importa.',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

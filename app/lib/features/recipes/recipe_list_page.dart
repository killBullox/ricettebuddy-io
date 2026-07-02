import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import 'recipe_detail_page.dart';

class RecipeListPage extends ConsumerWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ricette')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref
              .read(recipeRepositoryProvider)
              .create(const Recipe(title: 'Nuova ricetta'));
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
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(recipeListProvider),
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _RecipeTile(recipe: list[i]),
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

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _Thumb(url: recipe.imageUrl),
      title: Text(recipe.title),
      subtitle: recipe.totalMinutes != null
          ? Text('${recipe.totalMinutes} min')
          : null,
      trailing: recipe.isFavorite
          ? const Icon(Icons.favorite, color: Colors.pink)
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailPage(recipeId: recipe.id!),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url == null
            ? Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.restaurant),
              )
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
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

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

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
          if (recipe.videoMp4 != null || recipe.videoUrl != null)
            _VideoSection(
              poster: recipe.videoUrl,
              mp4: recipe.videoMp4,
              link: recipe.sourceUrl,
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
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s.position + 1}. ${s.text}'),
                              if (s.imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: RecipeImage(
                                        path: s.imageUrl,
                                        width: double.infinity,
                                        height: 180),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          if (recipe.sourceUrl != null)
            _Section(
              title: 'Fonte',
              child: InkWell(
                onTap: () => launchUrl(Uri.parse(recipe.sourceUrl!),
                    mode: LaunchMode.externalApplication),
                child: Text(recipe.sourceUrl!,
                    style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline)),
              ),
            ),
          const SizedBox(height: 32),
        ]),
      ],
    );
  }
}

/// Video della ricetta: mostra l'anteprima; al tap riproduce l'MP4 inline
/// (player con controlli). Se manca l'MP4, apre il video sulla pagina originale.
class _VideoSection extends StatefulWidget {
  final String? poster;
  final String? mp4;
  final String? link;
  const _VideoSection({this.poster, this.mp4, this.link});

  @override
  State<_VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<_VideoSection> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _loading = false;

  Future<void> _openSource() async {
    if (widget.link != null) {
      await launchUrl(Uri.parse(widget.link!),
          mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _start() async {
    if (widget.mp4 == null) {
      await _openSource();
      return;
    }
    setState(() => _loading = true);
    // Riproduce tramite l'endpoint /video del server locale, che rimuxa al volo
    // in MP4 frammentato (gli MP4 di GZ non sono faststart) -> parte subito.
    final playUrl =
        Uri.base.resolve('video?u=${Uri.encodeQueryComponent(widget.mp4!)}');
    final c = VideoPlayerController.networkUrl(playUrl);
    try {
      await c.initialize().timeout(const Duration(seconds: 30));
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _chewie = ChewieController(
          videoPlayerController: c,
          autoPlay: true,
          looping: false,
          aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
        );
        _loading = false;
      });
    } catch (_) {
      c.dispose();
      if (!mounted) return;
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video non riproducibile, apro la fonte.')),
        );
      }
      await _openSource();
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Video ricetta',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _chewie != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller!.value.aspectRatio,
                child: Chewie(controller: _chewie!),
              )
            : InkWell(
                onTap: _loading ? null : _start,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RecipeImage(
                        path: widget.poster,
                        width: double.infinity,
                        height: 200),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Icon(Icons.play_arrow,
                              color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
      ),
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

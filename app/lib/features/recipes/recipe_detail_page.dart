import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/enums.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';
import 'cook_mode_page.dart';
import 'diet_badges.dart';
import 'ingredient_icon.dart';
import 'nutrition_donut.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: recipe.imageUrl != null ? 240 : kToolbarHeight,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifica',
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RecipeEditorPage(existing: recipe),
                    ));
                    ref.invalidate(recipeDetailProvider(recipe.id!));
                    ref.invalidate(recipeListProvider);
                  },
                ),
                IconButton(
                  icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border),
                  onPressed: () async {
                    await ref.read(recipeRepositoryProvider)
                        .setFavorite(recipe.id!, !recipe.isFavorite);
                    ref.invalidate(recipeDetailProvider(recipe.id!));
                    ref.invalidate(recipeListProvider);
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                background: recipe.imageUrl != null
                    ? RecipeImage(path: recipe.imageUrl, iconSize: 48)
                    : null,
              ),
              bottom: const TabBar(
                tabs: [Tab(text: 'RICETTA'), Tab(text: 'LISTA SPESA')],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _RecipeTab(recipe: recipe),
              _ShoppingTab(recipe: recipe),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riga ingrediente con iconcina (o pallino neutro se non c'è emoji adatta).
Widget ingredientRow(BuildContext context, String raw) {
  final emoji = ingredientEmoji(raw);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEDE6),
            borderRadius: BorderRadius.circular(9),
          ),
          child: emoji.isEmpty
              ? Icon(Icons.circle, size: 7, color: Theme.of(context).hintColor)
              : Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(raw),
        )),
      ],
    ),
  );
}

class _RecipeTab extends ConsumerWidget {
  final Recipe recipe;
  const _RecipeTab({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = [...recipe.steps]..sort((a, b) => a.position - b.position);
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
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
          if (recipe.wasVegan == false)
            _VeganizedBanner(substitutions: recipe.substitutions),
          if (recipe.nutrition != null) NutritionDonut(n: recipe.nutrition!),
          if (recipe.category != null ||
              recipe.difficulty != null ||
              recipe.allergens.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (recipe.category != null) _MetaChip(icon: Icons.restaurant_menu, text: recipe.category!),
                  if (recipe.difficulty != null) _MetaChip(icon: Icons.bar_chart, text: recipe.difficulty!),
                  if (recipe.cuisine != null) _MetaChip(icon: Icons.public, text: recipe.cuisine!),
                  for (final a in recipe.allergens)
                    _MetaChip(icon: Icons.warning_amber, text: a),
                ],
              ),
            ),
          _Section(
            title: 'Ingredienti',
            child: recipe.ingredients.isEmpty
                ? const Text('Nessun ingrediente')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final ing in recipe.ingredients)
                        ingredientRow(context, ing.rawText),
                    ],
                  ),
          ),
          if (recipe.videoMp4 != null || recipe.videoUrl != null)
            _VideoSection(
              poster: recipe.videoUrl,
              mp4: recipe.videoMp4,
              link: recipe.sourceUrl,
            ),
          if (steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CookModePage(recipe: recipe),
                  )),
                  icon: const Icon(Icons.soup_kitchen),
                  label: const Text('Cucina passo-passo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
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
      ],
    );
  }
}

/// Tab "Lista spesa" della ricetta: ingredienti selezionabili + aggiunta alla
/// lista della spesa generale.
class _ShoppingTab extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _ShoppingTab({required this.recipe});

  @override
  ConsumerState<_ShoppingTab> createState() => _ShoppingTabState();
}

class _ShoppingTabState extends ConsumerState<_ShoppingTab> {
  late final Set<int> _selected =
      {for (var i = 0; i < widget.recipe.ingredients.length; i++) i};
  bool _adding = false;

  Future<void> _addSelected() async {
    setState(() => _adding = true);
    final chosen = [
      for (var i = 0; i < widget.recipe.ingredients.length; i++)
        if (_selected.contains(i)) widget.recipe.ingredients[i],
    ];
    // Riusa addFromRecipe passando una ricetta con i soli ingredienti scelti.
    final subset = widget.recipe.copyWith(ingredients: chosen);
    await ref.read(shoppingRepositoryProvider).addFromRecipe(subset);
    ref.invalidate(shoppingListProvider);
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chosen.length} ingredienti aggiunti alla lista della spesa'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ings = widget.recipe.ingredients;
    if (ings.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('Nessun ingrediente da aggiungere.'),
      ));
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              for (var i = 0; i < ings.length; i++)
                CheckboxListTile(
                  dense: true,
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() =>
                      v == true ? _selected.add(i) : _selected.remove(i)),
                  secondary: Container(
                    width: 30, height: 30, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEDE6),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: ingredientEmoji(ings[i].rawText).isEmpty
                        ? Icon(Icons.circle, size: 7, color: Theme.of(context).hintColor)
                        : Text(ingredientEmoji(ings[i].rawText), style: const TextStyle(fontSize: 16)),
                  ),
                  title: Text(ings[i].rawText),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _adding || _selected.isEmpty ? null : _addSelected,
                icon: _adding
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_shopping_cart),
                label: Text('Aggiungi ${_selected.length} alla lista della spesa'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ),
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
  bool _failed = false;
  String? _errorText;

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
    } catch (e) {
      c.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _errorText = '$e';
      });
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
                onTap: _loading ? null : (_failed ? _openSource : _start),
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
                          : Icon(_failed ? Icons.open_in_new : Icons.play_arrow,
                              color: Colors.white, size: 40),
                    ),
                    if (_failed)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            'Riproduzione non riuscita — tocca per aprire su GialloZafferano'
                            '${_errorText != null ? '\n$_errorText' : ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _VeganizedBanner extends StatelessWidget {
  final List<Map<String, dynamic>> substitutions;
  const _VeganizedBanner({required this.substitutions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🥑 ', style: TextStyle(fontSize: 18)),
            Text('Ricetta veganizzata',
                style: Theme.of(context).textTheme.titleSmall!
                    .copyWith(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          for (final s in substitutions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
                  children: [
                    TextSpan(text: '${s['original']} ', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                    const TextSpan(text: '→ '),
                    TextSpan(text: '${s['vegan']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    if ((s['note'] ?? '').toString().isNotEmpty)
                      TextSpan(text: '  ·  ${s['note']}', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

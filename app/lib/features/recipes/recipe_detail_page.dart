import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import '../../common/cooking_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../config.dart';
import '../../data/models/enums.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/shopping_repository.dart';
import '../../l10n/app_localizations.dart';
import 'cook_mode_page.dart';
import 'ingredient_avatar.dart';
import 'ingredient_icon.dart';
import 'nutrition_donut.dart';
import 'recipe_editor_page.dart';
import 'recipe_image.dart';
import 'recipe_labels.dart';
import 'step_ingredients.dart';

/// Override LOCALE delle porzioni mostrate nel dettaglio (chiave = id ricetta).
/// NON tocca il database: è solo una regolazione di visualizzazione. Scrivere
/// sul catalogo (user_id null) fallisce per gli utenti non-team a causa della
/// RLS — porzioni "bloccate" — e per il team cambierebbe il valore per TUTTI.
final _servingsOverrideProvider =
    StateProvider.autoDispose.family<int?, String>((ref, id) => null);

class RecipeDetailPage extends ConsumerWidget {
  final String recipeId;
  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      body: async.when(
        loading: () => const Center(
            child: CookingLoader(size: 96, style: BeetLoaderStyle.bounce)),
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
        // Trascina verso il basso per ricaricare la ricetta.
        body: RefreshIndicator(
          // Con NestedScrollView lo scroll parte dalla lista interna (depth>0):
          // senza questo predicate il pull-to-refresh non scatta mai.
          notificationPredicate: (n) => n.depth <= 2,
          onRefresh: () async {
            // Aggiorna la foto dalla fonte (server) e ricarica la ricetta.
            try {
              await ref
                  .read(recipeRepositoryProvider)
                  .refreshFromSource(recipe.id!);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
                );
              }
            }
            ref.invalidate(recipeDetailProvider(recipe.id!));
            ref.invalidate(recipeListProvider);
            await ref.read(recipeDetailProvider(recipe.id!).future);
          },
          child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: recipe.imageUrl != null ? 320 : null,
              pinned: true,
              backgroundColor: const Color(0xFFB5326B),
              foregroundColor: Colors.white,
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
              // La foto è solo decorativa: nessun testo sopra (così non ci sono
              // problemi di leggibilità con immagini chiare).
              flexibleSpace: recipe.imageUrl == null
                  ? null
                  : FlexibleSpaceBar(
                      background: RecipeImage(path: recipe.imageUrl, iconSize: 48),
                    ),
              // Titolo su banda beet solida + tab: sempre leggibili.
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(112),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFB5326B),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Text(recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 19,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    ColoredBox(
                      color: const Color(0xFFFBFAF7),
                      child: TabBar(
                        labelColor: const Color(0xFFB5326B),
                        unselectedLabelColor: const Color(0xFF898781),
                        indicatorColor: const Color(0xFF2E7D32),
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        tabs: [
                          Tab(text: AppLocalizations.of(context).tabRecipe),
                          Tab(text: AppLocalizations.of(context).tabShopping),
                        ],
                      ),
                    ),
                  ],
                ),
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
      ),
    );
  }
}

/// Scala la DOSE iniziale di un ingrediente in base alle porzioni mostrate.
/// Es. "200 g carota" (base 4) mostrato per 6 -> "300 g carota".
/// Scala SOLO il numero in testa (la dose): non tocca numeri dentro il nome
/// (es. "farina 00", "cioccolato 70%") ne', ovviamente, tempi/temperature.
String scaleIngredientText(String raw, int baseServings, int shownServings) {
  if (baseServings <= 0 || shownServings <= 0 || shownServings == baseServings) {
    return raw;
  }
  final factor = shownServings / baseServings;
  String fmt(double v) {
    final r = (v * 10).round() / 10.0; // un decimale
    if ((r - r.roundToDouble()).abs() < 0.049) return r.round().toString();
    return r.toStringAsFixed(1).replaceAll('.', ','); // virgola decimale IT
  }
  double val(String s) => double.parse(s.replaceAll(',', '.'));
  // range "2-3 foglie" -> scala entrambi gli estremi
  final range =
      RegExp(r'^(\s*)(\d+(?:[.,]\d+)?)(\s*[-–]\s*)(\d+(?:[.,]\d+)?)');
  final mr = range.firstMatch(raw);
  if (mr != null) {
    final rep = '${mr.group(1)}${fmt(val(mr.group(2)!) * factor)}'
        '${mr.group(3)}${fmt(val(mr.group(4)!) * factor)}';
    return raw.replaceRange(0, mr.end, rep);
  }
  // singola dose in testa
  final single = RegExp(r'^(\s*)(\d+(?:[.,]\d+)?)');
  final ms = single.firstMatch(raw);
  if (ms == null) return raw; // "q.b.", "sale q.b." -> nessuna dose da scalare
  return raw.replaceRange(
      0, ms.end, '${ms.group(1)}${fmt(val(ms.group(2)!) * factor)}');
}

/// Riga ingrediente con foto realistica. Le [porzioni] mostrate scalano la dose.
Widget ingredientRow(BuildContext context, Ingredient ing,
    {int baseServings = 0, int shownServings = 0}) {
  final text = scaleIngredientText(ing.rawText, baseServings, shownServings);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // L'avatar resta sul testo originale (serve solo per la foto).
        IngredientAvatar(raw: ing.rawText, img: ing.img, size: 38),
        const SizedBox(width: 10),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(text),
        )),
      ],
    ),
  );
}

/// Card impatto ambientale: CO₂ risparmiata veganizzando/scegliendo la ricetta,
/// con un'equivalenza intuitiva (km in auto).
class _Co2Card extends StatelessWidget {
  final double kg;
  final bool veganized;
  const _Co2Card({required this.kg, required this.veganized});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final km = (kg / 0.12).round(); // ~0.12 kg CO2e per km in auto
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x402E7D32)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32), shape: BoxShape.circle),
              child: const Icon(Icons.eco, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.co2Saved(kg.toStringAsFixed(1)),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1B5E20))),
                  const SizedBox(height: 2),
                  Text(
                    veganized
                        ? l.co2SubVeganized('$km')
                        : l.co2SubChosen('$km'),
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTab extends ConsumerWidget {
  final Recipe recipe;
  const _RecipeTab({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = [...recipe.steps]..sort((a, b) => a.position - b.position);
    // Porzioni mostrate = override locale se presente, altrimenti quelle base.
    final displayServings =
        ref.watch(_servingsOverrideProvider(recipe.id ?? '')) ?? recipe.servings;
    return ListView(
      // Sempre trascinabile (per il pull-to-refresh) anche se il contenuto è corto.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
          if (recipe.fromNutritionService)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety,
                      size: 18, color: Color(0xFF3B8C43)),
                  SizedBox(width: 8),
                  // Expanded → il testo va a capo invece di essere troncato.
                  Expanded(
                    child: Text(
                      'Elaborata dal servizio di consulenza nutrizionale',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E6B33)),
                    ),
                  ),
                ],
              ),
            )
          else if (recipe.source == RecipeSource.generated)
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
                  onPressed: displayServings > 1
                      ? () => ref
                          .read(_servingsOverrideProvider(recipe.id ?? '')
                              .notifier)
                          .state = displayServings - 1
                      : null,
                ),
                Text('$displayServings',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => ref
                      .read(_servingsOverrideProvider(recipe.id ?? '').notifier)
                      .state = displayServings + 1,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: RecipeLabels(recipe: recipe),
          ),
          if (recipe.co2Saved != null && recipe.co2Saved! > 0)
            _Co2Card(kg: recipe.co2Saved!, veganized: recipe.isVeganized),
          if (recipe.wasVegan == false)
            _VeganizedBanner(substitutions: recipe.substitutions),
          if (recipe.nutrition != null)
            NutritionDonut(n: recipe.nutrition!, servings: displayServings),
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
            title: displayServings == recipe.servings
                ? 'Ingredienti'
                : 'Ingredienti · per $displayServings porzioni',
            child: recipe.ingredients.isEmpty
                ? const Text('Nessun ingrediente')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final ing in recipe.ingredients)
                        ingredientRow(context, ing,
                            baseServings: recipe.servings,
                            shownServings: displayServings),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s.position + 1}. ${s.text}'),
                              // Foto degli ingredienti citati in questo passaggio.
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: StepIngredients(
                                  stepText: s.text,
                                  ingredients: recipe.ingredients,
                                  size: 64,
                                ),
                              ),
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

  /// Prodotto da comprare (senza preparazione): usa il nome normalizzato
  /// dell'AI, con fallback al pulitore client per le ricette non arricchite.
  String _product(Ingredient ing) {
    final n = ing.normalizedName?.trim();
    if (n != null && n.isNotEmpty) {
      return n[0].toUpperCase() + n.substring(1);
    }
    return cleanIngredientName(ing.rawText);
  }

  /// Fattore di scala dalle porzioni scelte nel dettaglio (override locale).
  double _factor({required bool watch}) {
    final base = widget.recipe.servings;
    if (base <= 0) return 1;
    final prov = _servingsOverrideProvider(widget.recipe.id ?? '');
    final shown = (watch ? ref.watch(prov) : ref.read(prov)) ?? base;
    return shown / base;
  }

  /// Quantità scalata (1 decimale), null se assente.
  double? _scaledQty(Ingredient ing, double factor) {
    final q = ing.quantity;
    if (q == null) return null;
    return (q * factor * 10).roundToDouble() / 10;
  }

  /// Quantità formattata (es. "300 g", "1,5"), stringa vuota se assente.
  String _amount(Ingredient ing, double factor) {
    final q = _scaledQty(ing, factor);
    if (q == null) return '';
    final qs = q == q.roundToDouble()
        ? q.toInt().toString()
        : q.toStringAsFixed(1).replaceAll('.', ','); // virgola decimale IT
    return ing.unit != null && ing.unit!.isNotEmpty ? '$qs ${ing.unit}' : qs;
  }

  Future<void> _addSelected() async {
    setState(() => _adding = true);
    // Le dosi in lista rispettano le porzioni scelte nel dettaglio.
    final factor = _factor(watch: false);
    // Aggiunge il PRODOTTO pulito (non la riga con la preparazione).
    final chosen = [
      for (var i = 0; i < widget.recipe.ingredients.length; i++)
        if (_selected.contains(i))
          Ingredient(
            position: i,
            rawText: _product(widget.recipe.ingredients[i]),
            normalizedName: _product(widget.recipe.ingredients[i]),
            quantity: _scaledQty(widget.recipe.ingredients[i], factor),
            unit: widget.recipe.ingredients[i].unit,
            aisleCategory: widget.recipe.ingredients[i].aisleCategory,
          ),
    ];
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
    final factor = _factor(watch: true);
    final shownServings =
        ref.watch(_servingsOverrideProvider(widget.recipe.id ?? '')) ??
            widget.recipe.servings;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Dosi per $shownServings porzioni',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).hintColor)),
          ),
        ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              for (var i = 0; i < ings.length; i++)
                CheckboxListTile(
                  dense: true,
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() =>
                      v == true ? _selected.add(i) : _selected.remove(i)),
                  secondary: IngredientAvatar(raw: ings[i].rawText, img: ings[i].img, size: 38),
                  title: Text(_product(ings[i]),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: _amount(ings[i], factor).isEmpty
                      ? null
                      : Text(_amount(ings[i], factor)),
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
        Config.backendUri('video?u=${Uri.encodeQueryComponent(widget.mp4!)}');
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
            SvgPicture.asset('assets/branding/beet_mark.svg', width: 20, height: 20),
            const SizedBox(width: 6),
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

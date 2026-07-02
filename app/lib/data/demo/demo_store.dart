import '../models/diet.dart';
import '../models/enums.dart';
import '../models/feed_source.dart';
import '../models/ingredient.dart';
import '../models/meal_plan_entry.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_step.dart';
import '../models/shopping_item.dart';
import '../repositories/creative_repository.dart';

/// Magazzino dati in memoria per la MODALITÀ DEMO (nessun Supabase).
/// Attiva quando l'app non è configurata: permette di provare tutte le
/// schermate con dati di esempio, senza account né backend.
class DemoStore {
  DemoStore._();
  static final DemoStore instance = DemoStore._();

  int _seq = 100;
  String _id() => 'demo-${_seq++}';

  late final List<Recipe> recipes = _seedRecipes();
  final List<PantryItem> pantry = _seedPantry();
  final List<ShoppingItem> shopping = [];
  final List<MealPlanEntry> mealPlan = [];
  final List<FeedSource> sources = _seedSources();

  /// Ricette che le sorgenti/feed potrebbero importare (simulazione demo).
  late final List<Recipe> _feedCandidates = _seedFeedCandidates();

  // --- Ricette ---------------------------------------------------------------

  List<Recipe> listRecipes({String? search}) {
    final all = [...recipes]..sort((a, b) =>
        (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000)));
    if (search == null || search.trim().isEmpty) return all;
    final q = search.toLowerCase();
    return all.where((r) => r.title.toLowerCase().contains(q)).toList();
  }

  Recipe getRecipe(String id) => recipes.firstWhere((r) => r.id == id);

  String createRecipe(Recipe r) {
    final id = _id();
    recipes.add(_withMeta(r, id));
    return id;
  }

  void setFavorite(String id, bool value) =>
      _replace(id, (r) => r.copyWith(isFavorite: value));

  void setServings(String id, int servings) =>
      _replace(id, (r) => r.copyWith(servings: servings));

  void deleteRecipe(String id) => recipes.removeWhere((r) => r.id == id);

  // --- Dispensa --------------------------------------------------------------

  void addPantry(PantryItem item) =>
      pantry.add(PantryItem(
        id: _id(),
        rawText: item.rawText,
        normalizedName: item.normalizedName,
        quantity: item.quantity,
        unit: item.unit,
        aisleCategory: item.aisleCategory,
        expiryDate: item.expiryDate,
      ));

  void deletePantry(String id) => pantry.removeWhere((p) => p.id == id);

  // --- Spesa -----------------------------------------------------------------

  void addFreeShopping(String name) =>
      shopping.add(ShoppingItem(id: _id(), name: name));

  void setShoppingChecked(String id, bool value) {
    final i = shopping.indexWhere((s) => s.id == id);
    if (i < 0) return;
    final s = shopping[i];
    shopping[i] = ShoppingItem(
      id: s.id,
      name: s.name,
      quantity: s.quantity,
      unit: s.unit,
      aisleCategory: s.aisleCategory,
      isChecked: value,
      sourceRecipeId: s.sourceRecipeId,
    );
  }

  void deleteShopping(String id) =>
      shopping.removeWhere((s) => s.id == id);

  void clearCheckedShopping() =>
      shopping.removeWhere((s) => s.isChecked);

  void addShoppingFromRecipe(Recipe recipe) {
    for (final ing in recipe.ingredients) {
      shopping.add(ShoppingItem(
        id: _id(),
        name: ing.normalizedName ?? ing.rawText,
        quantity: ing.quantity,
        unit: ing.unit,
        aisleCategory: ing.aisleCategory,
        sourceRecipeId: recipe.id,
      ));
    }
  }

  // --- Piano pasti -----------------------------------------------------------

  List<MealPlanEntry> mealPlanForWeek(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    return mealPlan
        .where((e) => !e.date.isBefore(weekStart) && e.date.isBefore(end))
        .toList();
  }

  // --- Chef creativo ---------------------------------------------------------

  List<DoableRecipe> doableFromPantry({double minCoverage = 0.6}) {
    final have = pantry.map((p) => p.normalizedName.toLowerCase()).toSet();
    final out = <DoableRecipe>[];
    for (final r in recipes) {
      final named = r.ingredients
          .where((i) => (i.normalizedName ?? '').trim().isNotEmpty)
          .map((i) => i.normalizedName!.toLowerCase())
          .toList();
      if (named.isEmpty) continue;
      final missing = named.where((n) => !have.contains(n)).toSet().toList();
      final haveCount = named.length - missing.length;
      final coverage = haveCount / named.length;
      if (coverage >= minCoverage) {
        out.add(DoableRecipe(
          recipeId: r.id!,
          title: r.title,
          totalNamed: named.length,
          haveCount: haveCount,
          coverage: double.parse(coverage.toStringAsFixed(2)),
          missing: missing,
        ));
      }
    }
    out.sort((a, b) => b.coverage.compareTo(a.coverage));
    return out;
  }

  List<Recipe> generateIdeas({int count = 3}) {
    final base = pantry.isNotEmpty
        ? pantry.map((p) => p.rawText).toList()
        : ['pasta', 'pomodoro', 'aglio'];
    return List.generate(count, (i) {
      return Recipe(
        id: null,
        title: 'Idea ${i + 1} con ${base.first}',
        source: RecipeSource.generated,
        prepMinutes: 10,
        cookMinutes: 20,
        ingredients: [
          for (final b in base.take(5)) Ingredient(rawText: b),
        ],
        steps: const [
          RecipeStep(position: 0, text: 'Prepara gli ingredienti.'),
          RecipeStep(position: 1, text: 'Cuoci il tutto a fuoco medio.'),
          RecipeStep(position: 2, text: 'Impiatta e servi.'),
        ],
      );
    });
  }

  String importFromUrl(String url) {
    final id = _id();
    recipes.add(_withMeta(
      Recipe(
        title: 'Ricetta importata (demo)',
        imageUrl: 'assets/images/pomodoro.jpg',
        sourceUrl: url,
        source: RecipeSource.web,
        ingredients: const [
          Ingredient(rawText: '200 g pasta', quantity: 200, unit: 'g',
              normalizedName: 'pasta', aisleCategory: 'Dispensa'),
        ],
        steps: const [RecipeStep(position: 0, text: 'Segui il link originale.')],
      ),
      id,
    ));
    return id;
  }

  // --- Sorgenti / Feed -------------------------------------------------------

  String addSource(FeedSource s) {
    final id = _id();
    sources.add(FeedSource(
      id: id,
      type: s.type,
      reference: s.reference,
      name: s.name,
      autoImport: s.autoImport,
    ));
    return id;
  }

  void deleteSource(String id) => sources.removeWhere((s) => s.id == id);

  void toggleSourceAuto(String id, bool value) {
    final i = sources.indexWhere((s) => s.id == id);
    if (i >= 0) sources[i] = sources[i].copyWith(autoImport: value);
  }

  /// Analizza una sorgente e importa le ricette conformi ai regimi attivi
  /// che non sono già presenti. Ritorna le ricette importate.
  List<Recipe> analyzeSource(String sourceId, Set<Diet> activeDiets) {
    final i = sources.indexWhere((s) => s.id == sourceId);
    if (i < 0) return [];
    final existingTitles = recipes.map((r) => r.title.toLowerCase()).toSet();

    final imported = <Recipe>[];
    for (final cand in _feedCandidates) {
      if (existingTitles.contains(cand.title.toLowerCase())) continue;
      if (!_matchesDiets(cand, activeDiets)) continue;
      final id = _id();
      recipes.add(_withMeta(cand, id));
      imported.add(recipes.last);
    }
    sources[i] = sources[i].copyWith(lastCheckedAt: DateTime.now());
    return imported;
  }

  /// Anteprima: quante ricette del feed sono conformi ai regimi (per la UI).
  int compatibleCount(Set<Diet> activeDiets) => _feedCandidates
      .where((c) => _matchesDiets(c, activeDiets))
      .length;

  bool _matchesDiets(Recipe r, Set<Diet> diets) =>
      diets.every((d) => r.dietTags.contains(d.name));

  // --- Piano pasti (assegnazione) --------------------------------------------

  void setSlot(DateTime date, MealSlot slot, String recipeId, int servings) {
    final d = DateTime(date.year, date.month, date.day);
    mealPlan.removeWhere((e) =>
        e.date == d && e.slot == slot);
    final recipe = recipes.firstWhere((r) => r.id == recipeId);
    mealPlan.add(MealPlanEntry(
      id: _id(),
      date: d,
      slot: slot,
      servings: servings,
      recipeId: recipeId,
      recipeTitle: recipe.title,
    ));
  }

  void clearSlotByDaySlot(DateTime date, MealSlot slot) {
    final d = DateTime(date.year, date.month, date.day);
    mealPlan.removeWhere((e) => e.date == d && e.slot == slot);
  }

  /// Genera la spesa aggregando gli ingredienti delle ricette pianificate.
  int generateShoppingFromWeek(DateTime weekStart) {
    final entries = mealPlanForWeek(weekStart);
    var added = 0;
    for (final e in entries) {
      if (e.recipeId == null) continue;
      final r = recipes.firstWhere((x) => x.id == e.recipeId);
      addShoppingFromRecipe(r);
      added += r.ingredients.length;
    }
    return added;
  }

  // --- Modifica ricetta (editor) ---------------------------------------------

  void updateRecipe(String id, Recipe updated) {
    final i = recipes.indexWhere((r) => r.id == id);
    if (i < 0) return;
    recipes[i] = _withMeta(updated, id);
  }

  // --- Helper ----------------------------------------------------------------

  void _replace(String id, Recipe Function(Recipe) f) {
    final i = recipes.indexWhere((r) => r.id == id);
    if (i >= 0) recipes[i] = f(recipes[i]);
  }

  Recipe _withMeta(Recipe r, String id) => Recipe(
        id: id,
        title: r.title,
        imageUrl: r.imageUrl,
        sourceUrl: r.sourceUrl,
        source: r.source,
        originalLanguage: r.originalLanguage,
        prepMinutes: r.prepMinutes,
        cookMinutes: r.cookMinutes,
        servings: r.servings,
        tags: r.tags,
        dietTags: r.dietTags,
        isFavorite: r.isFavorite,
        ingredients: r.ingredients,
        steps: r.steps,
        createdAt: DateTime(2026, 7, 2),
        updatedAt: DateTime(2026, 7, 2, 0, _seq),
      );

  // --- Dati seed -------------------------------------------------------------

  static List<Recipe> _seedRecipes() => [
        Recipe(
          id: 'demo-1',
          title: 'Spaghetti aglio, olio e peperoncino',
          imageUrl: 'assets/images/spaghetti.jpg',
          source: RecipeSource.manual,
          prepMinutes: 5,
          cookMinutes: 12,
          servings: 2,
          isFavorite: true,
          tags: const ['primo', 'veloce'],
          dietTags: const ['vegan', 'vegetarian', 'lactoseFree', 'pescetarian'],
          createdAt: DateTime(2026, 6, 30),
          updatedAt: DateTime(2026, 7, 1),
          ingredients: const [
            Ingredient(rawText: '200 g spaghetti', quantity: 200, unit: 'g',
                normalizedName: 'spaghetti', aisleCategory: 'Dispensa'),
            Ingredient(rawText: '2 spicchi aglio', quantity: 2, unit: 'pz',
                normalizedName: 'aglio', aisleCategory: 'Ortofrutta'),
            Ingredient(rawText: 'olio evo q.b.', normalizedName: 'olio',
                aisleCategory: 'Dispensa'),
            Ingredient(rawText: 'peperoncino', normalizedName: 'peperoncino',
                aisleCategory: 'Dispensa'),
          ],
          steps: const [
            RecipeStep(position: 0, text: 'Cuoci gli spaghetti in acqua salata.'),
            RecipeStep(position: 1, text: 'Rosola aglio e peperoncino nell\'olio.'),
            RecipeStep(position: 2, text: 'Manteca la pasta con il condimento.'),
          ],
        ),
        Recipe(
          id: 'demo-2',
          title: 'Frittata di zucchine',
          imageUrl: 'assets/images/frittata.jpg',
          source: RecipeSource.manual,
          prepMinutes: 10,
          cookMinutes: 10,
          servings: 2,
          tags: const ['secondo'],
          dietTags: const ['vegetarian', 'glutenFree', 'pescetarian'],
          createdAt: DateTime(2026, 6, 28),
          updatedAt: DateTime(2026, 6, 29),
          ingredients: const [
            Ingredient(rawText: '4 uova', quantity: 4, unit: 'pz',
                normalizedName: 'uova', aisleCategory: 'Frigo'),
            Ingredient(rawText: '2 zucchine', quantity: 2, unit: 'pz',
                normalizedName: 'zucchine', aisleCategory: 'Ortofrutta'),
            Ingredient(rawText: '50 g parmigiano', quantity: 50, unit: 'g',
                normalizedName: 'parmigiano', aisleCategory: 'Frigo'),
          ],
          steps: const [
            RecipeStep(position: 0, text: 'Affetta e rosola le zucchine.'),
            RecipeStep(position: 1, text: 'Sbatti le uova con il parmigiano.'),
            RecipeStep(position: 2, text: 'Cuoci la frittata su entrambi i lati.'),
          ],
        ),
        Recipe(
          id: 'demo-3',
          title: 'Pasta al pomodoro',
          imageUrl: 'assets/images/pomodoro.jpg',
          source: RecipeSource.web,
          sourceUrl: 'https://example.com/pasta-pomodoro',
          prepMinutes: 5,
          cookMinutes: 20,
          servings: 3,
          tags: const ['primo', 'classico'],
          dietTags: const ['vegan', 'vegetarian', 'lactoseFree', 'pescetarian'],
          createdAt: DateTime(2026, 6, 25),
          updatedAt: DateTime(2026, 6, 26),
          ingredients: const [
            Ingredient(rawText: '300 g pasta', quantity: 300, unit: 'g',
                normalizedName: 'pasta', aisleCategory: 'Dispensa'),
            Ingredient(rawText: '400 g passata di pomodoro', quantity: 400,
                unit: 'g', normalizedName: 'pomodoro', aisleCategory: 'Dispensa'),
            Ingredient(rawText: '1 spicchio aglio', quantity: 1, unit: 'pz',
                normalizedName: 'aglio', aisleCategory: 'Ortofrutta'),
            Ingredient(rawText: 'basilico', normalizedName: 'basilico',
                aisleCategory: 'Ortofrutta'),
          ],
          steps: const [
            RecipeStep(position: 0, text: 'Soffriggi l\'aglio.'),
            RecipeStep(position: 1, text: 'Aggiungi la passata e cuoci 15 min.'),
            RecipeStep(position: 2, text: 'Condisci la pasta e aggiungi basilico.'),
          ],
        ),
      ];

  static List<PantryItem> _seedPantry() => [
        const PantryItem(id: 'p-1', rawText: '500 g pasta',
            normalizedName: 'pasta', quantity: 500, unit: 'g'),
        const PantryItem(id: 'p-2', rawText: 'aglio',
            normalizedName: 'aglio'),
        const PantryItem(id: 'p-3', rawText: 'olio evo',
            normalizedName: 'olio'),
        const PantryItem(id: 'p-4', rawText: 'peperoncino',
            normalizedName: 'peperoncino'),
        const PantryItem(id: 'p-5', rawText: 'passata di pomodoro',
            normalizedName: 'pomodoro'),
      ];

  static List<FeedSource> _seedSources() => [
        const FeedSource(
          id: 's-1',
          type: SourceType.web,
          reference: 'https://www.giallozafferano.it',
          name: 'GialloZafferano',
        ),
        const FeedSource(
          id: 's-2',
          type: SourceType.instagram,
          reference: '@ricette_veloci',
          name: 'Ricette Veloci (IG)',
        ),
      ];

  /// Pool simulato di ricette "trovate" dai feed, con i regimi soddisfatti.
  static List<Recipe> _seedFeedCandidates() => [
        _cand('Insalata di ceci e verdure', 'insalata.jpg', 15, 0,
            ['vegan', 'vegetarian', 'glutenFree', 'lactoseFree', 'pescetarian'],
            ['240 g ceci lessati', '1 cetriolo', 'pomodorini', 'prezzemolo'],
            ['Taglia le verdure a cubetti.', 'Unisci i ceci scolati.',
             'Condisci con olio, limone e sale.']),
        _cand('Risotto ai funghi', 'risotto.jpg', 10, 25,
            ['vegetarian', 'glutenFree', 'pescetarian'],
            ['320 g riso', '250 g funghi', '50 g parmigiano', 'brodo vegetale'],
            ['Tosta il riso in casseruola.', 'Aggiungi il brodo poco per volta.',
             'Manteca con funghi e parmigiano.']),
        _cand('Pollo al limone', 'pollo.jpg', 10, 20,
            ['glutenFree', 'lactoseFree'],
            ['500 g pollo', '1 limone', 'rosmarino', 'olio evo'],
            ['Rosola il pollo nell\'olio.', 'Sfuma col succo di limone.',
             'Cuoci fino a doratura.']),
        _cand('Pancake vegani ai mirtilli', 'pancake.jpg', 10, 10,
            ['vegan', 'vegetarian', 'lactoseFree'],
            ['150 g farina', '200 ml latte di soia', 'mirtilli',
             '1 cucchiaino lievito'],
            ['Mescola gli ingredienti.', 'Scalda la padella.',
             'Cuoci i pancake su entrambi i lati.']),
        _cand('Minestrone di verdure', 'minestrone.jpg', 15, 40,
            ['vegan', 'vegetarian', 'glutenFree', 'lactoseFree', 'pescetarian'],
            ['carote', 'zucchine', 'patate', 'fagioli', 'sedano'],
            ['Taglia tutte le verdure.', 'Copri con acqua e porta a bollore.',
             'Cuoci a fuoco lento 40 minuti.']),
        _cand('Hummus di ceci', 'hummus.jpg', 10, 0,
            ['vegan', 'vegetarian', 'glutenFree', 'lactoseFree', 'pescetarian'],
            ['240 g ceci', '2 cucchiai tahina', '1 limone', 'aglio'],
            ['Frulla i ceci con la tahina.', 'Aggiungi limone e aglio.',
             'Servi con un filo d\'olio.']),
        _cand('Pizza Margherita', 'pizza.jpg', 20, 12,
            ['vegetarian', 'pescetarian'],
            ['250 g farina', '125 ml acqua', 'passata di pomodoro',
             'mozzarella'],
            ['Impasta e lascia lievitare.', 'Stendi e condisci.',
             'Cuoci in forno ben caldo.']),
        _cand('Caponata siciliana', 'caponata.jpg', 20, 30,
            ['vegan', 'vegetarian', 'glutenFree', 'lactoseFree', 'pescetarian'],
            ['2 melanzane', 'sedano', 'olive', 'capperi', 'passata'],
            ['Friggi le melanzane a cubetti.',
             'Cuoci sedano e salsa agrodolce.', 'Unisci tutto e fai insaporire.']),
        _cand('Pasta e fagioli', 'pastafagioli.jpg', 10, 35,
            ['vegan', 'vegetarian', 'lactoseFree', 'pescetarian'],
            ['200 g pasta', '300 g fagioli', 'sedano', 'carota', 'pomodoro'],
            ['Prepara un soffritto.', 'Aggiungi fagioli e acqua.',
             'Cuoci la pasta nella zuppa.']),
        _cand('Ratatouille', 'ratatouille.jpg', 20, 40,
            ['vegan', 'vegetarian', 'glutenFree', 'lactoseFree', 'pescetarian'],
            ['melanzana', 'zucchine', 'peperoni', 'pomodori', 'cipolla'],
            ['Taglia le verdure a rondelle.',
             'Disponi in teglia con la salsa.', 'Inforna per 40 minuti.']),
        _cand('Falafel di ceci', 'falafel.jpg', 20, 15,
            ['vegan', 'vegetarian', 'glutenFree', 'lactoseFree', 'pescetarian'],
            ['250 g ceci secchi ammollati', 'cipolla', 'aglio', 'prezzemolo',
             'cumino'],
            ['Frulla i ceci con le spezie.', 'Forma le polpette.',
             'Friggi fino a doratura.']),
      ];

  /// Costruisce una ricetta candidata dei feed in modo conciso.
  static Recipe _cand(String title, String image, int prep, int cook,
          List<String> diets, List<String> ings, List<String> steps) =>
      Recipe(
        title: title,
        imageUrl: 'assets/images/$image',
        source: RecipeSource.web,
        sourceUrl: 'https://example.com/feed',
        prepMinutes: prep,
        cookMinutes: cook,
        dietTags: diets,
        ingredients: [for (final i in ings) Ingredient(rawText: i)],
        steps: [
          for (final (i, s) in steps.indexed) RecipeStep(position: i, text: s),
        ],
      );
}

import '../models/enums.dart';
import '../models/feed_source.dart';
import '../models/ingredient.dart';
import '../models/meal_plan_entry.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_step.dart';
import '../models/shopping_item.dart';

/// Stato locale in memoria per dispensa, spesa, piano pasti e sorgenti in
/// MODALITÀ DEMO. Le ricette NON stanno qui: arrivano dal backend locale reale
/// (import da GialloZafferano con persistenza su file) — vedi LocalApi.
class DemoStore {
  DemoStore._();
  static final DemoStore instance = DemoStore._();

  int _seq = 100;
  String _id() => 'demo-${_seq++}';

  final List<PantryItem> pantry = _seedPantry();
  final List<ShoppingItem> shopping = [];
  final List<MealPlanEntry> mealPlan = [];
  final List<FeedSource> sources = _seedSources();

  // --- Dispensa --------------------------------------------------------------

  void addPantry(PantryItem item) => pantry.add(PantryItem(
        id: _id(),
        rawText: item.rawText,
        normalizedName: item.normalizedName,
        quantity: item.quantity,
        unit: item.unit,
        aisleCategory: item.aisleCategory,
        expiryDate: item.expiryDate,
      ));

  void deletePantry(String id) => pantry.removeWhere((p) => p.id == id);

  void updatePantry(PantryItem item) {
    final i = pantry.indexWhere((p) => p.id == item.id);
    if (i >= 0) pantry[i] = item;
  }

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

  void deleteShopping(String id) => shopping.removeWhere((s) => s.id == id);

  void clearCheckedShopping() => shopping.removeWhere((s) => s.isChecked);

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

  void setSlot(DateTime date, MealSlot slot, String recipeId, int servings,
      String recipeTitle) {
    final d = DateTime(date.year, date.month, date.day);
    // Più ricette per pasto: aggiunge senza rimuovere le altre. Evita solo il
    // duplicato esatto (stessa ricetta nello stesso pasto).
    final dup = mealPlan.any(
        (e) => e.date == d && e.slot == slot && e.recipeId == recipeId);
    if (dup) return;
    mealPlan.add(MealPlanEntry(
      id: _id(),
      date: d,
      slot: slot,
      servings: servings,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
    ));
  }

  void removeEntry(String id) => mealPlan.removeWhere((e) => e.id == id);

  void clearSlotByDaySlot(DateTime date, MealSlot slot) {
    final d = DateTime(date.year, date.month, date.day);
    mealPlan.removeWhere((e) => e.date == d && e.slot == slot);
  }

  List<String> plannedRecipeIds(DateTime weekStart) => mealPlanForWeek(weekStart)
      .where((e) => e.recipeId != null)
      .map((e) => e.recipeId!)
      .toList();

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

  // --- Chef creativo: idee nuove (mock basato sulla dispensa) -----------------

  List<Recipe> generateIdeas({int count = 3}) {
    final base = pantry.isNotEmpty
        ? pantry.map((p) => p.rawText).toList()
        : ['pasta', 'pomodoro', 'aglio'];
    return List.generate(count, (i) {
      return Recipe(
        title: 'Idea ${i + 1} con ${base.first}',
        source: RecipeSource.generated,
        prepMinutes: 10,
        cookMinutes: 20,
        ingredients: [for (final b in base.take(5)) Ingredient(rawText: b)],
        steps: const [
          RecipeStep(position: 0, text: 'Prepara gli ingredienti.'),
          RecipeStep(position: 1, text: 'Cuoci il tutto a fuoco medio.'),
          RecipeStep(position: 2, text: 'Impiatta e servi.'),
        ],
      );
    });
  }

  // --- Dati seed -------------------------------------------------------------

  static List<PantryItem> _seedPantry() => [
        const PantryItem(id: 'p-1', rawText: '500 g pasta',
            normalizedName: 'pasta', quantity: 500, unit: 'g'),
        const PantryItem(id: 'p-2', rawText: 'aglio', normalizedName: 'aglio'),
        const PantryItem(id: 'p-3', rawText: 'olio evo', normalizedName: 'olio'),
        const PantryItem(id: 'p-4', rawText: 'ceci', normalizedName: 'ceci'),
        const PantryItem(id: 'p-5', rawText: 'pomodoro',
            normalizedName: 'pomodoro'),
      ];

  static List<FeedSource> _seedSources() => [
        const FeedSource(
          id: 's-1',
          type: SourceType.web,
          reference: 'https://www.giallozafferano.it/ricette-vegane/',
          name: 'GialloZafferano · Vegane',
        ),
      ];
}

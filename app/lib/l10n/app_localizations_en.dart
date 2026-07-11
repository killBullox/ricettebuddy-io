// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navImport => 'Import';

  @override
  String get navChef => 'Chef';

  @override
  String get navPlan => 'Plan';

  @override
  String get navShopping => 'Shopping';

  @override
  String get navConsulenza => 'Consultation';

  @override
  String get navSettings => 'Settings';

  @override
  String get pantryTitle => 'Pantry';

  @override
  String get mealPlanTitle => 'Meal plan';

  @override
  String get importTitle => 'Import';

  @override
  String get importFromWebOrSocial => 'From website or social';

  @override
  String get pasteLinkHint => 'Paste a link…';

  @override
  String get importFromLink => 'Import from link';

  @override
  String get fromCamera => 'From camera';

  @override
  String get scanRecipeSoon => 'Scan recipe (coming soon)';

  @override
  String get shareHint =>
      'You can also import from social apps with the Share button (TikTok, Instagram, …).';

  @override
  String get preparingRecipe => 'Preparing your recipe…';

  @override
  String get recipeImported => 'Recipe imported!';

  @override
  String get alreadyInLibrary => 'This recipe is already in your library';

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get searchRecipes => 'Search recipes';

  @override
  String get noRecipes => 'No recipes';

  @override
  String get emptyRecipesBody =>
      'Import your first recipe from the Import tab.';

  @override
  String get tabRecipe => 'RECIPE';

  @override
  String get tabShopping => 'SHOPPING LIST';

  @override
  String get servings => 'Servings';

  @override
  String get veganizedRecipe => 'Veganized recipe';

  @override
  String get actionFavorite => 'Favorite';

  @override
  String get actionShopping => 'Shopping';

  @override
  String get actionDelete => 'Delete';

  @override
  String addedToShopping(Object title) {
    return '\"$title\" added to the shopping list';
  }

  @override
  String recipeDeleted(Object title) {
    return '\"$title\" deleted';
  }

  @override
  String get pantryEmpty =>
      'Pantry is empty.\nAdd what you have at home to get ideas.';

  @override
  String get add => 'Add';

  @override
  String get addToPantry => 'Add to pantry';

  @override
  String get edit => 'Edit';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get consulenzaTitle => 'Consultation';

  @override
  String get bookConsultation => 'Book a consultation';

  @override
  String get generateShopping => 'Generate shopping list';

  @override
  String get chooseRecipe => 'Choose a recipe';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get phaseAnalyzing => 'Analyzing the recipe…';

  @override
  String get phaseVeganizing => 'Veganizing the ingredients…';

  @override
  String get phaseInstructions => 'Writing the cooking steps…';

  @override
  String get phaseNutrition => 'Calculating nutrition facts…';

  @override
  String get phaseCo2 => 'Estimating the environmental impact (CO₂)…';

  @override
  String get phaseReading => 'Reading the recipe…';

  @override
  String get phaseProcessing => 'Preparing your recipe…';

  @override
  String get pasteRecipeTitle => 'Paste the recipe';

  @override
  String get pasteRecipeBody =>
      'Facebook won\'t let us read this reel without logging in. Paste the recipe text (ingredients and steps) and we\'ll veganize and organize it for you.';

  @override
  String get pasteRecipeHint => 'Paste ingredients and steps here…';

  @override
  String get navMore => 'More';

  @override
  String get badgeVeganized => 'Veganized';

  @override
  String get labelVegan => 'Vegan';

  @override
  String get labelHighProtein => 'HIGH PROTEIN';

  @override
  String get labelLowCarb => 'LOW CARB';

  @override
  String get labelLight => 'LIGHT';

  @override
  String get labelHighFiber => 'HIGH FIBER';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filterNoAllergens => 'Without allergens';

  @override
  String get allergenGluten => 'Gluten-free';

  @override
  String get allergenSoy => 'Soy-free';

  @override
  String get allergenNuts => 'Nut-free';

  @override
  String get allergenLactose => 'Lactose-free';

  @override
  String get filterLabels => 'Labels';

  @override
  String get filterMaxKcal => 'Max calories (per serving)';

  @override
  String get filterMinProtein => 'Min protein (per serving)';

  @override
  String filterMaxKcalChip(Object k) {
    return '≤ $k kcal';
  }

  @override
  String filterMinProteinChip(Object p) {
    return '≥ $p g';
  }

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply';

  @override
  String co2Saved(Object kg) {
    return '$kg kg CO₂ saved per serving';
  }

  @override
  String co2SubVeganized(Object km) {
    return 'by veganizing this recipe — like $km km less by car 🚗';
  }

  @override
  String co2SubChosen(Object km) {
    return 'by choosing this plant-based version — like $km km less by car 🚗';
  }

  @override
  String get chefIdeasTitle => 'AI Chef';

  @override
  String get chefThinking => 'The Chef is creating your recipes…';

  @override
  String get chefPrefFast => 'Quick (≤30 min)';

  @override
  String get chefGenerate => 'Generate recipes';

  @override
  String get chefHint =>
      'Pick your preferences and tap Generate: the Chef will invent recipes from what you have in your pantry.';

  @override
  String get saveToCookbook => 'Save to cookbook';

  @override
  String get savedToCookbook => 'Saved';

  @override
  String get ingredientsTitle => 'Ingredients';

  @override
  String get preparationTitle => 'Preparation';

  @override
  String get planHowTitle => 'How do you want to plan?';

  @override
  String get planManualTitle => 'Manual';

  @override
  String get planManualDesc => 'You add recipes to each meal yourself.';

  @override
  String get planAutoTitle => 'Automatic';

  @override
  String get planAutoDesc =>
      'Set filters and a daily calorie cap: the week fills itself with your recipes.';

  @override
  String get planConsultTitle => 'From nutrition consultation';

  @override
  String get planConsultDesc =>
      'Import your nutritionist\'s plan and match it with recipes.';

  @override
  String get planComingSoon => 'Coming soon';

  @override
  String get planMaxKcal => 'Max daily calories';

  @override
  String get planNoLimit => 'No limit';

  @override
  String get planIncludeSnack => 'Include snack';

  @override
  String get planGenerateBtn => 'Generate week plan';

  @override
  String planResultAll(Object n) {
    return '$n meals planned ✓';
  }

  @override
  String planResultPartial(Object filled, Object missing) {
    return '$filled meals planned, $missing left empty: not enough matching recipes with nutrition data.';
  }

  @override
  String get pantryScan => 'Scan food';

  @override
  String get pantryScanCamera => 'Take a photo';

  @override
  String get pantryScanGallery => 'Choose from gallery';

  @override
  String get pantryScanning => 'Recognizing the food…';

  @override
  String get pantryScanFound => 'Recognized items';

  @override
  String get pantryScanNone => 'No food recognized in the photo.';

  @override
  String pantryScanAdded(Object n) {
    return '$n items added to the pantry';
  }
}

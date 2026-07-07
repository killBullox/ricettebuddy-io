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
}

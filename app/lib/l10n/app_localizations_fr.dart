// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navRecipes => 'Recettes';

  @override
  String get navImport => 'Importer';

  @override
  String get navChef => 'Chef';

  @override
  String get navPlan => 'Plan';

  @override
  String get navShopping => 'Courses';

  @override
  String get navConsulenza => 'Consultation';

  @override
  String get navSettings => 'Réglages';

  @override
  String get pantryTitle => 'Garde-manger';

  @override
  String get mealPlanTitle => 'Plan de repas';

  @override
  String get importTitle => 'Importer';

  @override
  String get importFromWebOrSocial => 'Depuis un site ou les réseaux';

  @override
  String get pasteLinkHint => 'Collez un lien…';

  @override
  String get importFromLink => 'Importer depuis un lien';

  @override
  String get fromCamera => 'Depuis l\'appareil photo';

  @override
  String get scanRecipeSoon => 'Scanner une recette (bientôt)';

  @override
  String get shareHint =>
      'Vous pourrez aussi importer depuis les réseaux avec le bouton Partager (TikTok, Instagram, …).';

  @override
  String get preparingRecipe => 'Préparation de votre recette…';

  @override
  String get recipeImported => 'Recette importée !';

  @override
  String get alreadyInLibrary =>
      'Cette recette est déjà dans votre bibliothèque';

  @override
  String importFailed(Object error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String get searchRecipes => 'Rechercher des recettes';

  @override
  String get noRecipes => 'Aucune recette';

  @override
  String get emptyRecipesBody =>
      'Importez votre première recette depuis l\'onglet Importer.';

  @override
  String get tabRecipe => 'RECETTE';

  @override
  String get tabShopping => 'LISTE DE COURSES';

  @override
  String get servings => 'Portions';

  @override
  String get veganizedRecipe => 'Recette véganisée';

  @override
  String get actionFavorite => 'Favoris';

  @override
  String get actionShopping => 'Courses';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String addedToShopping(Object title) {
    return '\"$title\" ajoutée à la liste de courses';
  }

  @override
  String recipeDeleted(Object title) {
    return '\"$title\" supprimée';
  }

  @override
  String get pantryEmpty =>
      'Garde-manger vide.\nAjoutez ce que vous avez chez vous pour recevoir des idées.';

  @override
  String get add => 'Ajouter';

  @override
  String get addToPantry => 'Ajouter au garde-manger';

  @override
  String get edit => 'Modifier';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get consulenzaTitle => 'Consultation';

  @override
  String get bookConsultation => 'Réserver une consultation';

  @override
  String get generateShopping => 'Générer la liste de courses';

  @override
  String get chooseRecipe => 'Choisissez une recette';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Système';
}

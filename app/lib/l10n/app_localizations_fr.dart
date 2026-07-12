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

  @override
  String get phaseAnalyzing => 'Analyse de la recette…';

  @override
  String get phaseVeganizing => 'Véganisation des ingrédients…';

  @override
  String get phaseInstructions => 'Rédaction des étapes de préparation…';

  @override
  String get phaseNutrition => 'Calcul des valeurs nutritionnelles…';

  @override
  String get phaseCo2 => 'Estimation de l\'impact environnemental (CO₂)…';

  @override
  String get phaseReading => 'Lecture de la recette…';

  @override
  String get phaseProcessing => 'Préparation de votre recette…';

  @override
  String get pasteRecipeTitle => 'Colle la recette';

  @override
  String get pasteRecipeBody =>
      'Facebook ne nous laisse pas lire ce reel sans connexion. Colle le texte de la recette (ingrédients et étapes) et on la véganise et on l\'organise pour toi.';

  @override
  String get pasteRecipeHint => 'Colle ici les ingrédients et les étapes…';

  @override
  String get navMore => 'Plus';

  @override
  String get badgeVeganized => 'Véganisée';

  @override
  String get labelVegan => 'Végane';

  @override
  String get labelHighProtein => 'PROTÉINES';

  @override
  String get labelLowCarb => 'LOW CARB';

  @override
  String get labelLight => 'LÉGÈRE';

  @override
  String get labelHighFiber => 'RICHE EN FIBRES';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filterNoAllergens => 'Sans allergènes';

  @override
  String get allergenGluten => 'Sans gluten';

  @override
  String get allergenSoy => 'Sans soja';

  @override
  String get allergenNuts => 'Sans fruits à coque';

  @override
  String get allergenLactose => 'Sans lactose';

  @override
  String get filterLabels => 'Étiquettes';

  @override
  String get filterMaxKcal => 'Calories max (par portion)';

  @override
  String get filterMinProtein => 'Protéines min (par portion)';

  @override
  String filterMaxKcalChip(Object k) {
    return '≤ $k kcal';
  }

  @override
  String filterMinProteinChip(Object p) {
    return '≥ $p g';
  }

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get filterApply => 'Appliquer';

  @override
  String co2Saved(Object kg) {
    return '$kg kg de CO₂ économisés par portion';
  }

  @override
  String co2SubVeganized(Object km) {
    return 'en véganisant cette recette — comme $km km de moins en voiture 🚗';
  }

  @override
  String co2SubChosen(Object km) {
    return 'en choisissant cette version végétale — comme $km km de moins en voiture 🚗';
  }

  @override
  String get chefIdeasTitle => 'Chef IA';

  @override
  String get chefThinking => 'Le Chef crée vos recettes…';

  @override
  String get chefPrefFast => 'Rapide (≤30 min)';

  @override
  String get chefGenerate => 'Générer des recettes';

  @override
  String get chefHint =>
      'Choisis tes préférences et appuie sur Générer : le Chef inventera des recettes avec ce que tu as dans ton garde-manger.';

  @override
  String get saveToCookbook => 'Enregistrer dans le carnet';

  @override
  String get savedToCookbook => 'Enregistrée';

  @override
  String get ingredientsTitle => 'Ingrédients';

  @override
  String get preparationTitle => 'Préparation';

  @override
  String get planHowTitle => 'Comment veux-tu planifier ?';

  @override
  String get planManualTitle => 'Manuel';

  @override
  String get planManualDesc =>
      'Tu ajoutes toi-même les recettes à chaque repas.';

  @override
  String get planAutoTitle => 'Automatique';

  @override
  String get planAutoDesc =>
      'Définis des filtres et un plafond calorique quotidien : la semaine se remplit avec tes recettes.';

  @override
  String get planConsultTitle => 'Depuis la consultation nutritionnelle';

  @override
  String get planConsultDesc =>
      'Importe le plan de ton nutritionniste et associe-le aux recettes.';

  @override
  String get planComingSoon => 'Bientôt';

  @override
  String get planMaxKcal => 'Calories max par jour';

  @override
  String get planNoLimit => 'Sans limite';

  @override
  String get planIncludeSnack => 'Inclure une collation';

  @override
  String get planGenerateBtn => 'Générer le plan de la semaine';

  @override
  String planResultAll(Object n) {
    return '$n repas planifiés ✓';
  }

  @override
  String planResultPartial(Object filled, Object missing) {
    return '$filled repas planifiés, $missing vides : pas assez de recettes adaptées avec des données nutritionnelles.';
  }

  @override
  String get pantryScan => 'Scanner des aliments';

  @override
  String get pantryScanCamera => 'Prendre une photo';

  @override
  String get pantryScanGallery => 'Choisir dans la galerie';

  @override
  String get pantryScanning => 'Reconnaissance des aliments…';

  @override
  String get pantryScanFound => 'Aliments reconnus';

  @override
  String get pantryScanNone => 'Aucun aliment reconnu sur la photo.';

  @override
  String pantryScanAdded(Object n) {
    return '$n aliments ajoutés au garde-manger';
  }

  @override
  String get planIncludeDessert => 'Ajouter un dessert au déjeuner/dîner';

  @override
  String get pantryScanBarcode => 'Scanner un code-barres';

  @override
  String barcodeNotFound(Object code) {
    return 'Produit introuvable pour le code $code.';
  }

  @override
  String get planReplace => 'Remplacer';

  @override
  String get planReplaceTitle => 'Choisis le remplacement';
}

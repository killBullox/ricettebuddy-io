// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navRecipes => 'Ricette';

  @override
  String get navImport => 'Importa';

  @override
  String get navChef => 'Chef';

  @override
  String get navPlan => 'Piano';

  @override
  String get navShopping => 'Spesa';

  @override
  String get navConsulenza => 'Consulenza';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get pantryTitle => 'Dispensa';

  @override
  String get mealPlanTitle => 'Piano pasti';

  @override
  String get importTitle => 'Importa';

  @override
  String get importFromWebOrSocial => 'Da sito web o social';

  @override
  String get pasteLinkHint => 'Incolla un link…';

  @override
  String get importFromLink => 'Importa da link';

  @override
  String get fromCamera => 'Da fotocamera';

  @override
  String get scanRecipeSoon => 'Scansiona ricetta (in arrivo)';

  @override
  String get shareHint =>
      'Potrai importare dai social col tasto Condividi (TikTok, Instagram, …).';

  @override
  String get preparingRecipe => 'Sto preparando la tua ricetta…';

  @override
  String get recipeImported => 'Ricetta importata!';

  @override
  String get alreadyInLibrary => 'Questa ricetta è già nella tua libreria';

  @override
  String importFailed(Object error) {
    return 'Import non riuscito: $error';
  }

  @override
  String get searchRecipes => 'Cerca ricette';

  @override
  String get noRecipes => 'Nessuna ricetta';

  @override
  String get emptyRecipesBody =>
      'Importa la tua prima ricetta dalla scheda Importa.';

  @override
  String get tabRecipe => 'RICETTA';

  @override
  String get tabShopping => 'LISTA SPESA';

  @override
  String get servings => 'Porzioni';

  @override
  String get veganizedRecipe => 'Ricetta veganizzata';

  @override
  String get actionFavorite => 'Preferiti';

  @override
  String get actionShopping => 'Spesa';

  @override
  String get actionDelete => 'Elimina';

  @override
  String addedToShopping(Object title) {
    return '\"$title\" aggiunta alla lista della spesa';
  }

  @override
  String recipeDeleted(Object title) {
    return '\"$title\" eliminata';
  }

  @override
  String get pantryEmpty =>
      'Dispensa vuota.\nAggiungi ciò che hai in casa per ricevere idee.';

  @override
  String get add => 'Aggiungi';

  @override
  String get addToPantry => 'Aggiungi alla dispensa';

  @override
  String get edit => 'Modifica';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get consulenzaTitle => 'Consulenza';

  @override
  String get bookConsultation => 'Prenota una consulenza';

  @override
  String get generateShopping => 'Genera spesa';

  @override
  String get chooseRecipe => 'Scegli una ricetta';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get systemLanguage => 'Sistema';

  @override
  String get phaseAnalyzing => 'Sto analizzando la ricetta…';

  @override
  String get phaseVeganizing => 'Sto veganizzando gli ingredienti…';

  @override
  String get phaseInstructions =>
      'Sto scrivendo le istruzioni di preparazione…';

  @override
  String get phaseNutrition => 'Sto calcolando i valori nutrizionali…';

  @override
  String get phaseCo2 => 'Sto stimando l\'impatto ambientale (CO₂)…';

  @override
  String get phaseReading => 'Sto leggendo la ricetta…';

  @override
  String get phaseProcessing => 'Sto preparando la tua ricetta…';

  @override
  String get navMore => 'Altro';

  @override
  String get badgeVeganized => 'Veganized';

  @override
  String get labelVegan => 'Vegano';

  @override
  String get labelHighProtein => 'PROTEICO';

  @override
  String get labelLowCarb => 'LOW CARB';

  @override
  String get labelLight => 'LEGGERA';

  @override
  String get labelHighFiber => 'RICCA DI FIBRE';

  @override
  String get filtersTitle => 'Filtri';

  @override
  String get filterNoAllergens => 'Senza allergeni';

  @override
  String get allergenGluten => 'Senza glutine';

  @override
  String get allergenSoy => 'Senza soia';

  @override
  String get allergenNuts => 'Senza frutta a guscio';

  @override
  String get allergenLactose => 'Senza lattosio';

  @override
  String get filterLabels => 'Etichette';

  @override
  String get filterMaxKcal => 'Calorie max (a porzione)';

  @override
  String get filterMinProtein => 'Proteine min (a porzione)';

  @override
  String filterMaxKcalChip(Object k) {
    return '≤ $k kcal';
  }

  @override
  String filterMinProteinChip(Object p) {
    return '≥ $p g';
  }

  @override
  String get filterReset => 'Azzera';

  @override
  String get filterApply => 'Applica';

  @override
  String co2Saved(Object kg) {
    return '$kg kg CO₂ risparmiati a porzione';
  }

  @override
  String co2SubVeganized(Object km) {
    return 'veganizzando questa ricetta — come $km km in meno in auto 🚗';
  }

  @override
  String co2SubChosen(Object km) {
    return 'scegliendo questa versione vegetale — come $km km in meno in auto 🚗';
  }
}

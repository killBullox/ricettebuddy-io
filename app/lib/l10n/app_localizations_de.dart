// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navRecipes => 'Rezepte';

  @override
  String get navImport => 'Import';

  @override
  String get navChef => 'Chef';

  @override
  String get navPlan => 'Plan';

  @override
  String get navShopping => 'Einkauf';

  @override
  String get navConsulenza => 'Beratung';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get pantryTitle => 'Vorrat';

  @override
  String get mealPlanTitle => 'Essensplan';

  @override
  String get importTitle => 'Import';

  @override
  String get importFromWebOrSocial => 'Von Website oder Social';

  @override
  String get pasteLinkHint => 'Link einfügen…';

  @override
  String get importFromLink => 'Aus Link importieren';

  @override
  String get fromCamera => 'Von der Kamera';

  @override
  String get scanRecipeSoon => 'Rezept scannen (bald)';

  @override
  String get shareHint =>
      'Du kannst auch über die Teilen-Funktion aus sozialen Apps importieren (TikTok, Instagram, …).';

  @override
  String get preparingRecipe => 'Dein Rezept wird vorbereitet…';

  @override
  String get recipeImported => 'Rezept importiert!';

  @override
  String get alreadyInLibrary =>
      'Dieses Rezept ist bereits in deiner Bibliothek';

  @override
  String importFailed(Object error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get searchRecipes => 'Rezepte suchen';

  @override
  String get noRecipes => 'Keine Rezepte';

  @override
  String get emptyRecipesBody =>
      'Importiere dein erstes Rezept über den Tab Import.';

  @override
  String get tabRecipe => 'REZEPT';

  @override
  String get tabShopping => 'EINKAUFSLISTE';

  @override
  String get servings => 'Portionen';

  @override
  String get veganizedRecipe => 'Veganisiertes Rezept';

  @override
  String get actionFavorite => 'Favoriten';

  @override
  String get actionShopping => 'Einkauf';

  @override
  String get actionDelete => 'Löschen';

  @override
  String addedToShopping(Object title) {
    return '\"$title\" zur Einkaufsliste hinzugefügt';
  }

  @override
  String recipeDeleted(Object title) {
    return '\"$title\" gelöscht';
  }

  @override
  String get pantryEmpty =>
      'Vorrat ist leer.\nFüge hinzu, was du zu Hause hast, um Ideen zu erhalten.';

  @override
  String get add => 'Hinzufügen';

  @override
  String get addToPantry => 'Zum Vorrat hinzufügen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get consulenzaTitle => 'Beratung';

  @override
  String get bookConsultation => 'Beratung buchen';

  @override
  String get generateShopping => 'Einkaufsliste erstellen';

  @override
  String get chooseRecipe => 'Rezept auswählen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'System';
}

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

  @override
  String get phaseAnalyzing => 'Rezept wird analysiert…';

  @override
  String get phaseVeganizing => 'Zutaten werden veganisiert…';

  @override
  String get phaseInstructions => 'Zubereitungsschritte werden erstellt…';

  @override
  String get phaseNutrition => 'Nährwerte werden berechnet…';

  @override
  String get phaseCo2 => 'Umweltbilanz wird geschätzt (CO₂)…';

  @override
  String get phaseReading => 'Rezept wird gelesen…';

  @override
  String get phaseProcessing => 'Dein Rezept wird vorbereitet…';

  @override
  String get pasteRecipeTitle => 'Rezept einfügen';

  @override
  String get pasteRecipeBody =>
      'Facebook lässt uns dieses Reel ohne Login nicht lesen. Füge den Rezepttext (Zutaten und Schritte) ein — wir veganisieren und ordnen ihn für dich.';

  @override
  String get pasteRecipeHint => 'Zutaten und Schritte hier einfügen…';

  @override
  String get navMore => 'Mehr';

  @override
  String get badgeVeganized => 'Veganisiert';

  @override
  String get labelVegan => 'Vegan';

  @override
  String get labelHighProtein => 'PROTEINREICH';

  @override
  String get labelLowCarb => 'LOW CARB';

  @override
  String get labelLight => 'LEICHT';

  @override
  String get labelHighFiber => 'BALLASTSTOFFE';

  @override
  String get filtersTitle => 'Filter';

  @override
  String get filterNoAllergens => 'Ohne Allergene';

  @override
  String get allergenGluten => 'Glutenfrei';

  @override
  String get allergenSoy => 'Ohne Soja';

  @override
  String get allergenNuts => 'Ohne Nüsse';

  @override
  String get allergenLactose => 'Laktosefrei';

  @override
  String get filterLabels => 'Labels';

  @override
  String get filterMaxKcal => 'Max. Kalorien (pro Portion)';

  @override
  String get filterMinProtein => 'Min. Protein (pro Portion)';

  @override
  String filterMaxKcalChip(Object k) {
    return '≤ $k kcal';
  }

  @override
  String filterMinProteinChip(Object p) {
    return '≥ $p g';
  }

  @override
  String get filterReset => 'Zurücksetzen';

  @override
  String get filterApply => 'Anwenden';

  @override
  String co2Saved(Object kg) {
    return '$kg kg CO₂ pro Portion gespart';
  }

  @override
  String co2SubVeganized(Object km) {
    return 'durch Veganisieren dieses Rezepts — wie $km km weniger mit dem Auto 🚗';
  }

  @override
  String co2SubChosen(Object km) {
    return 'durch diese pflanzliche Version — wie $km km weniger mit dem Auto 🚗';
  }

  @override
  String get chefIdeasTitle => 'KI-Chef';

  @override
  String get chefThinking => 'Der Chef kreiert deine Rezepte…';

  @override
  String get chefPrefFast => 'Schnell (≤30 Min.)';

  @override
  String get chefGenerate => 'Rezepte generieren';

  @override
  String get chefHint =>
      'Wähle deine Präferenzen und tippe auf Generieren: Der Chef erfindet Rezepte aus deinem Vorrat.';

  @override
  String get saveToCookbook => 'Im Kochbuch speichern';

  @override
  String get savedToCookbook => 'Gespeichert';

  @override
  String get ingredientsTitle => 'Zutaten';

  @override
  String get preparationTitle => 'Zubereitung';

  @override
  String get planHowTitle => 'Wie möchtest du planen?';

  @override
  String get planManualTitle => 'Manuell';

  @override
  String get planManualDesc =>
      'Du fügst die Rezepte selbst zu jeder Mahlzeit hinzu.';

  @override
  String get planAutoTitle => 'Automatisch';

  @override
  String get planAutoDesc =>
      'Filter und Tageskalorienlimit festlegen: Die Woche füllt sich mit deinen Rezepten.';

  @override
  String get planConsultTitle => 'Aus der Ernährungsberatung';

  @override
  String get planConsultDesc =>
      'Importiere den Plan deiner Ernährungsberatung und kombiniere ihn mit Rezepten.';

  @override
  String get planComingSoon => 'Bald verfügbar';

  @override
  String get planMaxKcal => 'Max. Kalorien pro Tag';

  @override
  String get planNoLimit => 'Kein Limit';

  @override
  String get planIncludeSnack => 'Snack einplanen';

  @override
  String get planGenerateBtn => 'Wochenplan generieren';

  @override
  String planResultAll(Object n) {
    return '$n Mahlzeiten geplant ✓';
  }

  @override
  String planResultPartial(Object filled, Object missing) {
    return '$filled Mahlzeiten geplant, $missing leer: nicht genug passende Rezepte mit Nährwertdaten.';
  }

  @override
  String get pantryScan => 'Lebensmittel scannen';

  @override
  String get pantryScanCamera => 'Foto aufnehmen';

  @override
  String get pantryScanGallery => 'Aus der Galerie wählen';

  @override
  String get pantryScanning => 'Lebensmittel werden erkannt…';

  @override
  String get pantryScanFound => 'Erkannte Lebensmittel';

  @override
  String get pantryScanNone => 'Keine Lebensmittel auf dem Foto erkannt.';

  @override
  String pantryScanAdded(Object n) {
    return '$n Lebensmittel zum Vorrat hinzugefügt';
  }

  @override
  String get planIncludeDessert => 'Dessert zu Mittag-/Abendessen hinzufügen';

  @override
  String get pantryScanBarcode => 'Barcode scannen';

  @override
  String barcodeNotFound(Object code) {
    return 'Kein Produkt für Barcode $code gefunden.';
  }
}

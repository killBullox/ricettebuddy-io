import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @navRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navRecipes;

  /// No description provided for @navImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get navImport;

  /// No description provided for @navChef.
  ///
  /// In en, this message translates to:
  /// **'Chef'**
  String get navChef;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navShopping;

  /// No description provided for @navConsulenza.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get navConsulenza;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @pantryTitle.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get pantryTitle;

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get mealPlanTitle;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importFromWebOrSocial.
  ///
  /// In en, this message translates to:
  /// **'From website or social'**
  String get importFromWebOrSocial;

  /// No description provided for @pasteLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link…'**
  String get pasteLinkHint;

  /// No description provided for @importFromLink.
  ///
  /// In en, this message translates to:
  /// **'Import from link'**
  String get importFromLink;

  /// No description provided for @fromCamera.
  ///
  /// In en, this message translates to:
  /// **'From camera'**
  String get fromCamera;

  /// No description provided for @scanRecipeSoon.
  ///
  /// In en, this message translates to:
  /// **'Scan recipe (coming soon)'**
  String get scanRecipeSoon;

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'You can also import from social apps with the Share button (TikTok, Instagram, …).'**
  String get shareHint;

  /// No description provided for @preparingRecipe.
  ///
  /// In en, this message translates to:
  /// **'Preparing your recipe…'**
  String get preparingRecipe;

  /// No description provided for @recipeImported.
  ///
  /// In en, this message translates to:
  /// **'Recipe imported!'**
  String get recipeImported;

  /// No description provided for @alreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'This recipe is already in your library'**
  String get alreadyInLibrary;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @searchRecipes.
  ///
  /// In en, this message translates to:
  /// **'Search recipes'**
  String get searchRecipes;

  /// No description provided for @noRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes'**
  String get noRecipes;

  /// No description provided for @emptyRecipesBody.
  ///
  /// In en, this message translates to:
  /// **'Import your first recipe from the Import tab.'**
  String get emptyRecipesBody;

  /// No description provided for @tabRecipe.
  ///
  /// In en, this message translates to:
  /// **'RECIPE'**
  String get tabRecipe;

  /// No description provided for @tabShopping.
  ///
  /// In en, this message translates to:
  /// **'SHOPPING LIST'**
  String get tabShopping;

  /// No description provided for @servings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get servings;

  /// No description provided for @veganizedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Veganized recipe'**
  String get veganizedRecipe;

  /// No description provided for @actionFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get actionFavorite;

  /// No description provided for @actionShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get actionShopping;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @addedToShopping.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" added to the shopping list'**
  String addedToShopping(Object title);

  /// No description provided for @recipeDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" deleted'**
  String recipeDeleted(Object title);

  /// No description provided for @pantryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pantry is empty.\nAdd what you have at home to get ideas.'**
  String get pantryEmpty;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addToPantry.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get addToPantry;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @consulenzaTitle.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consulenzaTitle;

  /// No description provided for @bookConsultation.
  ///
  /// In en, this message translates to:
  /// **'Book a consultation'**
  String get bookConsultation;

  /// No description provided for @generateShopping.
  ///
  /// In en, this message translates to:
  /// **'Generate shopping list'**
  String get generateShopping;

  /// No description provided for @chooseRecipe.
  ///
  /// In en, this message translates to:
  /// **'Choose a recipe'**
  String get chooseRecipe;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @phaseAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the recipe…'**
  String get phaseAnalyzing;

  /// No description provided for @phaseVeganizing.
  ///
  /// In en, this message translates to:
  /// **'Veganizing the ingredients…'**
  String get phaseVeganizing;

  /// No description provided for @phaseInstructions.
  ///
  /// In en, this message translates to:
  /// **'Writing the cooking steps…'**
  String get phaseInstructions;

  /// No description provided for @phaseNutrition.
  ///
  /// In en, this message translates to:
  /// **'Calculating nutrition facts…'**
  String get phaseNutrition;

  /// No description provided for @phaseCo2.
  ///
  /// In en, this message translates to:
  /// **'Estimating the environmental impact (CO₂)…'**
  String get phaseCo2;

  /// No description provided for @phaseReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the recipe…'**
  String get phaseReading;

  /// No description provided for @phaseProcessing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your recipe…'**
  String get phaseProcessing;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @badgeVeganized.
  ///
  /// In en, this message translates to:
  /// **'Veganized'**
  String get badgeVeganized;

  /// No description provided for @labelVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get labelVegan;

  /// No description provided for @labelHighProtein.
  ///
  /// In en, this message translates to:
  /// **'HIGH PROTEIN'**
  String get labelHighProtein;

  /// No description provided for @labelLowCarb.
  ///
  /// In en, this message translates to:
  /// **'LOW CARB'**
  String get labelLowCarb;

  /// No description provided for @labelLight.
  ///
  /// In en, this message translates to:
  /// **'LIGHT'**
  String get labelLight;

  /// No description provided for @labelHighFiber.
  ///
  /// In en, this message translates to:
  /// **'HIGH FIBER'**
  String get labelHighFiber;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @filterNoAllergens.
  ///
  /// In en, this message translates to:
  /// **'Without allergens'**
  String get filterNoAllergens;

  /// No description provided for @allergenGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get allergenGluten;

  /// No description provided for @allergenSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy-free'**
  String get allergenSoy;

  /// No description provided for @allergenNuts.
  ///
  /// In en, this message translates to:
  /// **'Nut-free'**
  String get allergenNuts;

  /// No description provided for @allergenLactose.
  ///
  /// In en, this message translates to:
  /// **'Lactose-free'**
  String get allergenLactose;

  /// No description provided for @filterLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get filterLabels;

  /// No description provided for @filterMaxKcal.
  ///
  /// In en, this message translates to:
  /// **'Max calories (per serving)'**
  String get filterMaxKcal;

  /// No description provided for @filterMinProtein.
  ///
  /// In en, this message translates to:
  /// **'Min protein (per serving)'**
  String get filterMinProtein;

  /// No description provided for @filterMaxKcalChip.
  ///
  /// In en, this message translates to:
  /// **'≤ {k} kcal'**
  String filterMaxKcalChip(Object k);

  /// No description provided for @filterMinProteinChip.
  ///
  /// In en, this message translates to:
  /// **'≥ {p} g'**
  String filterMinProteinChip(Object p);

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @co2Saved.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg CO₂ saved per serving'**
  String co2Saved(Object kg);

  /// No description provided for @co2SubVeganized.
  ///
  /// In en, this message translates to:
  /// **'by veganizing this recipe — like {km} km less by car 🚗'**
  String co2SubVeganized(Object km);

  /// No description provided for @co2SubChosen.
  ///
  /// In en, this message translates to:
  /// **'by choosing this plant-based version — like {km} km less by car 🚗'**
  String co2SubChosen(Object km);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

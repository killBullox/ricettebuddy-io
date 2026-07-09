// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navRecipes => 'Recetas';

  @override
  String get navImport => 'Importar';

  @override
  String get navChef => 'Chef';

  @override
  String get navPlan => 'Plan';

  @override
  String get navShopping => 'Compra';

  @override
  String get navConsulenza => 'Consulta';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get pantryTitle => 'Despensa';

  @override
  String get mealPlanTitle => 'Plan de comidas';

  @override
  String get importTitle => 'Importar';

  @override
  String get importFromWebOrSocial => 'Desde web o redes sociales';

  @override
  String get pasteLinkHint => 'Pega un enlace…';

  @override
  String get importFromLink => 'Importar desde enlace';

  @override
  String get fromCamera => 'Desde la cámara';

  @override
  String get scanRecipeSoon => 'Escanear receta (próximamente)';

  @override
  String get shareHint =>
      'También podrás importar desde redes sociales con el botón Compartir (TikTok, Instagram, …).';

  @override
  String get preparingRecipe => 'Preparando tu receta…';

  @override
  String get recipeImported => '¡Receta importada!';

  @override
  String get alreadyInLibrary => 'Esta receta ya está en tu biblioteca';

  @override
  String importFailed(Object error) {
    return 'Error al importar: $error';
  }

  @override
  String get searchRecipes => 'Buscar recetas';

  @override
  String get noRecipes => 'Sin recetas';

  @override
  String get emptyRecipesBody =>
      'Importa tu primera receta desde la pestaña Importar.';

  @override
  String get tabRecipe => 'RECETA';

  @override
  String get tabShopping => 'LISTA DE LA COMPRA';

  @override
  String get servings => 'Raciones';

  @override
  String get veganizedRecipe => 'Receta veganizada';

  @override
  String get actionFavorite => 'Favoritos';

  @override
  String get actionShopping => 'Compra';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String addedToShopping(Object title) {
    return '\"$title\" añadida a la lista de la compra';
  }

  @override
  String recipeDeleted(Object title) {
    return '\"$title\" eliminada';
  }

  @override
  String get pantryEmpty =>
      'Despensa vacía.\nAñade lo que tienes en casa para recibir ideas.';

  @override
  String get add => 'Añadir';

  @override
  String get addToPantry => 'Añadir a la despensa';

  @override
  String get edit => 'Editar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get consulenzaTitle => 'Consulta';

  @override
  String get bookConsultation => 'Reservar una consulta';

  @override
  String get generateShopping => 'Generar lista de la compra';

  @override
  String get chooseRecipe => 'Elige una receta';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Sistema';

  @override
  String get phaseAnalyzing => 'Analizando la receta…';

  @override
  String get phaseVeganizing => 'Veganizando los ingredientes…';

  @override
  String get phaseInstructions => 'Escribiendo las instrucciones…';

  @override
  String get phaseNutrition => 'Calculando los valores nutricionales…';

  @override
  String get phaseCo2 => 'Estimando el impacto ambiental (CO₂)…';

  @override
  String get navMore => 'Más';

  @override
  String get badgeVeganized => 'Veganizada';

  @override
  String get labelVegan => 'Vegana';

  @override
  String get labelHighProtein => 'PROTEÍNAS';

  @override
  String get labelLowCarb => 'LOW CARB';

  @override
  String get labelLight => 'LIGERA';

  @override
  String get labelHighFiber => 'RICA EN FIBRA';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get filterNoAllergens => 'Sin alérgenos';

  @override
  String get allergenGluten => 'Sin gluten';

  @override
  String get allergenSoy => 'Sin soja';

  @override
  String get allergenNuts => 'Sin frutos secos';

  @override
  String get allergenLactose => 'Sin lactosa';

  @override
  String get filterLabels => 'Etiquetas';

  @override
  String get filterMaxKcal => 'Calorías máx. (por ración)';

  @override
  String get filterMinProtein => 'Proteínas mín. (por ración)';

  @override
  String filterMaxKcalChip(Object k) {
    return '≤ $k kcal';
  }

  @override
  String filterMinProteinChip(Object p) {
    return '≥ $p g';
  }

  @override
  String get filterReset => 'Restablecer';

  @override
  String get filterApply => 'Aplicar';

  @override
  String co2Saved(Object kg) {
    return '$kg kg de CO₂ ahorrados por ración';
  }

  @override
  String co2SubVeganized(Object km) {
    return 'al veganizar esta receta — como $km km menos en coche 🚗';
  }

  @override
  String co2SubChosen(Object km) {
    return 'al elegir esta versión vegetal — como $km km menos en coche 🚗';
  }
}

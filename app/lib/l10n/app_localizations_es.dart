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
  String get phaseReading => 'Leyendo la receta…';

  @override
  String get phaseProcessing => 'Preparando tu receta…';

  @override
  String get pasteRecipeTitle => 'Pega la receta';

  @override
  String get pasteRecipeBody =>
      'Facebook no nos deja leer este reel sin iniciar sesión. Pega el texto de la receta (ingredientes y pasos) y la veganizamos y organizamos por ti.';

  @override
  String get pasteRecipeHint => 'Pega aquí ingredientes y pasos…';

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

  @override
  String get chefIdeasTitle => 'Chef IA';

  @override
  String get chefThinking => 'El Chef está creando tus recetas…';

  @override
  String get chefPrefFast => 'Rápida (≤30 min)';

  @override
  String get chefGenerate => 'Generar recetas';

  @override
  String get chefHint =>
      'Elige tus preferencias y pulsa Generar: el Chef inventará recetas con lo que tienes en la despensa.';

  @override
  String get saveToCookbook => 'Guardar en el recetario';

  @override
  String get savedToCookbook => 'Guardada';

  @override
  String get ingredientsTitle => 'Ingredientes';

  @override
  String get preparationTitle => 'Preparación';

  @override
  String get planHowTitle => '¿Cómo quieres planificar?';

  @override
  String get planManualTitle => 'Manual';

  @override
  String get planManualDesc => 'Añades tú las recetas a cada comida.';

  @override
  String get planAutoTitle => 'Automática';

  @override
  String get planAutoDesc =>
      'Configura filtros y un tope calórico diario: la semana se llena con tus recetas.';

  @override
  String get planConsultTitle => 'Desde consulta nutricional';

  @override
  String get planConsultDesc =>
      'Importa el plan de tu nutricionista y combínalo con recetas.';

  @override
  String get planComingSoon => 'Próximamente';

  @override
  String get planMaxKcal => 'Calorías máximas al día';

  @override
  String get planNoLimit => 'Sin límite';

  @override
  String get planIncludeSnack => 'Incluir tentempié';

  @override
  String get planGenerateBtn => 'Generar plan semanal';

  @override
  String planResultAll(Object n) {
    return '$n comidas planificadas ✓';
  }

  @override
  String planResultPartial(Object filled, Object missing) {
    return '$filled comidas planificadas, $missing vacías: no hay suficientes recetas adecuadas con datos nutricionales.';
  }

  @override
  String get pantryScan => 'Escanear alimentos';

  @override
  String get pantryScanCamera => 'Hacer una foto';

  @override
  String get pantryScanGallery => 'Elegir de la galería';

  @override
  String get pantryScanning => 'Reconociendo los alimentos…';

  @override
  String get pantryScanFound => 'Alimentos reconocidos';

  @override
  String get pantryScanNone => 'No se reconoció ningún alimento en la foto.';

  @override
  String pantryScanAdded(Object n) {
    return '$n alimentos añadidos a la despensa';
  }

  @override
  String get planIncludeDessert => 'Añadir postre a comida/cena';

  @override
  String get pantryScanBarcode => 'Escanear código de barras';

  @override
  String barcodeNotFound(Object code) {
    return 'Producto no encontrado para el código $code.';
  }

  @override
  String get planReplace => 'Sustituir';

  @override
  String get planReplaceTitle => 'Elige el sustituto';

  @override
  String get consultFirstTitle => 'Primera consulta';

  @override
  String get consultFirstDesc =>
      'Evaluación inicial: hábitos, objetivos y plan personalizado.';

  @override
  String get consultFollowTitle => 'Seguimiento';

  @override
  String get consultFollowDesc => 'Control del progreso y ajustes del plan.';
}

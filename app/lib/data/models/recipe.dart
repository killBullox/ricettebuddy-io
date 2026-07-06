import 'enums.dart';
import 'ingredient.dart';
import 'recipe_step.dart';

class Recipe {
  final String? id;
  final String title;
  final String? imageUrl;
  final String? sourceUrl;
  final RecipeSource source;
  final String? originalLanguage;
  final int? prepMinutes;
  final int? cookMinutes;
  final int servings;
  final List<String> tags;
  /// Regimi soddisfatti dalla ricetta (nomi di Diet), es. ['vegan','glutenFree'].
  final List<String> dietTags;
  final bool isFavorite;

  // Segnali di gusto per lo "Chef creativo".
  final int cookedCount;
  final DateTime? lastCookedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Video associato: poster, id e URL MP4 diretto (riproducibile inline).
  final String? videoUrl;
  final String? videoId;
  final String? videoMp4;
  final List<String> stepGallery;

  // Arricchimento AI (veganizzazione + nutrizione + classificazione).
  final Map<String, dynamic>? nutrition; // per porzione: kcal, protein_g, ...
  final List<Map<String, dynamic>> substitutions; // {original, vegan, note}
  final bool? wasVegan; // false se la ricetta è stata veganizzata
  final String? category;
  final String? cuisine;
  final String? difficulty;
  final List<String> allergens;

  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;

  const Recipe({
    this.id,
    required this.title,
    this.imageUrl,
    this.sourceUrl,
    this.source = RecipeSource.manual,
    this.originalLanguage,
    this.prepMinutes,
    this.cookMinutes,
    this.servings = 2,
    this.tags = const [],
    this.dietTags = const [],
    this.isFavorite = false,
    this.cookedCount = 0,
    this.lastCookedAt,
    this.createdAt,
    this.updatedAt,
    this.videoUrl,
    this.videoId,
    this.videoMp4,
    this.stepGallery = const [],
    this.nutrition,
    this.substitutions = const [],
    this.wasVegan,
    this.category,
    this.cuisine,
    this.difficulty,
    this.allergens = const [],
    this.ingredients = const [],
    this.steps = const [],
  });

  int? get totalMinutes {
    final t = (prepMinutes ?? 0) + (cookMinutes ?? 0);
    return t > 0 ? t : null;
  }

  factory Recipe.fromMap(
    Map<String, dynamic> m, {
    List<Ingredient> ingredients = const [],
    List<RecipeStep> steps = const [],
  }) {
    // Se il map contiene già ingredienti/passi inline (formato API), usali;
    // altrimenti usa quelli passati (formato Supabase con query separate).
    final ing = m['ingredients'] is List
        ? (m['ingredients'] as List)
            .map((e) => Ingredient.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : ingredients;
    final st = m['steps'] is List
        ? (m['steps'] as List)
            .map((e) => RecipeStep.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : steps;
    return Recipe(
      id: m['id']?.toString(),
      title: m['title'] as String? ?? '',
      imageUrl: m['image_url'] as String?,
      sourceUrl: m['source_url'] as String?,
      source: RecipeSource.fromString(m['source_type'] as String?),
      originalLanguage: m['original_language'] as String?,
      prepMinutes: m['prep_minutes'] as int?,
      cookMinutes: m['cook_minutes'] as int?,
      servings: (m['servings'] as int?) ?? 2,
      tags: (m['tags'] as List?)?.cast<String>() ?? const [],
      dietTags: (m['diet_tags'] as List?)?.cast<String>() ?? const [],
      isFavorite: (m['is_favorite'] as bool?) ?? false,
      cookedCount: (m['cooked_count'] as int?) ?? 0,
      lastCookedAt: _date(m['last_cooked_at']),
      createdAt: _date(m['created_at']),
      updatedAt: _date(m['updated_at']),
      videoUrl: m['video_url'] as String?,
      videoId: m['video_id'] as String?,
      videoMp4: m['video_mp4'] as String?,
      stepGallery: (m['step_gallery'] as List?)?.cast<String>() ?? const [],
      nutrition: m['nutrition'] == null
          ? null
          : Map<String, dynamic>.from(m['nutrition'] as Map),
      substitutions: (m['substitutions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      wasVegan: m['was_vegan'] as bool?,
      category: m['category'] as String?,
      cuisine: m['cuisine'] as String?,
      difficulty: m['difficulty'] as String?,
      allergens: (m['allergens'] as List?)?.cast<String>() ?? const [],
      ingredients: ing,
      steps: st,
    );
  }

  /// Colonne della sola riga `recipes` (senza relazioni).
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'image_url': imageUrl,
        'source_url': sourceUrl,
        'source_type': source.name,
        'original_language': originalLanguage,
        'prep_minutes': prepMinutes,
        'cook_minutes': cookMinutes,
        'servings': servings,
        'tags': tags,
        'diet_tags': dietTags,
        'is_favorite': isFavorite,
        'cooked_count': cookedCount,
        'video_url': videoUrl,
        'video_id': videoId,
        'video_mp4': videoMp4,
        'step_gallery': stepGallery,
      };

  /// Map completa per l'API locale (include relazioni, galleria e video).
  Map<String, dynamic> toApiMap() => {
        ...toMap(),
        'ingredients': [for (final i in ingredients) i.toMap()],
        'steps': [for (final s in steps) s.toMap()],
        'step_gallery': stepGallery,
        'video_url': videoUrl,
        'video_id': videoId,
        'video_mp4': videoMp4,
      };

  Recipe copyWith({
    String? title,
    bool? isFavorite,
    int? servings,
    int? cookedCount,
    int? prepMinutes,
    int? cookMinutes,
    List<String>? tags,
    List<String>? dietTags,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
  }) =>
      Recipe(
        id: id,
        title: title ?? this.title,
        imageUrl: imageUrl,
        sourceUrl: sourceUrl,
        source: source,
        originalLanguage: originalLanguage,
        prepMinutes: prepMinutes ?? this.prepMinutes,
        cookMinutes: cookMinutes ?? this.cookMinutes,
        servings: servings ?? this.servings,
        tags: tags ?? this.tags,
        dietTags: dietTags ?? this.dietTags,
        isFavorite: isFavorite ?? this.isFavorite,
        cookedCount: cookedCount ?? this.cookedCount,
        lastCookedAt: lastCookedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        videoUrl: videoUrl,
        videoId: videoId,
        videoMp4: videoMp4,
        stepGallery: stepGallery,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
      );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

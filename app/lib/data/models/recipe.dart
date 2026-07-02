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
  final bool isFavorite;

  // Segnali di gusto per lo "Chef creativo".
  final int cookedCount;
  final DateTime? lastCookedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.isFavorite = false,
    this.cookedCount = 0,
    this.lastCookedAt,
    this.createdAt,
    this.updatedAt,
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
  }) =>
      Recipe(
        id: m['id'] as String?,
        title: m['title'] as String? ?? '',
        imageUrl: m['image_url'] as String?,
        sourceUrl: m['source_url'] as String?,
        source: RecipeSource.fromString(m['source_type'] as String?),
        originalLanguage: m['original_language'] as String?,
        prepMinutes: m['prep_minutes'] as int?,
        cookMinutes: m['cook_minutes'] as int?,
        servings: (m['servings'] as int?) ?? 2,
        tags: (m['tags'] as List?)?.cast<String>() ?? const [],
        isFavorite: (m['is_favorite'] as bool?) ?? false,
        cookedCount: (m['cooked_count'] as int?) ?? 0,
        lastCookedAt: _date(m['last_cooked_at']),
        createdAt: _date(m['created_at']),
        updatedAt: _date(m['updated_at']),
        ingredients: ingredients,
        steps: steps,
      );

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
        'is_favorite': isFavorite,
        'cooked_count': cookedCount,
      };

  Recipe copyWith({
    String? title,
    bool? isFavorite,
    int? servings,
    int? cookedCount,
  }) =>
      Recipe(
        id: id,
        title: title ?? this.title,
        imageUrl: imageUrl,
        sourceUrl: sourceUrl,
        source: source,
        originalLanguage: originalLanguage,
        prepMinutes: prepMinutes,
        cookMinutes: cookMinutes,
        servings: servings ?? this.servings,
        tags: tags,
        isFavorite: isFavorite ?? this.isFavorite,
        cookedCount: cookedCount ?? this.cookedCount,
        lastCookedAt: lastCookedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        ingredients: ingredients,
        steps: steps,
      );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

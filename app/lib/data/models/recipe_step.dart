/// Passaggio di preparazione. (Chiamato `RecipeStep` per non collidere con
/// eventuali `Step` di Flutter/Material.)
class RecipeStep {
  final String? id;
  final String? recipeId;
  final int position;
  final String text;
  final String? imageUrl; // foto del passaggio (se disponibile)

  const RecipeStep({
    this.id,
    this.recipeId,
    required this.position,
    required this.text,
    this.imageUrl,
  });

  factory RecipeStep.fromMap(Map<String, dynamic> m) => RecipeStep(
        id: m['id'] as String?,
        recipeId: m['recipe_id'] as String?,
        position: (m['position'] as int?) ?? 0,
        text: m['text'] as String? ?? '',
        imageUrl: (m['image'] ?? m['image_url']) as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (recipeId != null) 'recipe_id': recipeId,
        'position': position,
        'text': text,
        if (imageUrl != null) 'image': imageUrl,
      };
}

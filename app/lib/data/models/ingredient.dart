/// Ingrediente di una ricetta. `normalizedName`/`quantity`/`unit` sono
/// popolati dal parsing lato server e usati per aggregare la spesa e per il
/// match con la dispensa nello "Chef creativo".
class Ingredient {
  final String? id;
  final String? recipeId;
  final int position;
  final String rawText; // "200 g di farina 00"
  final double? quantity; // 200
  final String? unit; // "g"
  final String? normalizedName; // "farina"
  final String? aisleCategory; // corsia supermercato
  final String? img; // slug foto ingrediente (Spoonacular), es. "red-onion"

  const Ingredient({
    this.id,
    this.recipeId,
    this.position = 0,
    required this.rawText,
    this.quantity,
    this.unit,
    this.normalizedName,
    this.aisleCategory,
    this.img,
  });

  factory Ingredient.fromMap(Map<String, dynamic> m) => Ingredient(
        id: m['id'] as String?,
        recipeId: m['recipe_id'] as String?,
        position: (m['position'] as int?) ?? 0,
        rawText: m['raw_text'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble(),
        unit: m['unit'] as String?,
        normalizedName: m['normalized_name'] as String?,
        aisleCategory: m['aisle_category'] as String?,
        img: m['img'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (recipeId != null) 'recipe_id': recipeId,
        'position': position,
        'raw_text': rawText,
        'quantity': quantity,
        'unit': unit,
        'normalized_name': normalizedName,
        'aisle_category': aisleCategory,
        'img': img,
      };
}

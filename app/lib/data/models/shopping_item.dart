class ShoppingItem {
  final String? id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? aisleCategory;
  final bool isChecked;
  final String? sourceRecipeId;

  const ShoppingItem({
    this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.aisleCategory,
    this.isChecked = false,
    this.sourceRecipeId,
  });

  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
        id: m['id'] as String?,
        name: m['name'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble(),
        unit: m['unit'] as String?,
        aisleCategory: m['aisle_category'] as String?,
        isChecked: (m['is_checked'] as bool?) ?? false,
        sourceRecipeId: m['source_recipe_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'aisle_category': aisleCategory,
        'is_checked': isChecked,
        'source_recipe_id': sourceRecipeId,
      };
}

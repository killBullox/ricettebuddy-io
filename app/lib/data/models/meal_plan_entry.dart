import 'enums.dart';

class MealPlanEntry {
  final String? id;
  final DateTime date;
  final MealSlot slot;
  final int servings;
  final String? recipeId;
  final String? recipeTitle; // comodo per la UI (join lato query)

  const MealPlanEntry({
    this.id,
    required this.date,
    required this.slot,
    this.servings = 2,
    this.recipeId,
    this.recipeTitle,
  });

  factory MealPlanEntry.fromMap(Map<String, dynamic> m) => MealPlanEntry(
        id: m['id'] as String?,
        date: DateTime.parse(m['date'].toString()),
        slot: MealSlot.fromString(m['slot'] as String?),
        servings: (m['servings'] as int?) ?? 2,
        recipeId: m['recipe_id'] as String?,
        recipeTitle: m['recipes'] is Map
            ? (m['recipes']['title'] as String?)
            : m['recipe_title'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String().split('T').first,
        'slot': slot.name,
        'servings': servings,
        'recipe_id': recipeId,
      };
}

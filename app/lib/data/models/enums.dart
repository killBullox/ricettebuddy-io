/// Tipo di fonte da cui è stata importata la ricetta.
enum RecipeSource {
  manual,
  web,
  social,
  photo,
  generated; // creata dallo "Chef creativo"

  static RecipeSource fromString(String? value) =>
      RecipeSource.values.firstWhere(
        (s) => s.name == value,
        orElse: () => RecipeSource.manual,
      );
}

/// Slot del piano pasti giornaliero.
enum MealSlot {
  breakfast,
  lunch,
  snack,
  dinner;

  static MealSlot fromString(String? value) => MealSlot.values.firstWhere(
        (s) => s.name == value,
        orElse: () => MealSlot.dinner,
      );

  /// Etichetta localizzata (fallback italiano finché non colleghiamo le ARB).
  String get labelIt => switch (this) {
        MealSlot.breakfast => 'Colazione',
        MealSlot.lunch => 'Pranzo',
        MealSlot.snack => 'Spuntino',
        MealSlot.dinner => 'Cena',
      };
}

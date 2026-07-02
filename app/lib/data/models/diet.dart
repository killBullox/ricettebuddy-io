/// Regimi alimentari supportati per i filtri di import e la classificazione ricette.
enum Diet {
  vegan,
  vegetarian,
  glutenFree,
  lactoseFree,
  pescetarian;

  String get label => switch (this) {
        Diet.vegan => 'Vegano',
        Diet.vegetarian => 'Vegetariano',
        Diet.glutenFree => 'Senza glutine',
        Diet.lactoseFree => 'Senza lattosio',
        Diet.pescetarian => 'Pescetariano',
      };

  static Diet? fromName(String? name) {
    for (final d in Diet.values) {
      if (d.name == name) return d;
    }
    return null;
  }

  static Set<Diet> fromNames(Iterable<String> names) =>
      names.map(fromName).whereType<Diet>().toSet();

  static List<String> toNames(Iterable<Diet> diets) =>
      diets.map((d) => d.name).toList();
}

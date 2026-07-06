/// Restituisce un'emoji adatta a un ingrediente in base a parole chiave.
String ingredientEmoji(String raw) {
  final s = raw.toLowerCase();
  bool has(List<String> ks) => ks.any((k) => s.contains(k));

  if (has(['tofu', 'tempeh', 'seitan', 'soia'])) return '🧊';
  if (has(['pomodor', 'passata', 'concentrato di pom'])) return '🍅';
  if (has(['aglio'])) return '🧄';
  if (has(['cipoll', 'scalogno', 'porro'])) return '🧅';
  if (has(['carota'])) return '🥕';
  if (has(['patat'])) return '🥔';
  if (has(['zucchin', 'cetriol'])) return '🥒';
  if (has(['melanzan'])) return '🍆';
  if (has(['peperon'])) return '🫑';
  if (has(['fungh', 'porcini', 'shiitake', 'champignon'])) return '🍄';
  if (has(['broccol', 'cavol', 'spinac', 'insalat', 'lattuga', 'rucola', 'basilico', 'prezzemolo', 'erbe'])) return '🥬';
  if (has(['mais'])) return '🌽';
  if (has(['avocado'])) return '🥑';
  if (has(['limon', 'lime'])) return '🍋';
  if (has(['mela ', 'mele'])) return '🍎';
  if (has(['banan'])) return '🍌';
  if (has(['fragol', 'mirtill', 'lampon', 'frutti di bosco', 'bacche'])) return '🫐';
  if (has(['cocco'])) return '🥥';
  if (has(['ceci', 'fagiol', 'lenticch', 'legumi', 'piselli', 'edamame'])) return '🫘';
  if (has(['pasta', 'spaghetti', 'penne', 'lasagne', 'fusilli', 'noodle', 'gnocchi'])) return '🍝';
  if (has(['riso', 'risotto', 'basmati'])) return '🍚';
  if (has(['pane', 'pangrattato', 'toast', 'crostini', 'baguette'])) return '🍞';
  if (has(['farina', 'semola', 'lievito'])) return '🌾';
  if (has(['couscous', 'quinoa', 'bulgur', 'farro', 'orzo', 'avena', 'fiocchi'])) return '🌾';
  if (has(['mandorl', 'anacard', 'noci', 'nocciol', 'pistacch', 'frutta a guscio', 'arachidi', 'tahin'])) return '🥜';
  if (has(['olio', 'evo', 'oliva'])) return '🫒';
  if (has(['sale'])) return '🧂';
  if (has(['pepe', 'peperoncino', 'curcuma', 'cumino', 'paprika', 'spezie', 'cannella', 'noce moscata', 'zenzero', 'curry'])) return '🌶️';
  if (has(['zucchero', 'sciroppo', 'agave', 'acero', 'dolcificante'])) return '🍯';
  if (has(['cioccolat', 'cacao'])) return '🍫';
  if (has(['latte', 'panna', 'yogurt', 'bevanda', 'margarina', 'burro', 'formagg', 'mozzarell', 'ricotta', 'parmigian', 'pecorino'])) return '🥛';
  if (has(['acqua', 'brodo'])) return '💧';
  if (has(['vino', 'aceto', 'birra'])) return '🍷';
  if (has(['oliva', 'olive', 'capperi'])) return '🫒';
  return '🥄';
}

/// Emoji per un ingrediente. Match a PAROLA INTERA (niente sottostringhe: così
/// "alimentare" non diventa "lime", "olio di soia" non diventa tofu, ecc.).
/// Se non c'è un'emoji davvero adatta ritorna '' (l'UI mostra un pallino neutro).
String ingredientEmoji(String raw) {
  final s = raw.toLowerCase();
  bool w(List<String> kws) =>
      kws.any((k) => RegExp('(^|[^a-zà-ù])$k').hasMatch(s));

  // ordine: dal più specifico al più generico
  if (w(['peperoncin'])) return '🌶️';
  if (w(['peperon'])) return '🫑';
  if (w(['pomodor', 'passata', 'pelati', 'concentrato di pom'])) return '🍅';
  if (w(['aglio'])) return '🧄';
  if (w(['cipoll', 'scalogn', 'porro', 'porri'])) return '🧅';
  if (w(['carot'])) return '🥕';
  if (w(['patat'])) return '🥔';
  if (w(['zucchin', 'cetriol'])) return '🥒';
  if (w(['melanzan'])) return '🍆';
  if (w(['fungh', 'porcini', 'champignon', 'shiitake', 'chiodini'])) return '🍄';
  if (w(['basilico', 'prezzemolo', 'rosmarino', 'timo', 'menta', 'salvia',
        'coriandolo', 'origano', 'erba', 'erbe', 'aneto', 'maggiorana'])) return '🌿';
  if (w(['insalat', 'lattuga', 'spinac', 'rucola', 'cavol', 'bietol', 'verza',
        'radicchio', 'catalogna'])) return '🥬';
  if (w(['mais'])) return '🌽';
  if (w(['avocado'])) return '🥑';
  if (w(['limon', 'lime'])) return '🍋';
  if (w(['mela', 'mele'])) return '🍎';
  if (w(['banan'])) return '🍌';
  if (w(['fragol'])) return '🍓';
  if (w(['mirtill', 'lampon', 'more', 'frutti di bosco', 'bacche', 'ribes'])) return '🫐';
  if (w(['cocco'])) return '🥥';
  if (w(['ceci', 'fagiol', 'lenticch', 'legumi', 'piselli', 'edamame',
        'cannellini', 'borlotti', 'soia'])) return '🫘';
  if (w(['spaghett', 'pasta', 'penne', 'fusilli', 'lasagn', 'tagliatell',
        'gnocch', 'maccheron', 'rigatoni', 'noodle', 'tortellin', 'ravioli'])) return '🍝';
  if (w(['riso', 'risotto', 'basmati'])) return '🍚';
  if (w(['pane', 'pangrattato', 'crostini', 'baguette', 'focaccia', 'toast'])) return '🍞';
  if (w(['farina', 'semola', 'avena', 'couscous', 'quinoa', 'bulgur', 'farro',
        'orzo', 'cereali', 'fiocchi'])) return '🌾';
  if (w(['mandorl', 'anacard', 'noci', 'nocciol', 'pistacch', 'arachidi',
        'tahin', 'pinoli', 'semi di'])) return '🥜';
  if (w(['burro', 'margarina'])) return '🧈';
  if (w(['olio', 'oliva', 'olive', 'evo'])) return '🫒';
  if (w(['sale'])) return '🧂';
  if (w(['latte', 'panna', 'yogurt', 'bevanda', 'parmigian', 'pecorino',
        'formagg', 'mozzarell', 'ricotta', 'stracchino', 'mascarpone'])) return '🥛';
  if (w(['cioccolat', 'cacao'])) return '🍫';
  if (w(['miele', 'sciroppo', 'agave', 'acero'])) return '🍯';
  if (w(['zucchero', 'dolcificante'])) return '🍬';
  if (w(['acqua', 'brodo'])) return '💧';
  if (w(['vino', 'aceto', 'birra'])) return '🍷';
  // tofu/tempeh/seitan/lupini e spezie (pepe, lievito, curcuma, cumino, paprika,
  // cannella...): niente emoji adatta -> l'UI usa un'icona SVG generata dall'AI.
  return '';
}

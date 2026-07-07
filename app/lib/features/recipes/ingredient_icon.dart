// Unità di misura e parole di preparazione da togliere per ricavare il
// PRODOTTO da comprare (per la lista della spesa): "200 g di tempeh a cubetti"
// -> "Tempeh", "2 spicchi d'aglio tritato" -> "Aglio".
final _shopUnitRe = RegExp(
    r"\b(g|gr|grammi?|kg|ml|cl|dl|l|litr\w*|cucchiai\w*|tazz\w*|q\.?\s?b\.?|pizzic\w*|spicch\w*|fogli\w*|foglie|ramett\w*|manciat\w*|fett\w*|fettin\w*|pezz\w*|confezion\w*|barattol\w*|lattin\w*|mazzett\w*|scatol\w*|bicchier\w*|circa|qualche|q|b)\b",
    caseSensitive: false);
final _shopPrepRe = RegExp(
    r"\b(tritat\w*|tagliat\w*|affettat\w*|grattugiat\w*|sbucciat\w*|spellat\w*|pelat\w*|frullat\w*|schiacciat\w*|macinat\w*|sminuzzat\w*|spezzettat\w*|a cubetti|a cubetti piccoli|a dadini|a fette|a fettine|a rondelle|a listarelle|a julienne|a pezzi|a pezzetti|a tocchetti|in polvere|in scaglie|in pezzi|fresc\w*|secc\w*|matur\w*|finemente|grossolanamente|sottil\w*|a piacere|a temperatura ambiente|ammollat\w*|cott\w*|crud\w*|bio|extra\s?vergine)\b",
    caseSensitive: false);
final _shopStopRe = RegExp(
    r"\b(di|del|della|dello|dei|degli|delle|al|allo|alla|ai|agli|un|una|uno|lo|la|le|gli|il|i|e|ed|con|per|in)\b",
    caseSensitive: false);

/// Nome "da comprare" ripulito da quantità, unità e modo di preparazione.
/// Fallback usato quando manca `normalized_name` (ricette non arricchite).
String cleanIngredientName(String raw) {
  var s = raw.toLowerCase();
  final comma = s.indexOf(',');
  if (comma > 0) s = s.substring(0, comma); // dopo la virgola è di solito prep
  s = s.replaceAll("'", ' ').replaceAll('’', ' ');
  s = s.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  s = s.replaceAll(RegExp(r'[0-9]+([.,/][0-9]+)?'), ' ');
  s = s.replaceAll(RegExp('[½¼¾⅓⅔⅛]'), ' ');
  s = s.replaceAll(_shopPrepRe, ' ');
  s = s.replaceAll(_shopUnitRe, ' ');
  s = s.replaceAll(_shopStopRe, ' ');
  s = s.replaceAll(RegExp('[^a-zà-ù\\s]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) return raw.trim();
  return s[0].toUpperCase() + s.substring(1);
}

/// Emoji per un ingrediente. Match a PAROLA INTERA (niente sottostringhe: così
/// "alimentare" non diventa "lime", "olio di soia" non diventa tofu, ecc.).
/// Se non c'è un'emoji davvero adatta ritorna '' (l'UI mostra un pallino neutro).
String ingredientEmoji(String raw) {
  final s = raw.toLowerCase();
  bool w(List<String> kws) =>
      kws.any((k) => RegExp('(^|[^a-zà-ù])$k').hasMatch(s));

  // LIVELLO 1 — FORME / derivati: quello che il prodotto È vince su ciò da cui
  // deriva ("olio di soia" è OLIO, "latte di mandorle" è LATTE, "farina di ceci"
  // è FARINA). Vanno PRIMA degli ingredienti grezzi per non farsi rubare il match.
  if (w(['olio', 'oliva', 'olive', 'evo'])) return '🫒';
  if (w(['burro', 'margarina'])) return '🧈';
  if (w(['latte', 'panna', 'yogurt', 'bevanda vegetale', 'parmigian', 'pecorino',
        'formagg', 'mozzarell', 'ricotta', 'stracchino', 'mascarpone'])) return '🥛';
  if (w(['sale'])) return '🧂';
  if (w(['zucchero', 'dolcificante'])) return '🍬';
  if (w(['miele', 'sciroppo', 'agave', 'acero', 'malto'])) return '🍯';
  if (w(['aceto', 'vino', 'birra'])) return '🍷';
  if (w(['brodo', 'acqua'])) return '💧';
  if (w(['cioccolat', 'cacao'])) return '🍫';
  if (w(['farina', 'semola'])) return '🌾'; // farina di qualsiasi cosa
  if (w(['spaghett', 'pasta', 'penne', 'fusilli', 'lasagn', 'tagliatell',
        'gnocch', 'maccheron', 'rigatoni', 'noodle', 'tortellin', 'ravioli'])) return '🍝';
  if (w(['riso', 'risotto', 'basmati'])) return '🍚';
  if (w(['pane', 'pangrattato', 'crostini', 'baguette', 'focaccia', 'toast'])) return '🍞';
  if (w(['avena', 'couscous', 'quinoa', 'bulgur', 'farro', 'orzo', 'cereali',
        'fiocchi'])) return '🌾';

  // LIVELLO 2 — ingredienti grezzi (verdura, frutta, legumi, frutta secca, semi).
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
  // semi (lino, chia, sesamo, zucca...): non sono frutta secca -> icona AI
  if (w(['semi di lino', 'semi di chia', 'semi di sesamo', 'semi di zucca',
        'semi di girasole', 'semi di papavero', 'lino', 'chia'])) return '';
  if (w(['arachid'])) return '🥜'; // 🥜 è "peanut": solo le arachidi
  // mandorle, anacardi, noci, nocciole, pistacchi, pinoli, tahin, semi e le
  // spezie (pepe, lievito, curcuma...): nessuna emoji dedicata (l'unica per la
  // frutta secca è l'arachide) -> icona SVG generata dall'AI, distinta per ognuno.
  // Lo stesso per tofu/tempeh/seitan.
  return '';
}

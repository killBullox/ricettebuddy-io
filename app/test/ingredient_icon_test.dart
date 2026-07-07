import 'package:flutter_test/flutter_test.dart';
import 'package:ricettebuddy/features/recipes/ingredient_icon.dart';

// Blocca la classe di bug "la forma perde contro la fonte": olio/latte/farina/
// sale devono vincere sull'ingrediente da cui derivano, e i descrittori
// ("in fiocchi", "in polvere") non devono dirottare l'icona.
void main() {
  group('ingredientEmoji', () {
    final cases = <String, String>{
      // FORME che vincono sulla fonte
      'olio di soia': '🫒',
      'olio extravergine di oliva': '🫒',
      'olio di semi di girasole': '🫒',
      'latte di mandorle': '🥛',
      'latte di soia': '🥛',
      'farina di ceci': '🌾',
      'farina di mandorle': '🌾',
      '250 g di farina 00': '🌾',
      // sale non deve diventare cereale
      'sale in fiocchi': '🧂',
      'sale fino': '🧂',
      // cereali/fiocchi restano cereali
      "fiocchi d'avena": '🌾',
      // ingredienti grezzi
      'pomodori pelati': '🍅',
      "2 spicchi d'aglio": '🧄',
      '200 g di ceci': '🫘',
      'cioccolato fondente': '🍫',
      // 🥜 è l'arachide: solo le arachidi. Gli altri frutti secchi -> icona AI.
      'arachidi tostate': '🥜',
      'anacardi ammollati': '',
      'pistacchi non salati': '',
      'mandorle a lamelle': '',
      'noci sgusciate': '',
      'aceto balsamico': '🍷',
      // semi -> icona AI (stringa vuota)
      'semi di lino macinati': '',
      // niente emoji adatta -> icona AI
      'lievito alimentare': '',
      'pepe nero': '',
      'estratto di vaniglia': '',
    };

    cases.forEach((input, expected) {
      test('"$input" -> "$expected"', () {
        expect(ingredientEmoji(input), expected);
      });
    });
  });
}

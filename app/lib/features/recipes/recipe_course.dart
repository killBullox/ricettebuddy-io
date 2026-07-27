import '../../data/models/recipe.dart';

/// Classificazione delle ricette per PORTATA, allineata all'area team
/// (site-team COURSE_MAP). Serve ai filtri della lista ricette.
///
/// "Piatto unico" e "Insalatona" sono trasversali (una bowl può essere un
/// "Primo" per categoria): si riconoscono in automatico da titolo/categoria +
/// kcal, ma il team può correggere le eccezioni con i tag `piatto_unico` /
/// `insalatona` (o `no_piatto_unico` / `no_insalatona`) sulla ricetta.

const courseColazione = 'Colazione';
const courseAntipasti = 'Antipasti';
const coursePrimi = 'Primi';
const courseZuppe = 'Zuppe';
const courseSecondi = 'Secondi';
const coursePanePizza = 'Pane/Pizza';
const courseDolci = 'Dolci';
const courseInternazionali = 'Internazionali';
const coursePiattoUnico = 'Piatto unico';
const courseInsalatona = 'Insalatona';

/// Le opzioni mostrate nel filtro "Portata" (in ordine).
const courseOptions = <String>[
  courseColazione, courseAntipasti, coursePrimi, courseZuppe, courseSecondi,
  coursePanePizza, courseDolci, courseInternazionali,
  coursePiattoUnico, courseInsalatona,
];

const _courseMap = {
  'Colazione': courseColazione,
  'Antipasti e contorni': courseAntipasti,
  'Primi di pasta': coursePrimi,
  'Riso e cereali': coursePrimi,
  'Zuppe e minestre': courseZuppe,
  'Legumi e secondi vegetali': courseSecondi,
  'Lievitati, pane e pizza': coursePanePizza,
  'Dolci': courseDolci,
};

/// Portata "principale" di una ricetta (una delle 7 di base).
String courseOf(Recipe r) => _courseMap[r.category] ?? courseInternazionali;

double? _kcal(Recipe r) => (r.nutrition?['kcal'] as num?)?.toDouble();

final _rePiattoUnico = RegExp(
    r'piatto unico|bowl|buddha|poke|one[- ]pot|curry|chili|paella|couscous|cous cous|parmigiana',
    caseSensitive: false);
final _reInsalatona = RegExp(
    r'insalat|fattoush|tabbouleh|tabbule|panzanella|caesar|poke|nizzarda',
    caseSensitive: false);

bool _hasTag(Recipe r, String t) =>
    r.tags.any((x) => x.toLowerCase() == t);

bool isPiattoUnico(Recipe r) {
  if (_hasTag(r, 'piatto_unico')) return true;
  if (_hasTag(r, 'no_piatto_unico')) return false;
  final hay = '${r.category ?? ''} ${r.title}';
  if (_rePiattoUnico.hasMatch(hay)) return true;
  final k = _kcal(r);
  final c = courseOf(r);
  return k != null &&
      k >= 350 &&
      (c == coursePrimi || c == courseSecondi || c == courseInternazionali);
}

bool isInsalatona(Recipe r) {
  if (_hasTag(r, 'insalatona')) return true;
  if (_hasTag(r, 'no_insalatona')) return false;
  final hay = '${r.category ?? ''} ${r.title}';
  if (!_reInsalatona.hasMatch(hay)) return false;
  final k = _kcal(r);
  return k == null || k >= 300; // insalata "da pasto", non semplice contorno
}

/// True se la ricetta rientra in [course] (gestisce anche le due trasversali).
bool recipeInCourse(Recipe r, String course) {
  if (course == coursePiattoUnico) return isPiattoUnico(r);
  if (course == courseInsalatona) return isInsalatona(r);
  return courseOf(r) == course;
}

// ---- Caratteristiche trasversali (facile / veloce / di stagione) ----

const traitFacile = 'Facile';
const traitVeloce = 'Veloce';
const traitStagione = 'Di stagione';
const traitOptions = <String>[traitFacile, traitVeloce, traitStagione];

/// "Facile" = difficoltà indicata come Facile.
bool isFacile(Recipe r) => (r.difficulty ?? '').toLowerCase() == 'facile';

/// "Veloce" = tempo totale (prep + cottura) entro 30 minuti.
bool isVeloce(Recipe r) {
  final t = (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0);
  return t > 0 && t <= 30;
}

/// "Di stagione" = il mese corrente è tra i mesi di stagione della ricetta.
/// (Nessun dato stagione => la consideriamo sempre disponibile.)
bool isDiStagione(Recipe r, {DateTime? now}) {
  if (r.seasonMonths.isEmpty) return true;
  final m = (now ?? DateTime.now()).month;
  return r.seasonMonths.contains(m);
}

bool recipeHasTrait(Recipe r, String trait) {
  switch (trait) {
    case traitFacile:
      return isFacile(r);
    case traitVeloce:
      return isVeloce(r);
    case traitStagione:
      return isDiStagione(r);
  }
  return false;
}

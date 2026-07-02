import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/diet.dart';

/// Preferenze utente (lingua, unità, regimi alimentari).
/// In demo vivono in memoria; con Supabase andranno sulla tabella `profiles`.
class AppPrefs {
  final String language;
  final String measurement; // 'metric' | 'imperial'
  final Set<Diet> diets;

  const AppPrefs({
    this.language = 'it',
    this.measurement = 'metric',
    this.diets = const {},
  });

  AppPrefs copyWith({String? language, String? measurement, Set<Diet>? diets}) =>
      AppPrefs(
        language: language ?? this.language,
        measurement: measurement ?? this.measurement,
        diets: diets ?? this.diets,
      );
}

class PrefsNotifier extends Notifier<AppPrefs> {
  @override
  AppPrefs build() => const AppPrefs();

  void setLanguage(String v) => state = state.copyWith(language: v);
  void setMeasurement(String v) => state = state.copyWith(measurement: v);

  void toggleDiet(Diet d) {
    final next = {...state.diets};
    next.contains(d) ? next.remove(d) : next.add(d);
    state = state.copyWith(diets: next);
  }
}

final prefsProvider =
    NotifierProvider<PrefsNotifier, AppPrefs>(PrefsNotifier.new);

/// Comodo accesso ai soli regimi attivi.
final activeDietsProvider = Provider<Set<Diet>>((ref) {
  return ref.watch(prefsProvider).diets;
});

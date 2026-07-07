import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Istanza di SharedPreferences, iniettata in main().
final sharedPrefsProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

/// Lingua scelta dall'utente (null = lingua di sistema). Persistita.
class LocaleController extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;
  static const _key = 'locale';
  LocaleController(this._prefs) : super(_load(_prefs));

  static Locale? _load(SharedPreferences p) {
    final code = p.getString(_key);
    return (code == null || code.isEmpty) ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>(
  (ref) => LocaleController(ref.watch(sharedPrefsProvider)),
);

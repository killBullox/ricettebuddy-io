/// Configurazione runtime. I valori si passano a build/run con --dart-define
/// (mai committare le chiavi):
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Modalità demo: senza Supabase l'app gira con dati di esempio in memoria,
  /// così è provabile subito (utile per il test e le anteprime web).
  static bool get demo => !isConfigured;
}

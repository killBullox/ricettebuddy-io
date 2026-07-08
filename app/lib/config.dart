/// Configurazione runtime. I valori si passano a build/run con --dart-define
/// (mai committare le chiavi):
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Base URL del backend Node (import/AI/icone). Sul web resta vuoto -> stessa
  /// origine da cui è servita l'app. Su mobile va impostato all'URL pubblico:
  ///   --dart-define=API_BASE=https://beetit.tuodominio.it
  static const apiBase = String.fromEnvironment('API_BASE');

  /// Risolve un percorso del backend: su mobile usa `API_BASE`, sul web la
  /// stessa origine. Usato per API, proxy immagini (/img), video (/video) e
  /// icone (/api/ingredient-icon).
  static Uri backendUri(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return apiBase.isNotEmpty
        ? Uri.parse('$apiBase/$p')
        : Uri.base.resolve(p);
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Modalità demo: senza Supabase l'app gira con dati di esempio in memoria,
  /// così è provabile subito (utile per il test e le anteprime web).
  static bool get demo => !isConfigured;
}

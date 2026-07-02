import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'features/auth/auth_gate.dart';

class RicetteBuddyApp extends StatelessWidget {
  const RicetteBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE8734A), // arancio "cucina"
    );
    return MaterialApp(
      title: 'RicetteBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      // F8 — localizzazione. Le lingue crescono aggiungendo file lib/l10n/*.arb.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
        Locale('nl'),
        Locale('fr'),
        Locale('de'),
        Locale('es'),
      ],
      home: Config.isConfigured
          ? const AuthGate()
          : const _MissingConfigScreen(),
    );
  }
}

/// Mostrata se mancano le variabili --dart-define di Supabase.
class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest, size: 48),
              const SizedBox(height: 16),
              Text('Configurazione mancante',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Avvia con:\n'
                'flutter run \\\n'
                '  --dart-define=SUPABASE_URL=... \\\n'
                '  --dart-define=SUPABASE_ANON_KEY=...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

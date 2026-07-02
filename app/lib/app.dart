import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_shell.dart';

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
      // Con Supabase configurato → login reale; altrimenti modalità demo.
      home: Config.isConfigured ? const AuthGate() : const HomeShell(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_shell.dart';
import 'features/import/share_receiver.dart';

class RicetteBuddyApp extends StatelessWidget {
  const RicetteBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB5326B), // barbabietola (identità BeetIt)
      primary: const Color(0xFFB5326B), // magenta barbabietola
      secondary: const Color(0xFF2E7D32), // verde foglia (accento)
      surface: const Color(0xFFFBFAF7),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Beet-It Vegan Recipes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFAF7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFBFAF7),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF3A0E2A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          backgroundColor: const Color(0xFFEFEDE6),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
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
      // ShareReceiver intercetta i link condivisi da altre app (solo mobile).
      home: ShareReceiver(
        child: Config.isConfigured ? const AuthGate() : const HomeShell(),
      ),
    );
  }
}

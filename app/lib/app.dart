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
      seedColor: const Color(0xFF3BA55D), // verde avocado
      primary: const Color(0xFF2E7D4F),
      secondary: const Color(0xFFB5326B), // barbabietola
      surface: const Color(0xFFFBFAF7),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'BeetIt',
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
            color: Color(0xFF17321F),
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
      home: Config.isConfigured ? const AuthGate() : const HomeShell(),
    );
  }
}

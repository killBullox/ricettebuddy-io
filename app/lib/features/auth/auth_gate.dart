import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_shell.dart';
import 'sign_in_page.dart';

/// Mostra la home se l'utente è autenticato, altrimenti la schermata di accesso.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const HomeShell();
        return const SignInPage();
      },
    );
  }
}

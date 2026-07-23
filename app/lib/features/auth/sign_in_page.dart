import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Accesso all'app. Metodi:
///  - Email + password (accedi / registrati)
///  - Google e Apple (OAuth via Supabase)
///  - Magic link (link via email) come alternativa senza password
///
/// Google/Apple richiedono i provider abilitati in Supabase (Authentication →
/// Providers) con le credenziali dei rispettivi developer console, e la URL di
/// redirect `io.beetit.recipes://login-callback/` fra quelle consentite.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false; // false = accedi, true = registrati
  bool _busy = false;
  String? _message;
  bool _ok = false;

  // Redirect per l'OAuth: su mobile il custom scheme del bundle, sul web niente
  // (Supabase usa l'origine corrente).
  static const _redirect = kIsWeb ? null : 'io.beetit.recipes://login-callback/';

  SupabaseClient get _auth => Supabase.instance.client;

  void _say(String m, {bool ok = false}) =>
      setState(() { _message = m; _ok = ok; });

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _message = null; });
    try {
      await action();
    } on AuthException catch (e) {
      _say('Accesso non riuscito: ${e.message}');
    } catch (e) {
      _say('Errore: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailPassword() => _run(() async {
        final email = _email.text.trim();
        final pwd = _password.text;
        if (email.isEmpty || pwd.length < 6) {
          _say('Inserisci email e una password di almeno 6 caratteri.');
          return;
        }
        if (_signUp) {
          final res = await _auth.auth.signUp(email: email, password: pwd);
          if (res.session == null) {
            _say('Ti abbiamo inviato una email per confermare l\'account.',
                ok: true);
          }
        } else {
          await _auth.auth.signInWithPassword(email: email, password: pwd);
          // Al successo AuthGate mostra la home da solo.
        }
      });

  Future<void> _magicLink() => _run(() async {
        final email = _email.text.trim();
        if (email.isEmpty) { _say('Inserisci prima la tua email.'); return; }
        await _auth.auth.signInWithOtp(email: email, emailRedirectTo: _redirect);
        _say('Ti abbiamo inviato un link di accesso via email.', ok: true);
      });

  Future<void> _oauth(OAuthProvider provider) => _run(() async {
        await _auth.auth.signInWithOAuth(provider, redirectTo: _redirect);
      });

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset('assets/branding/beet_it_round.svg',
                      width: 170, semanticsLabel: 'Beet It! Vegan Recipes'),
                  const SizedBox(height: 20),
                  // segmento Accedi / Registrati
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Accedi')),
                      ButtonSegment(value: true, label: Text('Registrati')),
                    ],
                    selected: {_signUp},
                    onSelectionChanged: (s) =>
                        setState(() { _signUp = s.first; _message = null; }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onSubmitted: (_) => _busy ? null : _emailPassword(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _emailPassword,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(_signUp ? 'Crea account' : 'Accedi'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _magicLink,
                    child: const Text('Accedi con link via email'),
                  ),

                  const SizedBox(height: 4),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('oppure'),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _oauth(OAuthProvider.google),
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: const Text('Continua con Google'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _oauth(OAuthProvider.apple),
                    icon: const Icon(Icons.apple, size: 20),
                    label: const Text('Continua con Apple'),
                  ),

                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _ok
                              ? const Color(0xFF3B8C43)
                              : Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

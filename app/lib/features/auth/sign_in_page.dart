import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Accesso via magic link (email). Sign in with Apple / Google si aggiungono
/// come provider OAuth in Supabase e qui con pulsanti dedicati.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  bool _sending = false;
  String? _message;

  Future<void> _sendMagicLink() async {
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _email.text.trim(),
      );
      setState(() => _message = 'Ti abbiamo inviato un link di accesso via email.');
    } catch (e) {
      setState(() => _message = 'Errore: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SvgPicture.asset('assets/branding/beet_it_round.svg',
                    width: 200, semanticsLabel: 'Beet-It Vegan Recipes'),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _sending ? null : _sendMagicLink,
                  child: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Accedi con link email'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

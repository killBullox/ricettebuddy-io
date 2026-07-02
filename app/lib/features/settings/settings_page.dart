import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = Supabase.instance.client.auth.currentUser?.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Lingua preferita'),
            subtitle: Text('Italiano'),
            trailing: Icon(Icons.chevron_right),
            // TODO(F8): selettore lingua legato a profiles.preferred_language
          ),
          const ListTile(
            title: Text('Unità di misura'),
            subtitle: Text('Metrico (g, ml)'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            title: const Text('Account'),
            subtitle: Text(email ?? '—'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Esci'),
            onTap: () => Supabase.instance.client.auth.signOut(),
          ),
          const Divider(),
          const ListTile(
            dense: true,
            title: Text('RicetteBuddy · versione 0.2'),
          ),
        ],
      ),
    );
  }
}

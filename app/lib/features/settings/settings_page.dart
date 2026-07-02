import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../data/models/diet.dart';
import '../../data/prefs.dart';
import '../sources/sources_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _languages = [
    ('it', 'Italiano'),
    ('en', 'English'),
    ('nl', 'Nederlands'),
    ('fr', 'Français'),
    ('de', 'Deutsch'),
    ('es', 'Español'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final notifier = ref.read(prefsProvider.notifier);
    final email = Config.demo
        ? 'demo (nessun account)'
        : Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          // --- Sorgenti ---
          ListTile(
            leading: const Icon(Icons.rss_feed),
            title: const Text('Sorgenti / Feed'),
            subtitle: const Text('Pagine web e account social per l\'auto-import'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SourcesPage()),
            ),
          ),
          const Divider(),

          // --- Regimi alimentari ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Regimi alimentari',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Dai feed verranno importate solo le ricette conformi a TUTTI i regimi attivi.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final d in Diet.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilterChip(
                    label: Text(d.label),
                    selected: prefs.diets.contains(d),
                    onSelected: (_) => notifier.toggleDiet(d),
                  ),
                ),
            ],
          ),
          const Divider(),

          // --- Lingua ---
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Lingua preferita'),
            trailing: DropdownButton<String>(
              value: prefs.language,
              underline: const SizedBox.shrink(),
              items: [
                for (final (code, name) in _languages)
                  DropdownMenuItem(value: code, child: Text(name)),
              ],
              onChanged: (v) => v == null ? null : notifier.setLanguage(v),
            ),
          ),

          // --- Unità ---
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Unità di misura'),
            trailing: DropdownButton<String>(
              value: prefs.measurement,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'metric', child: Text('Metrico')),
                DropdownMenuItem(value: 'imperial', child: Text('Imperiale')),
              ],
              onChanged: (v) => v == null ? null : notifier.setMeasurement(v),
            ),
          ),
          const Divider(),

          // --- Account ---
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            subtitle: Text(email ?? '—'),
          ),
          if (!Config.demo)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Esci'),
              onTap: () => Supabase.instance.client.auth.signOut(),
            ),
          const Divider(),
          ListTile(
            dense: true,
            title: Text('RicetteBuddy · versione 0.2'
                '${Config.demo ? ' · MODALITÀ DEMO' : ''}'),
          ),
        ],
      ),
    );
  }
}

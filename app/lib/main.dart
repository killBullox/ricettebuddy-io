import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Config.isConfigured) {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      // "anon key" è stata rinominata "publishable key" in Supabase.
      publishableKey: Config.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: RicetteBuddyApp()));
}

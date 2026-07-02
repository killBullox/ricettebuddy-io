import 'package:flutter_test/flutter_test.dart';

import 'package:ricettebuddy/config.dart';

void main() {
  test('Config non è configurato senza --dart-define', () {
    // Senza SUPABASE_URL/ANON_KEY passati a build-time, isConfigured è false.
    expect(Config.isConfigured, isFalse);
  });
}

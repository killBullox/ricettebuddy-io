#!/bin/bash
export PATH="$HOME/flutter/bin:$HOME/.rbenv/versions/3.3.6/bin:$PATH"
export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8
cd "$HOME/beetit" || exit 1
git fetch --depth 1 origin main >/dev/null 2>&1 && git reset --hard origin/main | tail -1
cd app || exit 1
flutter pub get >/dev/null 2>&1

# Il progetto usa Swift Package Manager: nessun CocoaPods.
rm -f ios/Podfile ios/Podfile.lock; rm -rf ios/Pods

# 1. config-only: rigenera l'integrazione SPM (FlutterGeneratedPluginSwiftPackage)
echo "=== flutter build ios --config-only (SPM) ==="
flutter build ios --config-only --release --dart-define=API_BASE=http://185.218.126.96:8090 --dart-define=SUPABASE_URL=https://zffcpwtijxbbshrpsxqq.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_PaKU0cAnn701i04XkFl-Eg_Xt7YUXLR 2>&1 | tail -4

# 2. xcodeproj: aggiunge il target app-extension (Swift puro, nessuna dipendenza)
echo "=== xcodeproj: add ShareExtension target ==="
ruby ~/add_share_target.rb ios/Runner.xcodeproj || { echo "XCODEPROJ_FAIL"; exit 1; }

# 3. Verifica: build senza firma (compilazione + embed dell'extension)
echo "=== flutter build ipa --no-codesign (build 3, verifica) ==="
flutter build ipa --no-codesign --dart-define=API_BASE=http://185.218.126.96:8090 --dart-define=SUPABASE_URL=https://zffcpwtijxbbshrpsxqq.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_PaKU0cAnn701i04XkFl-Eg_Xt7YUXLR --build-number=3 2>&1 | tail -22
echo "BUILD_EXIT=${PIPESTATUS[0]}"

# 4. Conferma che il target e' presente e l'app-extension e' dentro l'ipa/app
echo "=== target nel progetto ==="
grep -c 'ShareExtension' ios/Runner.xcodeproj/project.pbxproj
echo "=== .appex prodotto? ==="
find build -name '*.appex' 2>/dev/null | head
echo "SETUP_SHARE_DONE"

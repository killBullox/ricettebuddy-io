# Build Android (APK) — Beet It!

Il progetto Flutter builda l'APK con la solita pipeline. Note/gotcha emerse:

## compileSdk 37
`receive_sharing_intent` 1.9.0 (Android) richiede **compileSdk ≥ 37**, mentre
Flutter di default usa 36. Quindi in `app/android/app/build.gradle.kts`:

```kotlin
compileSdk = 37
```

e in `app/android/gradle.properties`:

```properties
android.suppressUnsupportedCompileSdk=37
```

(AGP consiglia max 36: il flag sopprime il warning, il build passa.)

## SDK: pacchetto android-37.0
La platform API 37 è pubblicata col nuovo schema di versioning minore, cioè
**`platforms;android-37.0`** (non `android-37`). Va installata così, poi serve un
symlink perché AGP cerca la cartella `android-37`:

```bash
sdkmanager 'platforms;android-37.0' 'build-tools;37.0.0'
ln -sfn "$ANDROID_HOME/platforms/android-37.0" "$ANDROID_HOME/platforms/android-37"
```

## Toolchain minima (macOS headless, come sul Mac Scaleway)
- JDK 17 (Temurin aarch64) → `JAVA_HOME`, e `flutter config --jdk-dir`
- Android cmdline-tools → `~/Library/Android/sdk/cmdline-tools/latest`
- `flutter config --android-sdk "$ANDROID_HOME"`

## Build
```bash
flutter build apk --release \
  --dart-define=API_BASE=http://185.218.126.96:8090 \
  --dart-define=SUPABASE_URL=https://zffcpwtijxbbshrpsxqq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_PaKU0cAnn701i04XkFl-Eg_Xt7YUXLR
# -> build/app/outputs/flutter-apk/app-release.apk  (firmato debug, installabile per test)
```

> **Le define Supabase sono obbligatorie** perché l'app esca dalla modalità demo
> e usi account reali, catalogo base e piani del nutrizionista. La chiave qui è la
> *publishable* (pubblica per design, sicura da committare) — mai la service_role.

Lo share (menu Condividi) è già dichiarato nel manifest (`ACTION_SEND` text/image),
gestito lato Flutter da `ShareReceiver`. La release usa la firma **debug**: per la
pubblicazione su Play Store va aggiunta una signing config di release.

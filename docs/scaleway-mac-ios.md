# Build iOS su Mac Scaleway → TestFlight (passo-passo)

Hai un Mac su Scaleway: lo usiamo come "macchina di build" per compilare Beet It!,
firmarla col tuo Apple Developer e caricarla su TestFlight (poi la installi
sull'iPhone via l'app TestFlight).

> ⚠️ Costo: i Mac mini Scaleway hanno **fatturazione minima 24h** (regola Apple).
> Fai tutto in una sessione e poi spegni/elimina l'istanza.

## 0. Prerequisiti (in parallelo)
- **Apple Developer Program** attivo ($99/anno) — se non è ancora approvato, aspetta.
- **Backend pubblico** raggiungibile (l'URL `API_BASE`). Senza, l'app si apre ma
  non carica ricette. (Lo mettiamo sulla VPS: vedi `ios-testflight.md`.)

## 1. Connettiti al Mac
Nella console Scaleway (Apple silicon → la tua istanza) trovi le credenziali
**VNC**. Connettiti con un client VNC (es. RealVNC Viewer) usando IP + password.

## 2. Installa gli strumenti (nel Terminale del Mac)
```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Flutter, CocoaPods, Git
brew install --cask flutter
brew install cocoapods git
```
Poi installa **Xcode** dal Mac App Store (accedi con il tuo Apple ID) e accetta la licenza:
```bash
sudo xcodebuild -license accept
flutter doctor            # deve diventare tutto verde per iOS
```

## 3. Prendi il progetto
```bash
git clone https://github.com/killBullox/ricettebuddy-io.git
cd ricettebuddy-io/app
flutter pub get
```

## 4. Firma (una volta)
Apri il progetto in Xcode:
```bash
open ios/Runner.xcworkspace
```
- Seleziona il target **Runner** → **Signing & Capabilities**.
- **Team**: scegli il tuo team Apple Developer. Bundle id: `io.beetit.recipes`.
- Lascia "Automatically manage signing" attivo.

## 5. Compila e carica su TestFlight
```bash
flutter build ipa --release --dart-define=API_BASE=https://IL-TUO-BACKEND
```
L'IPA esce in `build/ios/ipa/`. Caricalo su App Store Connect con **Transporter**
(app gratis dal Mac App Store) oppure da **Xcode → Organizer → Distribute App →
App Store Connect → Upload**.

## 6. Installa sull'iPhone
- Su App Store Connect la build appare in **TestFlight** (dopo qualche minuto di
  "processing").
- Aggiungiti come **tester interno**.
- Sull'iPhone installa l'app **TestFlight**, accetta l'invito, installa Beet It!.

## Nota onesta
Questa via è potente ma manuale (Xcode via VNC). Se ti sembra troppo, **Codemagic**
(vedi `ios-testflight.md`) fa gli stessi passi in automatico col tuo stesso account
Apple. Il Mac Scaleway conviene se vuoi controllo diretto o build frequenti.

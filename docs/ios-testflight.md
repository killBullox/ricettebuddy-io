# Beet-It su iPhone (nativo, via TestFlight)

Da Windows non si compila iOS: usiamo un **Mac in cloud (Codemagic)** che builda,
firma e carica su **TestFlight**. Ecco l'ordine dei passi.

## Fatto lato codice (già pronto)
- Icone app iOS generate dal logo barbabietola.
- Bundle identifier: **`io.beetit.recipes`**; nome app "Beet-It Recipes".
- Base URL backend configurabile: `--dart-define=API_BASE=<url pubblico>`.
- `codemagic.yaml` (workflow `ios-testflight`).

## Cosa devi fare tu (account/servizi)

### 1. Apple Developer Program — $99/anno
Iscriviti su https://developer.apple.com/programs/ (approvazione anche 24-48h,
**inizia subito**).

### 2. App su App Store Connect
- https://appstoreconnect.apple.com → My Apps → **+** → New App.
- Bundle ID: `io.beetit.recipes` (prima registralo in Certificates → Identifiers).
- Segna l'**Apple ID numerico** dell'app (serve in codemagic.yaml → `APP_STORE_APPLE_ID`).

### 3. Chiave API App Store Connect
- App Store Connect → Users and Access → Integrations → **App Store Connect API** →
  genera una chiave (ruolo App Manager). Scarica il file `.p8`, segna Key ID e Issuer ID.

### 4. Codemagic
- https://codemagic.io → accedi con GitHub, aggiungi il repo `ricettebuddy-io`.
- Team → Integrations → **App Store Connect**: carica la chiave `.p8` (Key ID/Issuer),
  chiama l'integrazione **`CodemagicASC`** (come nel yaml).
- Crea un **environment group** chiamato `beetit` con la variabile:
  - `API_BASE` = URL pubblico del backend (es. `https://beetit.tuodominio.it`).
- Avvia il workflow **ios-testflight**.

### 5. TestFlight sull'iPhone
- Installa l'app **TestFlight** dall'App Store.
- Quando la build arriva su TestFlight, accetta l'invito e installa Beet-It.

## Prerequisito: il backend pubblico
La build TestFlight gira sul tuo iPhone ovunque: **non** raggiunge il PC. Il server
Node (import social con Playwright + veganizzazione AI + icone) va deployato su un
**URL pubblico** (la VPS). È il valore di `API_BASE`. Senza questo, l'app si apre ma
non carica né importa ricette.

## La Share Extension (tasto Condividi)
Va aggiunta come **target in Xcode** (vedi `share-extension-ios.md`). Si può fare in
un secondo momento su Codemagic/Xcode: la prima build TestFlight può uscire anche
senza, per testare il resto dell'app.

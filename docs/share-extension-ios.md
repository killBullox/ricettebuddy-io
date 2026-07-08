# Share Extension iOS — "Beet-It Recipes" nel menu Condividi

Su **Android è già pronto**: il manifest dichiara gli `intent-filter` `ACTION_SEND`
(text/* e image/*), quindi Beet-It compare nel menu Condividi. L'app riceve il
link tramite `receive_sharing_intent` e lo importa (vedi
`lib/features/import/share_receiver.dart`).

Su **iOS** l'estensione è integrata in modo **scriptato e riproducibile** (niente
passaggi manuali in Xcode). Vive in `app/ios/Share/` + `app/ios/scripts/`.

## Perché autonoma (Swift puro)

`receive_sharing_intent` 1.9.0 usa **Swift Package Manager** e **non ha podspec**.
Agganciare quel package a una *nuova* app-extension via script è impraticabile.
Quindi la nostra `ShareExtension` è **autonoma**: nessuna dipendenza, solo
`Share/ShareViewController.swift`. Scrive il contenuto condiviso nell'**App Group**
`group.io.beetit.recipes` sotto la chiave `ShareKey`, nello **stesso formato**
`SharedMediaFile` (JSON `[{path,type,…}]`, `type` = `url`/`text`) che il lato
Flutter del plugin legge, poi riapre l'app con lo schema
`ShareMedia-io.beetit.recipes:share`.

## Pezzi nel repo

- `app/ios/Share/ShareViewController.swift` — extension autonoma (`@objc(ShareViewController)`).
- `app/ios/Share/Info.plist` — `NSExtensionActivationRule` (WebURL + Text),
  `NSExtensionPrincipalClass = ShareViewController`, point `com.apple.share-services`.
- `app/ios/Share/Share.entitlements` — App Group `group.io.beetit.recipes`.
- `app/ios/Runner/Runner.entitlements` — stessa App Group.
- `app/ios/Runner/Info.plist` — `CFBundleURLScheme = ShareMedia-io.beetit.recipes`
  (usato per riaprire l'app) + `CFBundleDisplayName = Beet-It Recipes`.
- `app/ios/scripts/add_share_target.rb` — aggiunge il target app-extension al
  `.xcodeproj` (target, build settings, embed in Runner, dipendenza, entitlements).
- `app/ios/scripts/build_with_share.sh` — pipeline completa sul Mac di build.

## Build (sul Mac, progetto in modalità SPM)

```bash
bash app/ios/scripts/build_with_share.sh      # reset + pub get + config-only + add target + build ipa --no-codesign
cd app/ios && fastlane sign && fastlane upload # export firmato + upload TestFlight
```

### Dettagli critici risolti

1. **SPM, non CocoaPods.** Il progetto integra i plugin via
   `FlutterGeneratedPluginSwiftPackage`. Nessun `Podfile`: lo script lo rimuove.
2. **Ordine delle build phase.** La fase *Embed App Extensions* deve stare
   **prima** del Run Script *Thin Binary* di Flutter, altrimenti Xcode segnala un
   *dependency cycle* e l'archive fallisce. Lo fa `add_share_target.rb`.
3. **App Group provisioning.** L'export con firma automatica
   (`-allowProvisioningUpdates` + App Store Connect API key) registra da solo
   l'App ID dell'extension (`io.beetit.recipes.ShareExtension`) e l'App Group su
   entrambi i profili. `CodeSignOnCopy` sull'appex embeddato.

## Lato Flutter — già fatto

`ShareReceiver` (montato come `home` in `app.dart`) ascolta
`getInitialMedia()` / `getMediaStream()`, estrae l'URL e chiama l'import mostrando
il loader.

> Nota: la Share Extension si testa solo su un **device/simulatore iOS** (o
> Android), non sul build web.

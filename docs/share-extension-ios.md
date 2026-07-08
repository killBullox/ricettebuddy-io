# Share Extension iOS — "Beet-It Recipes" nel menu Condividi

Su **Android è già pronto**: il manifest dichiara gli `intent-filter` `ACTION_SEND`
(text/* e image/*), quindi Beet-It compare nel menu Condividi. L'app riceve il
link tramite `receive_sharing_intent` e lo importa (vedi
`lib/features/import/share_receiver.dart`).

Su **iOS** l'estensione è integrata in modo **scriptato e riproducibile** (niente
passaggi manuali in Xcode). Vive in `app/ios/Share/` + `app/ios/scripts/`.

## Meccanismo (niente App Group, niente plugin)

`receive_sharing_intent` 1.9.0 usa **Swift Package Manager** e non ha podspec:
agganciarlo a una nuova app-extension è impraticabile. E l'App Group non è
utilizzabile: l'entitlement `application-groups` non entra nel binario firmato
(`-allowProvisioningUpdates` non registra l'App Group, e l'archive firmato con
firma automatica fallisce sull'auth della API key). Quindi:

1. La `ShareExtension` (Swift puro, `Share/ShareViewController.swift`) estrae il
   link condiviso (`public.url` / `public.plain-text`) e **riapre l'app con il
   link dentro l'URL**: `ShareMedia-io.beetit.recipes://import?u=<link-encoded>`.
2. Flutter usa lo **scene lifecycle**: il `Runner/SceneDelegate.swift`
   (sottoclasse di `FlutterSceneDelegate`) fa override di `willConnectTo` e
   `openURLContexts`, cattura il link in `SceneDelegate.pendingSharedUrl`.
3. `Runner/AppDelegate.swift` espone il link via `MethodChannel("beetit/share")`.
4. `lib/features/import/share_receiver.dart` (montato come `home`) chiama il
   canale su launch e ad ogni **resume** dell'app → importa e apre la ricetta.

L'unico requisito iOS è lo **schema URL** `ShareMedia-io.beetit.recipes` in
`Runner/Info.plist` (nessun entitlement, nessun profilo speciale).

## Pezzi nel repo

- `app/ios/Share/ShareViewController.swift` — extension autonoma (`@objc`).
- `app/ios/Share/Info.plist` — `NSExtensionActivationRule` (WebURL + Text),
  `NSExtensionPrincipalClass = ShareViewController`, point `com.apple.share-services`.
- `app/ios/Runner/SceneDelegate.swift` — cattura il link dallo schema URL.
- `app/ios/Runner/AppDelegate.swift` — `MethodChannel("beetit/share")`.
- `app/ios/Runner/Info.plist` — `CFBundleURLScheme = ShareMedia-io.beetit.recipes`
  + `CFBundleDisplayName = Beet-It Recipes`.
- `app/ios/scripts/add_share_target.rb` — aggiunge il target app-extension.
- `app/ios/scripts/build_with_share.sh` — pipeline di build sul Mac.

## Build (sul Mac, progetto in modalità SPM)

```bash
bash app/ios/scripts/build_with_share.sh      # reset + pub get + config-only + add target + build ipa --no-codesign
cd app/ios && fastlane sign && fastlane upload # export firmato + upload TestFlight
```

### Dettagli critici risolti

1. **SPM, non CocoaPods.** Nessun `Podfile`: lo script lo rimuove.
2. **Ordine build phase.** *Embed App Extensions* deve stare **prima** del Run
   Script *Thin Binary* di Flutter, altrimenti Xcode segnala un dependency cycle.
3. **Firma.** Export da archive `--no-codesign` (lane `sign`): nessuna entitlement
   speciale, così il signing non richiede provisioning di capability.

## Lato Android

`ShareReceiver` usa il plugin `receive_sharing_intent` (intent `ACTION_SEND`).

> La Share Extension si testa solo su un **device/simulatore iOS** (o Android),
> non sul build web.

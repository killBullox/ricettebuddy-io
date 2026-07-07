# Share Extension iOS — "Beet-It Recipes" nel menu Condividi

Su **Android è già pronto**: il manifest dichiara gli `intent-filter` `ACTION_SEND`
(text/* e image/*), quindi Beet-It compare nel menu Condividi. L'app riceve il
link tramite `receive_sharing_intent` e lo importa (vedi
`lib/features/import/share_receiver.dart`).

Su **iOS** serve un target **Share Extension** creato in Xcode (non è generabile
solo da file). Passi una tantum, poi funziona come Avocadish:

## 1. Crea il target Share Extension
In Xcode: `File → New → Target… → Share Extension`. Nome: `ShareExtension`.

## 2. App Group (per passare il link all'app)
- Aggiungi la capability **App Groups** sia al target `Runner` sia a
  `ShareExtension`, con lo **stesso** gruppo, es. `group.io.beetit.recipes`.

## 3. Sostituisci i file dell'estensione con quelli di receive_sharing_intent
Segui il README del plugin (v1.8): copia lo `ShareViewController.swift` fornito
e imposta in **entrambi** gli Info.plist la stessa App Group in
`AppGroupId` / `NSExtensionActivationRule`.

`ShareExtension/Info.plist` — regola di attivazione (accetta URL, testo, immagini):

```xml
<key>NSExtension</key>
<dict>
  <key>NSExtensionAttributes</key>
  <dict>
    <key>NSExtensionActivationRule</key>
    <dict>
      <key>NSExtensionActivationSupportsWebURLWithMaxCount</key><integer>1</integer>
      <key>NSExtensionActivationSupportsText</key><true/>
      <key>NSExtensionActivationSupportsImageWithMaxCount</key><integer>1</integer>
    </dict>
  </dict>
  <key>NSExtensionMainStoryboard</key><string>MainInterface</string>
  <key>NSExtensionPointIdentifier</key><string>com.apple.share-services</string>
</dict>
```

## 4. URL scheme condiviso
Nel `Runner/Info.plist` aggiungi il CFBundleURLScheme
`ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` (richiesto dal plugin per riaprire l'app).

## 5. Nome visualizzato
Già impostato: `CFBundleDisplayName = Beet-It Recipes` (così appare nel menu).

## Lato Flutter — già fatto
`ShareReceiver` ascolta `getInitialMedia()` / `getMediaStream()`, estrae l'URL e
chiama `importFromUrl` mostrando il loader. Nessuna modifica ulteriore serve.

> Nota: la Share Extension si testa solo su un **device/simulatore iOS** (o
> Android), non sul build web.

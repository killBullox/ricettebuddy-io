# RicetteBuddy (iOS)

App iOS/iPadOS per salvare ricette da social/web/foto, pianificare i pasti e
generare liste della spesa, con sync cloud e traduzione automatica.

> **Stato:** scheletro iniziale (v0.1). Codice SwiftUI + SwiftData funzionante come
> punto di partenza. Vedi `docs/ios-app-requirements.md` per i requisiti completi.

## Requisiti di sviluppo
- **macOS + Xcode 15+** (obbligatorio per compilare/eseguire app iOS)
- iOS 17+ come target minimo (usa SwiftData e String Catalogs)

## Come creare il progetto Xcode e aggiungere questi file

Questo pacchetto contiene **solo i file sorgente Swift**, non un progetto `.xcodeproj`
già pronto (va generato da Xcode sul tuo Mac). Passi:

1. Apri **Xcode → File → New → Project… → iOS → App**.
2. Product Name: `RicetteBuddy` · Interface: **SwiftUI** · Language: **Swift** ·
   Storage: **None** (usiamo SwiftData a mano).
3. Salva il progetto **dentro questa cartella** (il repo `ricettebuddy-ios`).
4. In Finder, trascina la cartella `RicetteBuddy/` (Models, App, Features, Resources)
   dentro il navigator di Xcode scegliendo **"Copy items if needed"** e
   **"Create groups"**. Elimina il `ContentView.swift`/`App.swift` generati da Xcode
   se duplicano i nostri (`RicetteBuddyApp.swift`, `ContentView.swift`).
5. Compila ed esegui sul simulatore (`⌘R`).

## Abilitare la sincronizzazione iCloud (F6/F7)
1. Seleziona il target → **Signing & Capabilities → + Capability → iCloud**.
2. Spunta **CloudKit** e crea un container (es. `iCloud.com.tuonome.RicetteBuddy`).
3. Aggiungi anche **Background Modes → Remote notifications** se vuoi push di sync.
4. SwiftData userà automaticamente CloudKit; assicurati che tutte le proprietà dei
   `@Model` abbiano un valore di default o siano opzionali (requisito CloudKit).

## Struttura

```
RicetteBuddy/
  App/         RicetteBuddyApp.swift, ContentView.swift (TabView)
  Models/      Recipe, Ingredient, Step, MealPlanEntry, ShoppingItem (SwiftData)
  Features/
    Recipes/   lista + dettaglio
    Import/    import da URL (parser JSON-LD) + hook fotocamera/social
    MealPlan/  calendario settimanale a slot
    Shopping/  lista spesa + aggregazione ingredienti
    Settings/  lingua, unità, sync
  Resources/   (String Catalog per la localizzazione)
```

## Roadmap
Vedi `docs/ios-app-requirements.md` §8 (MVP → piano pasti/spesa → social+traduzione).

## Note tecniche
- L'estrazione robusta delle ricette (parsing avanzato, structuring AI di video/foto,
  traduzione) andrebbe spostata **lato server** per proteggere le API key e aggiornare
  i parser senza rilasciare nuove build. `RecipeImporter` è predisposto per questo.
- L'import dai social si realizza con una **Share Extension** (target separato da
  aggiungere in Xcode).

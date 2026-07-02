# ADR-0001 — Stack: Flutter + Supabase (iOS prima, poi Android)

**Stato:** Accettata · **Data:** 2026-07-02

## Contesto

RicetteBuddy deve essere pubblicata **prima su iOS, poi su Android**, ma
l'obiettivo dichiarato è avere **entrambe le piattaforme**. Lo scheletro iniziale
(v0.1) era SwiftUI + SwiftData + CloudKit, cioè 100% ecosistema Apple.

Vincoli rilevanti:

- Lo sviluppo avviene su **Windows**. Lo sviluppo iOS nativo (SwiftUI/Xcode)
  richiede un Mac: non compilabile sulla macchina di sviluppo attuale.
- Il progetto è gestito da un team ridotto: mantenere **due UI native** (SwiftUI +
  Compose) raddoppia il costo di ogni schermata.
- Il prodotto richiede **logica server ricca**: parsing web robusto, structuring
  AI di video/foto (OCR), traduzione automatica e la nuova feature creativa
  ("Chef creativo"). Le API key non devono stare sul client.
- I dati sono **relazionali** (ricette ↔ ingredienti ↔ passi ↔ piano pasti ↔
  spesa ↔ dispensa) e la lista della spesa richiede **aggregazioni** su unità di
  misura.

## Decisione

### Client → **Flutter** (un solo codebase Dart per iOS + Android)

- Sviluppabile e testabile **da Windows** (Android in locale; build/firma iOS via
  Mac in cloud — Codemagic / GitHub Actions).
- Un solo codice per entrambe le piattaforme: "iOS prima, poi Android" diventa
  attivare un target, non riscrivere l'app.
- Le feature delicate hanno equivalenti maturi: Share Extension →
  `receive_sharing_intent`, OCR → `google_mlkit_text_recognition`, i18n →
  `flutter_localizations` + ARB.
- Lo scheletro SwiftUI (~900 righe) è archiviato in `legacy/swiftui-starter/`;
  modelli e logica sono riportati in Dart quasi 1:1.

Alternative scartate: **native x2** (costo doppio di UI, iOS non compilabile su
Windows), **React Native** (valido ma meno consistente cross-platform di Flutter),
**Kotlin Multiplatform** (richiede comunque due UI native + setup maggiore).

### Backend → **Supabase**

- **Postgres**: modello relazionale naturale + aggregazioni SQL per la spesa.
- **Edge Functions** (Deno/TypeScript): parsing, structuring AI, traduzione e
  generazione creativa lato server, con API key protette.
- **Auth**: Sign in with Apple + Google out-of-the-box.
- **Storage** per le immagini delle ricette.
- **Row Level Security**: isolamento dei dati per utente.
- **pgvector**: embedding per "profilo gusti" / similarità (feature creativa).
- Offline-first sul client tramite cache locale (Drift/SQLite) + sync verso
  Supabase.

Alternative scartate: **CloudKit** (Apple-only, escluso dal requisito Android),
**Firebase** (NoSQL scomodo per le aggregazioni, lock-in Google), **backend
custom** (troppa infrastruttura da mantenere in questa fase).

## Conseguenze

- La sync non è più "automatica" come CloudKit: va implementata (repository
  offline-first + Realtime/pull da Supabase). Vedi ADR futuri.
- Serve un Mac in cloud nella pipeline CI per le build iOS.
- I caveat CloudKit del vecchio schema non si applicano più al nuovo stack.

## Layout del repository

```
docs/        requisiti + ADR
app/         applicazione Flutter (iOS + Android)
supabase/    migrations SQL + Edge Functions
legacy/      scheletro SwiftUI archiviato (riferimento)
```

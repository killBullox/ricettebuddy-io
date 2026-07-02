# RicetteBuddy

App **iOS + Android** per salvare ricette da social/web/foto, pianificare i pasti,
generare liste della spesa e — con lo "**Chef creativo**" — ricevere idee di ricetta
basate su ciò che hai in dispensa e sui tuoi gusti. Sync cloud, multi-dispositivo,
multilingua con traduzione automatica.

> **Stato:** in ricostruzione su nuovo stack (v0.2). Vedi
> [docs/adr-0001-flutter-supabase.md](docs/adr-0001-flutter-supabase.md) per la
> scelta tecnica e [docs/ios-app-requirements.md](docs/ios-app-requirements.md)
> per i requisiti funzionali (F1–F9 + Chef creativo).

## Stack

- **Client:** Flutter (un codebase per iOS e Android) — sviluppabile da Windows.
- **Backend:** Supabase (Postgres + Auth + Storage + Edge Functions + pgvector).
- **Locale/offline:** cache SQLite (Drift) con sync verso Supabase.

## Struttura del repository

```
docs/        requisiti funzionali + decisioni architetturali (ADR)
app/         applicazione Flutter (iOS + Android)
supabase/    schema DB (migrations SQL) + Edge Functions (parsing/AI/traduzione/creativa)
legacy/      scheletro SwiftUI iniziale, archiviato come riferimento
```

## Funzionalità

| # | Funzionalità |
|---|--------------|
| F1 | Import da social (TikTok, Instagram, Pinterest, Facebook, YouTube) |
| F2 | Import da siti web e blog (parser schema.org/Recipe + fallback AI) |
| F3 | Import da fotocamera (OCR, anche scrittura a mano) |
| F4 | Piano pasti settimanale (colazione/pranzo/spuntino/cena) |
| F5 | Liste della spesa con aggregazione ingredienti |
| F6 | Sincronizzazione cloud |
| F7 | Multi-dispositivo (iPhone + iPad + Android) |
| F8 | Multilingua (25+ lingue) |
| F9 | Traduzione automatica delle ricette importate |
| **C1** | **Chef creativo:** idee di ricetta da dispensa + gusti (ricette salvate fattibili + nuove generate dall'AI) |

## Sviluppo

Prerequisiti: **Flutter SDK 3.x**, **Node 20+** (Supabase CLI), un account Supabase.

```bash
# app Flutter
cd app
flutter pub get
flutter run                 # Android/emulatore locale (iOS: build via Mac/CI)

# backend Supabase
cd supabase
supabase start             # stack locale (Docker)
supabase db reset          # applica le migrations in supabase/migrations
```

Vedi [docs/adr-0001-flutter-supabase.md](docs/adr-0001-flutter-supabase.md) per i
dettagli e le conseguenze operative (build iOS via Mac in cloud, strategia di sync).

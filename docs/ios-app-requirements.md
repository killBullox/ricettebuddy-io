# Requisiti App iOS — "RicetteBuddy" (nome provvisorio)

> Documento di requisiti funzionali e tecnici per un'app iOS/iPadOS di gestione ricette,
> pianificazione pasti e liste della spesa. Basato sull'elenco funzionalità fornito.

**Stato:** bozza v1.0 · **Data:** 2026-07-02 · **Piattaforme target:** iOS + iPadOS

---

## 1. Visione del prodotto

Un'app che permette di **raccogliere ricette da qualsiasi fonte** (social, web, foto di libri/appunti),
**organizzarle**, **pianificare i pasti della settimana** e **generare automaticamente la lista della spesa**,
con **sincronizzazione cloud** su più dispositivi e supporto **multilingua con traduzione automatica**.

Utente tipo: chi cucina in casa, salva ricette da TikTok/Instagram/blog e vuole un unico posto
organizzato, disponibile su iPhone e iPad, sempre sincronizzato.

---

## 2. Funzionalità (dall'elenco fornito)

| # | Funzionalità | Descrizione |
|---|--------------|-------------|
| F1 | Salva ricette dai Social Media | Importa da TikTok, Instagram, Pinterest, Facebook, YouTube |
| F2 | Salva ricette da Siti Web e Blog | Importa da URL di siti e blog di cucina |
| F3 | Salva ricette con la Fotocamera | Foto di libri, ricette stampate o appunti scritti a mano (OCR) |
| F4 | Piano Pasti Settimanale | Colazione, pranzo, spuntino, cena |
| F5 | Liste della Spesa | Liste intelligenti dai piani pasti, ordinate per corsia o per ricetta |
| F6 | Sincronizzazione Cloud | Tutto salvato in cloud, nessuna ricetta persa |
| F7 | Multi-dispositivo | iPhone e iPad in contemporanea |
| F8 | Oltre 25 lingue | Inglese, olandese, francese, tedesco, spagnolo, ecc. |
| F9 | Traduzione Automatica | Le ricette importate vengono tradotte nella lingua preferita |

---

## 3. Dettaglio requisiti funzionali

### F1 — Import da Social Media
- Ingresso tramite **Share Extension** iOS: l'utente usa "Condividi" da TikTok/Instagram/ecc. → "Salva in RicetteBuddy".
- Anche incolla-URL diretto nell'app.
- Il sistema deve estrarre: titolo, ingredienti, passaggi, tempo, porzioni, immagine di copertina.
- Per i video (TikTok/YouTube): estrazione da **descrizione + eventuali sottotitoli/trascrizione audio**;
  se il testo non contiene la ricetta strutturata, usare un passo AI di "structuring" (vedi §6.3).
- **Requisiti legali:** rispettare i ToS delle piattaforme; salvare **link alla fonte originale** e attribuzione.
  Non scaricare/ripubblicare contenuti protetti oltre l'uso personale.

### F2 — Import da Siti Web e Blog
- Parsing di **schema.org/Recipe** (JSON-LD) quando presente — copre la maggioranza dei food blog.
- Fallback: estrazione euristica del contenuto + structuring AI.
- Rimozione automatica di banner cookie, pubblicità e "storytelling" prima degli ingredienti.

### F3 — Import da Fotocamera (OCR)
- Scatto o selezione da galleria di 1+ pagine.
- OCR (VisionKit `DataScannerViewController` / `VNRecognizeTextRequest`) incluso riconoscimento
  di **scrittura a mano**.
- Structuring AI del testo grezzo in campi ricetta.
- Editor manuale post-OCR per correggere.

### F4 — Piano Pasti Settimanale
- Vista calendario settimanale con 4 slot per giorno: **colazione, pranzo, spuntino, cena**.
- Drag & drop di una ricetta su uno slot.
- Porzioni regolabili per slot (scala automaticamente le quantità).
- Vista giornaliera e settimanale; navigazione tra settimane.

### F5 — Liste della Spesa
- Generazione automatica dagli slot del piano pasti su un intervallo scelto.
- **Aggregazione ingredienti** (es. "200 g farina" + "300 g farina" = "500 g farina") con
  normalizzazione unità di misura.
- Due modalità di ordinamento: **per corsia del supermercato** (categoria) o **per ricetta**.
- Check-off manuale, aggiunta voci libere, condivisione lista.

### F6 — Sincronizzazione Cloud
- Ogni modifica propagata a tutti i dispositivi dell'utente.
- Funzionamento **offline-first**: modifiche locali salvate e sincronizzate al ritorno online.
- Gestione conflitti (last-write-wins a livello campo, o merge dove sensato).

### F7 — Multi-dispositivo (iPhone + iPad)
- Layout adattivo (SwiftUI + size classes); su iPad vista a due colonne (lista + dettaglio).
- Stesso account = stessi dati.

### F8 — Multilingua (25+ lingue)
- Localizzazione UI tramite String Catalogs (`.xcstrings`).
- Lingua preferita selezionabile in impostazioni.

### F9 — Traduzione Automatica
- Le ricette importate in lingua diversa da quella preferita vengono tradotte.
- Mantenere **testo originale** + traduzione (toggle per vedere l'originale).
- Traduzione on-demand anche per ricette esistenti.

---

## 4. Schermate principali (information architecture)

1. **Onboarding / Login** — scelta lingua, creazione account, permessi (camera, notifiche).
2. **Le mie ricette** — griglia/lista con ricerca, filtri (categoria, tempo, tag), preferiti.
3. **Dettaglio ricetta** — immagine, ingredienti (con scala porzioni), passaggi, fonte, azioni
   (aggiungi al piano, aggiungi alla spesa, traduci, condividi, modifica).
4. **Importa** — hub con: incolla URL, scansiona con fotocamera, e la Share Extension esterna.
5. **Piano pasti** — calendario settimanale con slot.
6. **Lista della spesa** — liste attive, aggregata/per ricetta, check-off.
7. **Impostazioni** — account, lingua, unità di misura, sync, abbonamento.

---

## 5. Requisiti non funzionali

- **Performance:** apertura app < 2 s; import da URL con feedback entro 1 s e risultato entro pochi secondi.
- **Offline:** navigazione e modifica ricette salvate senza rete.
- **Privacy/GDPR:** consenso, esportazione ed eliminazione dati account; privacy policy.
  Rispetto delle **App Store Review Guidelines** (in particolare uso di contenuti di terzi).
- **Accessibilità:** Dynamic Type, VoiceOver, contrasto AA.
- **Sicurezza:** autenticazione sicura (Sign in with Apple consigliato), dati in transito su TLS,
  segreti mai nel client.
- **Versione minima iOS:** iOS 17+ (consigliato per String Catalogs e API moderne).

---

## 6. Architettura tecnica (proposta)

### 6.1 Client
- **SwiftUI** + architettura MVVM (o TCA se il team la conosce).
- **Persistenza locale:** SwiftData (iOS 17+) o Core Data.
- **Share Extension** per l'import dai social.
- **VisionKit** per OCR.

### 6.2 Backend / Cloud sync — opzioni a confronto

| Opzione | Pro | Contro | Quando sceglierla |
|---|---|---|---|
| **CloudKit (iCloud)** | Zero costi server, sync nativa, privacy, Sign in with Apple | Solo ecosistema Apple (no Android/web futuro), logica server limitata | **Consigliata** se il target resta solo Apple e si vuole time-to-market rapido |
| **Supabase / Firebase** | Multipiattaforma, auth+DB+storage, funzioni serverless per parsing/AI | Costi, gestione infrastruttura, privacy da presidiare | Se si prevede Android/web o logica server ricca |
| **Backend custom (es. FastAPI)** | Massimo controllo, ideale per pipeline import/AI | Più lavoro e manutenzione | Se le pipeline di import/traduzione diventano il cuore del prodotto |

> **Raccomandazione:** partire con **CloudKit** per la sync (F6/F7) + un piccolo servizio serverless
> **solo** per i compiti che non possono stare sul client (parsing web robusto, structuring AI, traduzione).
> Migrabile in seguito a Supabase se serve il multipiattaforma.

### 6.3 Servizi lato server (necessari per F1–F3, F9)
- **Estrattore ricette web:** parsing JSON-LD `schema.org/Recipe` + fallback euristico/AI.
- **Structuring AI:** da testo grezzo (video/OCR) → struttura ricetta (LLM con output strutturato).
- **Traduzione:** API di traduzione (o LLM) con cache per costo/latenza.
- Questi girano lato server per proteggere le API key ed evitare aggiornamenti client per ogni fix di parsing.

### 6.4 Modello dati (essenziale)
- `Recipe`: id, titolo, immagine, sourceURL, sourceType, linguaOriginale, tempoPrep, tempoCottura, porzioni, tags[], createdAt, updatedAt
- `Ingredient`: id, recipeId, testoGrezzo, quantità, unità, nomeNormalizzato, categoriaCorsia
- `Step`: id, recipeId, ordine, testo
- `MealPlanEntry`: id, data, slot(colazione/pranzo/spuntino/cena), recipeId, porzioni
- `ShoppingList` / `ShoppingItem`: id, nome, quantità, unità, categoria, checked, origine(recipeId?)
- `Translation`: recipeId, lingua, campiTradotti
- `User`: id, linguaPreferita, unitàMisura, abbonamento

---

## 7. Monetizzazione (da confermare)
- **Freemium** con StoreKit 2: gratis un numero limitato di ricette/import; abbonamento per import illimitati,
  traduzione e sync avanzata. Da definire con il committente.

---

## 8. Roadmap suggerita (fasi)

**MVP (Fase 1)**
- Import da URL (F2) con parser JSON-LD
- Ricettario + dettaglio (CRUD)
- Sync CloudKit (F6/F7)
- Localizzazione UI base (F8)

**Fase 2**
- Piano pasti (F4)
- Liste della spesa con aggregazione (F5)
- Import fotocamera/OCR (F3)

**Fase 3**
- Import social + Share Extension (F1)
- Traduzione automatica (F9)
- Monetizzazione, rifiniture, ampliamento lingue

---

## 9. Rischi e questioni aperte

- **Legale:** l'import da social/YouTube deve rispettare ToS e copyright — validare con consulenza legale.
- **Affidabilità parsing:** i food blog variano molto; serve fallback AI e possibilità di correzione manuale.
- **Costi AI/traduzione:** prevedere caching e limiti per contenere i costi.
- **Naming/branding:** "RicetteBuddy" è un segnaposto — definire nome e identità.
- **Scelta backend:** CloudKit vs Supabase impatta il futuro multipiattaforma — decidere presto.

---

## 10. Nota sul repository

Questo repository (`tradingbuddy-render`) contiene attualmente un bot di trading in Python e **non**
è un progetto Xcode. Questo documento definisce i requisiti; per lo sviluppo dell'app iOS servirà un
**progetto Xcode/SwiftUI separato** (idealmente in un repository dedicato). Posso generare lo scheletro
SwiftUI iniziale su richiesta.

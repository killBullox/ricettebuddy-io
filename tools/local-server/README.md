# Server locale di sviluppo

Server Node che serve la build web di Flutter **e** fornisce un'API reale con
**import da GialloZafferano** (copertina, ingredienti, procedimento passo-passo
con foto, galleria, video) e **persistenza su file** (`recipes.json`).

Serve per provare l'app da browser in modalità demo senza Supabase: un'app web
non può leggere GialloZafferano direttamente (CORS), quindi l'import gira qui
lato server. In produzione la stessa logica va nelle Edge Functions Supabase
(`supabase/functions/analyze-feed`, `import-recipe`).

## Uso

```bash
cd app && flutter build web            # genera app/build/web
cd ../tools/local-server && node app_server.js   # http://localhost:8080
```

## API

- `GET  /api/recipes` · `GET /api/recipes/:id`
- `POST /api/recipes` (create) · `PUT /api/recipes/:id` · `DELETE /api/recipes/:id`
- `POST /api/import-url` `{ url }` — importa una singola ricetta
- `POST /api/analyze` `{ diets, limit, pages }` — naviga il listato vegane di GZ
  e importa le ricette conformi ai regimi

`gz_parser.js` contiene il parser reale (JSON-LD + HTML per foto-passo e video).

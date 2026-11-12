# Halal Assistant

A cross-platform mobile app that helps Muslims understand food ingredients.
Scan a product barcode or type an ingredient list, and the app explains which
ingredients raise no concern, which are clearly prohibited and which need to
be verified — and why.

> **Important.** Halal Assistant gives a preliminary, ingredient-based
> assessment. It is not a fatwa, a religious ruling or a halal certificate.
> Absence of a halal certificate does not automatically mean that a product
> is Haram.

## University requirements

| Requirement | How it is met |
|---|---|
| Cross-platform mobile app (Flutter) | [`mobile/`](mobile) — one Flutter codebase for Android and iOS (also builds for web) |
| Mobile communicates with a server | [`backend/`](backend) — FastAPI REST server; every result shown in the app comes from it over HTTP (Dio) |
| State management (BLoC) | `flutter_bloc` throughout: one bloc per feature, with events and states |
| Pushed to GitHub | This repository |

## Features

- **Home dashboard** — statistics, recent checks, and an explanation of the four results
- **Barcode scanner** — the camera reads a barcode (`mobile_scanner`), the backend looks it up in Open Food Facts and analyses its ingredients; the barcode can also be typed
- **Manual ingredient checker** — type a product name and an ingredient list
- **Analysis result** — overall status, an explanation for every ingredient, a recommended next step, and certification information shown separately
- **Ingredient dictionary** — the knowledge database with search, and a details screen per ingredient
- **History** — every check is stored in SQLite on the server; open or delete past results

### The four results

| Result | Meaning |
|---|---|
| **Halal indicated** | No known problematic ingredients were identified. Preliminary, not a certificate. |
| **Haram indicator** | A clearly identified prohibited ingredient or origin was found, and the result names it. |
| **Needs verification** (mashbooh) | Some ingredients have an uncertain origin; the result says what to verify. |
| **Insufficient information** | Ingredients are missing, incomplete or could not be reliably identified. |

### How the analysis decides

The rules are transparent and live in
[`backend/app/services/analyzer.py`](backend/app/services/analyzer.py); the
knowledge database is
[`backend/app/data/ingredients.json`](backend/app/data/ingredients.json).

- An additive whose source is not stated — E471, E322, E422, gelatin (E441) —
  is **never** reported as Haram from its code alone. It is "needs verification".
- It becomes prohibited only when the label itself declares a prohibited
  source (`pork gelatin`, `gelatin (pork)`, `lard`).
- It becomes "no known concern" when the label declares a plant, microbial or
  synthetic source (`soy lecithin`, `E471 (vegetable)`).
- Ingredients that are not in the database are reported as "not in database",
  never silently approved. If most of a list cannot be identified, the result
  is "insufficient information".
- Certification is reported separately. The app has no source that can
  confirm a certificate, so it only ever reports `UNKNOWN` or `NOT_FOUND`; it
  never invents a certificate. `VERIFIED` and `EXPIRED` exist in the model for
  a future verified source.

The knowledge database is a starter set of about 30 entries, not a complete
religious ruling database, and it is in English: ingredient lists in other
languages are mostly reported as "insufficient information".

## Architecture

```
Flutter app                                   FastAPI backend
───────────                                   ───────────────
Screens ──events──▶ Blocs ──▶ HalalRepository ──▶ ApiClient (Dio) ══HTTP══▶ Routers ──▶ Analyzer ──▶ SQLite
   ▲                  │                                                        │
   └──────states──────┘                                                        └──▶ Open Food Facts API
```

```
mobile/lib/
  main.dart, app.dart
  core/
    constants/api_config.dart      backend address (the one place to change it)
    network/api_client.dart        Dio wrapper and error handling
    theme/, widgets/               Material 3 theme, shared widgets
  features/
    home/                bloc/ (DashboardBloc, NavigationCubit), screens/, widgets/
    scanner/             bloc/ (ScannerBloc), screens/
    ingredient_checker/  bloc/ (IngredientCheckerBloc), screens/, models/, repository/
    product_details/     screens/ (analysis result)
    history/             bloc/ (HistoryBloc), screens/
    ingredients/         bloc/ (IngredientsBloc, IngredientDetailsBloc), screens/

backend/
  app/
    main.py              app factory, CORS, /health
    database.py          SQLite engine and sessions
    models.py            tables: ingredients, product_checks, product_check_details
    schemas.py           request and response bodies
    routers/             products.py, ingredients.py, history.py
    services/            analyzer.py, checks.py, open_food_facts.py
    data/                ingredients.json, common_ingredients.json
  tests/                 API and rule tests
```

## API

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Backend status |
| GET | `/api/products/barcode/{barcode}` | Look the product up in Open Food Facts, analyse it, save it to history |
| POST | `/api/analyze` | Analyse a manually entered list: `{"product_name": "...", "ingredients": "..."}` |
| GET | `/api/ingredients` | Ingredient knowledge database (`?q=` to search) |
| GET | `/api/ingredients/{code}` | One ingredient, by code (`lecithin`) or E-number (`E322`) |
| GET | `/api/history` | Checked products, newest first |
| GET | `/api/history/{id}` | One saved check |
| POST | `/api/history` | Analyse and save a check |
| DELETE | `/api/history/{id}` | Delete a saved check |
| GET | `/api/dashboard` | Number of checks, counts per result, recent checks |

Both analysis endpoints save the check to history; add `?save=false` to skip
that. Interactive documentation is at `http://localhost:8000/docs` while the
backend is running.

## Running

### 1. Backend (Python 3.11+)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The SQLite database (`backend/halal_assistant.db`) and the ingredient
dictionary are created automatically on first start.

### 2. Mobile app (Flutter 3.50+)

```bash
cd mobile
flutter pub get
flutter run
```

The backend address is set in
[`mobile/lib/core/constants/api_config.dart`](mobile/lib/core/constants/api_config.dart):

| Where the app runs | Address used |
|---|---|
| Android emulator | `http://10.0.2.2:8000` (automatic) |
| iOS simulator, web | `http://localhost:8000` (automatic) |
| Physical phone | The computer's address on the local network, passed at build time |

For a physical phone, connect it to the same Wi-Fi as the computer and run:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

(replace `192.168.1.10` with the computer's address; on macOS,
`ipconfig getifaddr en0` prints it).

## Testing

```bash
cd backend && source .venv/bin/activate && pytest     # API, rules, persistence
cd mobile && flutter analyze && flutter test          # static analysis, bloc tests
```

The backend tests cover, among other things: `/health`, manual analysis, the
known-ingredient rules, safe handling of unknown ingredients, that E471 is not
classified as Haram, that a missing certificate does not mean Haram, that
history is saved, and that the database persists across restarts. They use a
fake Open Food Facts client, so they need no network.

### Testing the barcode scanner

Camera scanning needs a real camera, so test it on a physical phone:

1. Start the backend and run the app on the phone with `API_BASE_URL` set as above.
2. On the home screen tap **Scan Barcode** and allow camera access.
3. Point the camera at the barcode of a packaged food product.

Without a camera (simulator, emulator, web) the scanner screen shows a message
and the barcode can be typed into the field below it, for example
`5000159407236` or `5449000000996`. A barcode that Open Food Facts does not
know, such as `0000000000000`, shows the "Product not found" message with a
button to enter the ingredients manually.

## Data sources

- Product data: [Open Food Facts](https://world.openfoodfacts.org), a
  community database. Its ingredient lists can be incomplete or wrong.
- Ingredient knowledge: general food-science information about E-numbers and
  their possible origins. For a definitive answer, consult a qualified scholar
  or a recognised halal certification body.

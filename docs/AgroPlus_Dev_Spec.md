# AgroPlus — Development Specification

This document is the build spec for AgroPlus. Use it as the source of truth for architecture, schema, and scope decisions. Current task: build authentication, database schema, and the dashboard screen.

## 1. Project Overview

AgroPlus is a mobile app that recommends crops to farmers based on soil (N, P, K, pH) and climate data, and estimates profit for the recommended crop. Built solo, fixed 12-week timeline, local development only (no cloud deployment yet).

**Core loop:** Farmer enters soil readings from 5 points on their land (4 corners + center) → app averages into a composite reading, auto-fetches climate data → backend ML model returns top-3 crop recommendations → profit is calculated from static yield/price lookup tables → an LLM generates a plain-language explanation.

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart) |
| Backend API | FastAPI (Python) |
| Primary ML models | XGBoost + Random Forest (server-side, online) |
| Offline ML model | Keras/TensorFlow MLP → TensorFlow Lite (on-device) — **must be trained separately; XGBoost/RF cannot convert to TFLite** |
| Offline integration | `tflite_flutter` package |
| Database | PostgreSQL |
| DB management | pgAdmin (local) |
| Auth | JWT (access + refresh tokens) |
| Explanation LLM | OpenAI API |
| Training dataset | Kaggle Crop Recommendation Dataset (2,200 rows, 22 crops, 7 features: N, P, K, temperature, humidity, pH, rainfall) |
| Localization | English / Bangla toggle (Flutter `intl` or `easy_localization`) |
| Weather data | Open-Meteo (forecast + historical archive) — free, no API key |
| GPS coordinates | `geolocator` Flutter package (device-native, no external API) |
| Coordinates → district | Local nearest-district lookup table (no external API — see §3) |
| Manual location entry | Static dropdown of Bangladesh's 64 districts |
| Environment | Local-only for now; no cloud deployment |

## 3. Database Schema

```
FARMER {
  uuid id PK
  string name
  string email UNIQUE
  string phone
  string password_hash
  string home_address
  timestamp created_at
}

FARM {
  uuid id PK
  uuid farmer_id FK -> FARMER.id
  string farm_name
  string location
  float size_acres
}

RECOMMENDATION {
  uuid id PK
  uuid farm_id FK -> FARM.id
  timestamp created_at
  float composite_n
  float composite_p
  float composite_k
  float composite_ph
  string top_crop
  float confidence
  float yield_estimate
  float net_profit
}

SAMPLE_POINT {
  uuid id PK
  uuid recommendation_id FK -> RECOMMENDATION.id
  string point_label      -- e.g. "corner_1_near_water", "center"
  float n
  float p
  float k
  float ph
}

DISTRICT {
  uuid id PK
  string name              -- one of Bangladesh's 64 districts
  float center_lat
  float center_lng
}
```

Relationships: `FARMER (1) --- (many) FARM`, `FARM (1) --- (many) RECOMMENDATION`, `RECOMMENDATION (1) --- (many) SAMPLE_POINT`. `FARM.location` stores the resolved `DISTRICT.name` (from either manual selection or GPS lookup) — this is the same key used by the `crop_region_price` and `crop_region_yield` lookup tables, so no translation layer is needed between location and profit calculation.

### Location & weather architecture

- **Weather (temperature, humidity, rainfall):** Open-Meteo forecast + historical archive API. No API key, free for non-commercial use — call it server-side once a district/coordinates are known.
- **GPS auto-detect:** `geolocator` Flutter package reads device coordinates directly — no external API involved.
- **Coordinates → district name:** Google Places / Open-Meteo reverse geocoding were both ruled out (Open-Meteo has no reverse geocoding yet; Google Places is built for open-world search and needs paid billing). Instead, seed the `DISTRICT` table with each district's center coordinates once, and resolve GPS coordinates to a district via a simple nearest-center distance calculation — no external call, works offline, and matches the same 64-district set your price/yield tables already use.
- **Manual location entry:** a dropdown backed by the `DISTRICT` table, not a live search API.

Design rationale:
- `SAMPLE_POINT` is a child of `RECOMMENDATION`, not `FARM` — soil readings drift season to season, so each recommendation run stays self-contained and re-explainable.
- `size_acres` lives on `FARM` — land size is stable; only soil profile and derived outputs change between runs.
- Profit/yield numbers are computed from static lookup tables (to be added: `crop_region_price`, `crop_region_yield`, sourced from Bangladesh DAM for prices and BBS/DAE for yield) — never inferred by the LLM.

Use Alembic for migrations from the start — do not hand-edit schema later.

## 4. Full Feature Plan

Priority legend: **P0** = MVP core loop (must work for demo). **P1** = real product value, built once P0 is solid. **P2** = documented future work only.

### Authentication
- JWT login/register (email + password) — **P0**
- Token-protected API endpoints — **P0**
- Token refresh handling in Flutter — **P1**

### Farmer & Farm Management
- Farmer profile (name, phone, home address) — **P0**
- Add/edit/delete a farm (name, location, size in acres) — **P0**
- Multiple farms per farmer — **P0**
- Farms list dashboard (card view) — **P0**
- Farm detail screen (info + recommendation history) — **P0**

### Location Input
- Manual location entry (baseline) — **P0**
- Real-time GPS auto-detect with permission prompt — **P1**
- Reverse geocoding GPS → region name — **P1**

### Soil Input & Crop Recommendation
- 5-point soil input form (N, P, K, pH per point) — **P0**
- Auto-fetch temperature, humidity, rainfall — **P0**
- Composite averaging of 5 points → single feature vector — **P0**
- XGBoost/RF inference via FastAPI → top-3 crops + confidence — **P0**
- Sample-count scaling by land size (3/5/grid) — **P1**
- Zone-based split recommendation — **P2**

### Profit & Yield Estimation
- Static yield table (crop × region) — **P0**
- Static price table (crop × region), sourced from DAM — **P0**
- Gross profit calculation (yield × price × land size) — **P0**
- Net profit calculation (gross − input cost) — **P1**
- Input budget field used in net profit — **P1**

### AI Explanation Layer
- Plain-language explanation via OpenAI API — **P0**
- BAMIS advisory knowledge base collection — **P1**
- Grounding explanation in BAMIS advisory snippet (RAG-lite) — **P1**
- Caching explanations per crop/region — **P1**
- Explanation generated in selected language (en/bn) — **P1**

### Offline Mode
- Small Keras MLP mirrored from XGBoost — **P1**
- TFLite conversion + `tflite_flutter` integration — **P1**
- Connectivity check (online → full pipeline, offline → on-device crop only) — **P1**
- Cached/template explanation for offline results — **P1**

### Recommendation History
- Save every recommendation (inputs + outputs) per farm — **P0**
- Recommendation history list (newest first) — **P0**
- Recommendation detail view — **P0**

### Localization (en/bn)
- Language toggle in settings — **P1**
- UI strings translated — **P1**
- Bangla crop/region names — **P1**

### Data & Model Foundation
- Train XGBoost + Random Forest on Kaggle dataset — **P0**
- Local Postgres schema — **P0**
- Multi-dataset training experiment (schema-aligned, holdout-validated) — **P2**, time-boxed, only after MVP

### Explicitly out of scope for now
- Cloud deployment
- Zone-based split recommendation (documented future work)

## 5. Current Increment: Auth + Schema + Dashboard

This is the active build target. Everything below should be implemented first.

### Backend structure (FastAPI)
```
backend/
├── app/
│   ├── main.py                  # FastAPI app entrypoint
│   ├── core/
│   │   ├── config.py            # env vars, DB URL, JWT secret
│   │   ├── security.py          # password hashing, JWT encode/decode
│   │   └── dependencies.py      # get_current_farmer() — verifies JWT on protected routes
│   ├── models/
│   │   └── farmer.py            # SQLAlchemy model
│   ├── schemas/
│   │   ├── auth.py              # Pydantic: RegisterRequest, LoginRequest, TokenResponse
│   │   └── farmer.py            # Pydantic: FarmerOut, FarmerUpdate
│   ├── routers/
│   │   ├── auth.py              # /auth/register, /auth/login, /auth/refresh
│   │   └── farmers.py           # /farmers/me
│   ├── db/
│   │   ├── session.py           # SQLAlchemy engine/session
│   │   └── base.py
│   └── alembic/                 # migrations
├── requirements.txt
└── .env
```

Key libraries: `fastapi`, `sqlalchemy`, `alembic`, `passlib[bcrypt]`, `python-jose[cryptography]`, `psycopg2-binary`, `pydantic-settings`.

### Auth endpoint contract
```
POST /auth/register  { name, email, phone, password }        → 201, TokenResponse
POST /auth/login      { email, password }                     → 200, TokenResponse
POST /auth/refresh    { refresh_token }                        → 200, { access_token }
GET  /farmers/me      Authorization: Bearer <access_token>     → 200, FarmerOut
```
`TokenResponse = { access_token, refresh_token, token_type: "bearer" }`. Access token short-lived (~30 min), refresh token longer-lived (~7–30 days). Every route under `/farms`, `/recommendations`, etc. depends on a single reusable `get_current_farmer` dependency — write it once, apply everywhere.

### Flutter structure
```
lib/
├── main.dart                    # app entry; checks secure storage for saved token → Dashboard or Login
├── core/
│   ├── api_client.dart          # http/dio wrapper, attaches Bearer token, handles 401 → refresh
│   └── secure_storage.dart      # wraps flutter_secure_storage for token get/set/clear
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── auth_provider.dart   # holds auth state, calls api_client, exposes isLoggedIn
│   └── dashboard/
│       ├── dashboard_screen.dart    # farmer header + farms list
│       └── farm_card.dart
```
State management: `Provider` (or `Riverpod` if already familiar) — avoid Bloc, unnecessary ceremony at this scale. Token storage: `flutter_secure_storage` only — never `SharedPreferences` for credentials.

### Dashboard screen — first cut
- Header: farmer name (from `/farmers/me`)
- Empty state: "You haven't added a farm yet" + prominent "+ Add farm" button
- Once farms exist: scrollable card list (name, location, size, last recommendation date) + floating "+ Add farm" action

### Build order
1. Postgres: create the `farmer` table via Alembic migration.
2. FastAPI: `core/security.py` (password hashing + JWT functions) — unit test in isolation.
3. FastAPI: `/auth/register` and `/auth/login` — verify with curl/Postman before touching Flutter.
4. FastAPI: `get_current_farmer` dependency + `/farmers/me` as the first protected route.
5. Flutter: `api_client.dart` + `secure_storage.dart` (plumbing before UI).
6. Flutter: Login screen wired to `/auth/login`, storing tokens on success.
7. Flutter: Register screen wired to `/auth/register`.
8. Flutter: Dashboard screen calling `/farmers/me`, showing the empty state.

End state for this increment: a real account can be created, logged into, and lands on a working (if empty) dashboard.

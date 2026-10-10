# AgroPlus — Explanation, Budget Check, Weather Forecast & Multi-Cropping Rotation

Four features for this increment. Parts 1–3 are small, self-contained additions to systems that already exist. Part 4 (multi-cropping + rotation) is the large one — it touches the land form, the recommendation pipeline, and `crop_economics`.

---

## Part 1 — Recommendation Explanation ("Why this crop?")

### What "explanation" means here
No SHAP or other per-instance model introspection — that's a real dependency increase for a thin payoff. An explanation is: this land's actual N/P/K/pH/temperature/humidity/rainfall compared against the typical range for the crop in question (computed from the Kaggle training dataset, grouped by crop label), plus the model's global feature importances (which inputs the ensemble weighs most heavily overall, across all crops — not specific to this one prediction). The chat agent turns that grounded data into a natural-language answer. It never explains from general agronomy knowledge — same "only state numbers from a tool call" discipline the chat agent already follows everywhere else.

This also finally resolves the `get_explanation` TODO left in `recommendation_service.py`'s module docstring ("deferred to a later increment" — the OpenAI integration it was waiting on now exists).

### Backend
New function in `recommendation_service.py`:
```
get_recommendation_explanation(crop, n, p, k, temperature, humidity, ph, rainfall) -> dict
    -> {
         crop,
         feature_comparison: [
           { feature: "N", farm_value, typical_min, typical_max, typical_mean, in_range: bool },
           ... one entry per feature in FEATURE_COLUMNS
         ],
         model_feature_importance: [ { feature, importance }, ... ]   # global, xgb_model.feature_importances_
       }
```
`typical_min/max/mean` computed once per crop label from `Crop_recommendation.csv` (the same training CSV the model was built from) and cached alongside the model artifacts — same lazy-load-once pattern `_load_models()` already uses.

New chat tool `get_recommendation_explanation(crop)`:
- Fetches the land's soil reading + live weather (same two calls `get_other_crop_options` already makes)
- Calls the function above
- Returns the structured comparison; the agent phrases it in prose (e.g. "Your phosphorus (46.7) sits inside rice's typical 35–55 range, which helped it score well. Your pH of 5.5 is at the low end of rice's usual 5.5–7 band.")

### Flutter
No new screen. A "Why this crop?" text button on `crop_harvest_detail_screen.dart` (under the season/yield cards) navigates to the chat screen for that land with the message `"Why do you recommend {crop} for my land?"` pre-filled and auto-sent — reuses the existing chat screen and the same send mechanism the quick chips already use. No new UI component.

### Build order
1. Backend: cache per-crop feature stats from the training CSV at model-load time.
2. Backend: `get_recommendation_explanation()`.
3. Backend: register the chat tool + dispatch case.
4. Flutter: "Why this crop?" button → navigates to chat, auto-sends the question.

---

## Part 2 — Budget vs. Cost Check

### Behavior
Every land already has a `budget` (BDT). Every crop already resolves a `total_cost` via `get_crop_detail` — but that figure never reached the saved top-3 (`RecommendationCrop` only stores `yield_estimate`/`net_profit`), so there's nothing to compare against on the list screen today. Wire it through and surface the comparison on both the crop list and crop detail screens.

### Backend
- `RecommendationCrop` gains `total_cost: float | None` — same nullability rule as `yield_estimate`/`net_profit` (null only when the crop has no economics row).
- `get_profit_estimate()` already computes `avg_cost * size_acres` internally but never returns it — add `"total_cost": avg_cost * size_acres` to its result dict.
- `upsert_point` (`recommendations.py`) stores `total_cost` on each saved `RecommendationCrop`, right next to where it already stores `yield_estimate`/`net_profit`.
- `RecommendationCropOut` schema gains `total_cost: float | None`.
- `CropDetailOut` already has `total_cost`, and the endpoint already loads the land's `budget` via `_get_owned_farm` — no new backend field needed there. **Decision:** push the over-budget comparison to Flutter as pure display logic, the same way `net_profit < 0 → red styling` is already handled client-side rather than as a server-computed flag.

### Migration
One nullable `Float` column on `recommendation_crop`.

### Flutter
- `RecommendedCrop` (`farm_provider.dart`) gains `totalCost: double?`.
- `RecommendationListScreen` tile: when `crop.totalCost != null && crop.totalCost! > land.budget`, show a small "Over budget" warning chip next to the confidence percentage. `budget` gets threaded in as a constructor param from `farm_screen.dart`, which already holds the full land record.
- `crop_harvest_detail_screen.dart`: in the "Profit estimate" card, if `detail.totalCost > budget`, show one warning line above the total-cost row — "This exceeds your budget of {budget} BDT by {difference} BDT" — styled with the same warning color the negative-net-profit case already uses.

### Build order
1. Migration + model column.
2. `get_profit_estimate` returns `total_cost`.
3. `upsert_point` persists it.
4. Schema + Flutter model field.
5. Thread `budget` from `farm_screen.dart` into both screens.
6. Warning UI in both screens.

---

## Part 3 — Weather Forecast

### Behavior
"Live conditions" today shows one current snapshot (it calls Open-Meteo's forecast endpoint but only ever reads the `current` block). Add a short forecast strip — next 5–7 days, date + high/low temp + rain — below it, and a matching chat tool so the agent can answer "will it rain this week" grounded in real data instead of declining to answer.

### Backend
`weather_service.py` gains:
```
fetch_forecast(lat, lng, days=7) -> list[dict]
    -> [{ date, temp_max_c, temp_min_c, precipitation_mm }, ...]
```
via Open-Meteo's `daily` parameter set (`temperature_2m_max`, `temperature_2m_min`, `precipitation_sum`) — same `httpx.AsyncClient` + timeout + `WeatherServiceError` pattern `fetch_current_conditions` already uses.

New endpoint, same shape as the existing conditions route:
```
GET /farms/{farm_id}/forecast
    -> [ForecastDayOut]   -- date, temp_max_c, temp_min_c, precipitation_mm
```

New chat tool `get_weather_forecast()` — fetches the same data for the land's district.

### Flutter
- `farm_provider.dart`: `loadForecast()` + `List<ForecastDay> forecast`.
- New `weather_forecast_card.dart`: horizontal scroll, one column per day (short weekday label, high/low, rain mm), placed directly below `live_conditions_card.dart` on the land profile screen.

### Build order
1. Backend: `fetch_forecast()`.
2. Backend: `/farms/{farm_id}/forecast` endpoint + schema.
3. Backend: chat tool.
4. Flutter: provider method + model.
5. Flutter: forecast card, wired into the land profile screen.

---

## Part 4 — Multi-Cropping (Double/Triple) & Rotation Constraint

The large piece. Three tied-together changes: (a) a land-level choice of single/double/triple cropping, (b) a hard agronomic rule — a crop can't be grown more than twice in a row on the same land — enforced everywhere crops get ranked, and (c) the two-slot crop-history field that rule needs as input.

### 4.1 — Cropping history on the land form

Two new optional fields, same dropdown-field pattern already used for soil type / water availability / target season in `add_farm_modal.dart`:
- **Last crop harvested** → `previous_crop_1`
- **Second-last crop harvested** → `previous_crop_2`

Options: the 8 `SUPPORTED_CROPS` + "None / first cultivation" (stored as `null`). Deliberately scoped to `SUPPORTED_CROPS` — the rotation rule and the economics data only reason about those 8, so a crop outside that list can't be meaningfully tracked here.

`FarmCreate` / `FarmUpdate` / `FarmOut` gain `previous_crop_1: str | None`, `previous_crop_2: str | None`. Two new nullable columns on `farm`. Editable through the same add/edit modal already in place (`AgroPlus_History_And_Edit_Spec.md` — no new modal).

### 4.2 — Cropping pattern on the land form

Third new field: **Cropping pattern** — single-select, `"single" | "double" | "triple"`, default `"single"`. Same form, same pattern. `Farm.cropping_pattern` column, `String` with a default and a `CHECK` constraint, same style as `SOIL_TYPES`/`TARGET_SEASONS`.

When `"single"` — the default, and every existing land until edited — **behavior is unchanged from what's live today.** Double/triple only activate the logic below.

### 4.3 — Season classification for SUPPORTED_CROPS

Building a seasonal plan needs to know which of Bangladesh's three growing seasons (Rabi / Aus / Aman — the same three values `target_season` already uses) each crop belongs to. BAMIS's `season_label` text is already captured per `crop_economics` row (e.g. `"Kharif-2 (Jul - Dec)"`) — it just isn't structured yet.

- New `crop_economics.season` column: `"Rabi" | "Aus" | "Aman" | null`.
- `seed_crop_economics.py` gains a keyword classifier (Rabi/Boro → Rabi, Aus/Kharif-1 → Aus, Aman/Kharif-2 → Aman) applied once per row at seed time, right where `season_label` is already captured.
- **Important nuance:** `crop_economics` keeps variety rows separately (rice has boro/aman/local/hybrid variants with different `season_label`s), so **the same crop name can legitimately land in more than one season bucket** — e.g. rice's boro variety → Rabi, rice's aman variety → Aman. That's agronomically correct (rice really is grown in both seasons via different varieties in Bangladesh), so season bucketing happens at the `(crop, variety)` row level. The rotation rule in 4.4, by contrast, counts at the **crop-name level only** — matching how `previous_crop_1/2` are recorded (crop names, not varieties). A plan can legitimately place "rice" in two different season slots using two different variety rows; the rotation rule only blocks a *third* occurrence of the name "rice" (counting history + this plan together).
- **Mango is excluded from multi-cropping entirely.** It's a perennial tree crop, not something grown on a seasonal rotation within one year. It keeps full single-cropping support unchanged; the double/triple candidate pool is the 7 annual `SUPPORTED_CROPS` minus mango.

### 4.4 — The rotation rule

**Rule:** a crop (by name) cannot be selected if it already appears twice among {`previous_crop_1`, `previous_crop_2`, crops already placed earlier in the plan currently being built}. Applied as a hard exclusion, not a warning — everywhere crops get ranked:
- The existing single-season top-3 (`get_recommendation`)
- The chat's "other crop options beyond the top-3" (`get_other_crop_options`)
- The new double/triple plan builder (4.5)

`get_all_crop_scores()` / `get_recommendation()` gain an optional `exclude_crops: set[str] | None` parameter. When a crop's rotation count has already hit 2, it's dropped from the candidate pool *before* top-k/bucket selection — not just reordered or flagged. Backward compatible: omitted (or a land with no recorded history), nothing changes.

### 4.5 — Building the double/triple plan

Triggered at the same point as today's single recommendation — when a land's composite soil reading completes, inside `upsert_point` — branching on `farm.cropping_pattern`:

- **`single`**: unchanged — `get_all_crop_scores()` (rotation-filtered using `previous_crop_1/2`) → top 3 → saved as `RecommendationCrop` rows, `season = null`.
- **`double` / `triple`**: `get_all_crop_scores()` once, same soil + live-weather inputs as today (see limitation below) → group the ranked, non-mango candidates by their best-matching `crop_economics` row's `season` → for each of 2 (double) or 3 (triple) season buckets, take the highest-scoring candidate in that bucket that still passes the rotation rule (accounting for crops already placed earlier in *this* plan) → save one `RecommendationCrop` row per season, `season` set, `rank` repurposed as plan order (1st, 2nd, 3rd crop of the year). The yield/price/cost figures for that row come from the specific `(crop, variety)` row matching that season — not the species-wide average `get_profit_estimate` uses for single-cropping — since averaging across a dry-season and a monsoon-season variety would blur two genuinely different numbers together.
- If a bucket's top candidate is rotation-blocked, fall through to the next-best candidate in that bucket and record why on a new `rotation_note` field — e.g. *"Rice skipped — already grown twice in a row; Lentil selected instead."* If a bucket has no eligible candidate at all after exclusions, that slot is simply left unfilled (the plan has fewer rows than requested) rather than fabricating a choice.
- **Known limitation — stated plainly, including to the farmer if asked:** every season bucket is scored against the *same* current soil + live-weather reading. This doesn't model season-specific climate normals (Aus's pre-monsoon heat vs. Rabi's dry winter, etc.) — doing that would mean sourcing historical seasonal climate data per district, out of scope for this increment. *Which* crops are eligible per season is accurate (BAMIS-sourced); the *ranking within* a season is a same-snapshot approximation.

### 4.6 — Data model summary

```
farm:
  + cropping_pattern    String, not null, default 'single', check in ('single','double','triple')
  + previous_crop_1     String, nullable
  + previous_crop_2     String, nullable

crop_economics:
  + season              String, nullable, check in ('Rabi','Aus','Aman')

recommendation_crop:
  + season              String, nullable    (set only for double/triple plan rows)
  + rotation_note        String, nullable    (set only when a substitution happened)
  + total_cost           Float, nullable     (from Part 2 — fine to batch into the same migration)
```

### 4.7 — API / schema changes
```
FarmCreate / FarmUpdate / FarmOut
  + cropping_pattern: "single" | "double" | "triple"
  + previous_crop_1: str | None
  + previous_crop_2: str | None

RecommendationCropOut
  + season: str | None
  + rotation_note: str | None
```
No new endpoints. `RecommendationOut.top_crops` is reused for both single (3 ranked alternatives) and double/triple (2–3 sequenced plan rows) — the Flutter client decides how to render based on `farm.croppingPattern`, same reuse-over-duplication approach the add/edit modal already uses.

### 4.8 — Flutter

- `add_farm_modal.dart`: three new fields — cropping-pattern selector, two previous-crop dropdowns — same validation/styling as existing fields. Only `cropping_pattern` is required (pre-selected to "single").
- `RecommendationListScreen` branches on `farm.croppingPattern`:
  - `single` (unchanged): rank badge + confidence, exactly as today.
  - `double`/`triple`: the season name ("Rabi" / "Aus" / "Aman") replaces the rank badge; confidence shown secondarily; a row with `rotationNote` shows it as a small caption under the crop name.
- Chat: `get_current_recommendation`'s returned dict gains `season`/`rotation_note` per crop — the data already exists once 4.5 lands, this just stops dropping those two fields on the way out. System prompt gains the land's `previous_crop_1/2` as static context, in the same block as `farm_name`/`soil_type` today — no dedicated tool call needed for the agent to know rotation history when reasoning about ad-hoc questions.

### 4.9 — Build order
1. Migrations: `farm.cropping_pattern` / `previous_crop_1` / `previous_crop_2`, `crop_economics.season`, `recommendation_crop.season` / `rotation_note` (+ `total_cost` from Part 2 — same batch is fine).
2. `seed_crop_economics.py`: season classifier, re-run the seed script.
3. `recommendation_service.py`: `exclude_crops` param on `get_all_crop_scores`/`get_recommendation`; rotation-count helper.
4. `recommendations.py` (`upsert_point`): branch on `cropping_pattern`, build single vs. plan.
5. Schemas: `Farm*`, `RecommendationCropOut`.
6. `chat_agent_service.py`: thread `previous_crop_1/2` into the system prompt; stop dropping `season`/`rotation_note` from `get_current_recommendation`'s tool output.
7. Flutter: new fields in `add_farm_modal.dart`.
8. Flutter: season-aware rendering in `RecommendationListScreen`.

---

## Cross-cutting build order

Parts 1–3 are independent of each other and of Part 4 — any order works. Part 4 has real internal sequencing (history fields → season classification → rotation filter → plan builder → UI) and depends on nothing from Parts 1–3. Suggested order, smallest/lowest-risk first:

1. **Part 2** (budget check) — one column, no new concepts.
2. **Part 3** (forecast) — additive, no change to existing tables.
3. **Part 1** (explanation) — additive, one new tool.
4. **Part 4** (multi-cropping) — last: largest, touches the most existing code paths (form, pipeline, chat prompt).

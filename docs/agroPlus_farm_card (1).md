# AgroPlus — Farm Page Spec

Reached by tapping a farm card on the dashboard. Builds on the existing `Farm` model and the auth/dashboard increments already complete. Four-card layout: farm profile, live conditions, soil reading, recommendation.

## 1. Page overview

```
Farm page
├── Card 1 — Farm profile      (static, from FARM row)
├── Card 2 — Live conditions   (auto-fetched: temperature, humidity, rainfall)
├── Card 3 — Soil reading      (5-point N/P/K/pH input + latest composite)
└── Card 4 — Recommendation    (result derived from the latest reading; future home of the chat agent)
```

Load order matters: fetch Card 1 (farm data) first, Card 2 (live conditions) second. Card 4's action is disabled until Card 3 has at least one submitted reading — the recommendation call needs a soil reading as input, not just weather data.

## 2. Card 1 — Farm profile

Read-only display of the `FARM` row: farm name, location, district, area, soil type, water availability, budget, target season. Same data captured in the Add Farm modal. Edit action deferred (P1) — can reuse the Add Farm modal's form pre-filled with existing values when built.

`GET /farms/{id}` → `FarmOut`

## 3. Card 2 — Live conditions

Temperature, humidity, and rainfall, auto-fetched from Open-Meteo using the farm's `district_id` (resolved to lat/lng via the `DISTRICT` table server-side — never call Open-Meteo directly from Flutter).

- Fetch on page load. Show a "last updated: X min ago" label with a manual refresh icon — don't refetch on every re-render, don't cache indefinitely either.
- Endpoint: `GET /farms/{id}/conditions` → `{ temperature, humidity, rainfall, fetched_at }`. This stays a backend call so district-resolution and any future caching/rate-limiting logic lives in one place.

## 4. Card 3 — Soil reading

The card is shaped like the land itself — a box with tappable points positioned where each sample point actually sits on the field — rather than a plain list of inputs.

**Point count and position, driven by `farm.size_acres`:**

| Area | Points | Positions | Point labels |
|---|---|---|---|
| < 0.5 acre | 1 | Center only | `center` |
| 0.5–2 acres | 3 | 2 opposite corners + center | `corner_1`, `corner_2`, `center` |
| 2–5 acres | 5 | 4 corners + center | `corner_1`..`corner_4`, `center` |
| > 5 acres | 5 | 1 per quadrant + center | `quadrant_1`..`quadrant_4`, `center` |

This tier→label mapping (`required_points_for_area(size_acres)`) must be implemented identically on both frontend (to lay out the box) and backend (to validate submissions) — see §7.

**Card layout:** a dashed-border box representing the field, with one circular button per required point positioned proportionally within the box (e.g. top-left, top-right, bottom-left, bottom-right, and dead-center for the 5-point tier). Each button has two states:
- **Unfilled** — dashed outline, `+` icon.
- **Filled** — solid, checkmark icon.

Tapping any point (filled or unfilled) opens the same modal — N, P, K, pH fields — pre-filled if editing an existing point, empty if adding a new one.

**Composite section (bottom of card):**
- While any required point is still unfilled: a prompt, e.g. "Add the last point to see your composite reading" — never show a partial/fake composite.
- Once every required point for the farm's tier is filled: the actual composite N/P/K/pH (simple average across the filled points) displays here, e.g. `N 75.6 · P 38.8 · K 40.4 · pH 6.34`.

**Backend behavior — points save incrementally, pipeline runs on completion:** unlike a single "submit all 5 at once" form, each point is saved as soon as its modal is submitted. This means a soil reading can be in progress across multiple app sessions. To support this without restructuring the schema:
- The first point saved for a farm creates a `RECOMMENDATION` row with `status = "in_progress"` (see schema update in `AgroPlus_Dev_Spec.md` §3).
- Each subsequent point upserts a `SAMPLE_POINT` under that same in-progress recommendation.
- The moment the last required point for the farm's tier is saved, the backend computes the composite, runs the full recommendation pipeline (`get_recommendation` → `get_profit_estimate` → `get_explanation`), and flips `status` to `"complete"` — all in the same request/response.
- Card 3 and Card 4 both read from this one `RECOMMENDATION` object; there's no separate "submit reading" action distinct from "get recommendation" — completing the last point *is* the trigger.

**API for this card:**
```
GET /farms/{id}/recommendations/current
    → RecommendationOut | null   (status: in_progress or complete; includes saved points + composite if complete)

PUT /farms/{id}/recommendations/current/points/{point_label}
    { n, p, k, ph }
    → 200, RecommendationOut
    (creates the in-progress recommendation if none exists; upserts this point; if this
     completes the required set, runs the full pipeline and returns status: complete)
```
`point_label` must be one of the labels valid for the farm's current tier — reject otherwise. `PUT` (not `POST`) because re-tapping a filled point to correct it is the same operation as filling it the first time.

## 5. Card 4 — Recommendation

**Architectural decision — build backend logic as discrete callable functions, not one monolithic endpoint.** This card today is a simple "show the result" UI, but a chat agent is planned later where the farmer can ask for what they need conversationally. To avoid rebuilding this card twice, the underlying logic should be structured from the start as tools the agent can later call directly (OpenAI function calling) — the agent adds a conversational interface over the same functions, it doesn't get new capabilities.

Core functions (implement as real, independently callable backend functions — not just internal helper code inside one big handler):
```
get_soil_reading(farm_id)              → composite N/P/K/pH from the most recent input
get_recommendation(farm_id)            → top-3 crops + confidence (XGBoost/RF inference)
get_profit_estimate(farm_id, crop)     → yield × price × area − budget
get_explanation(farm_id, crop)         → OpenAI-generated plain-language reasoning
```

**Card states:**
- No reading yet (Card 3 empty) → this card stays disabled/greyed with a hint pointing at Card 3 — don't duplicate the "add reading" action here.
- Reading exists but pipeline hasn't produced a fresh result → shouldn't happen in practice, since the pipeline runs automatically the instant the last required point is saved (see Card 3) — there's no separate trigger to miss.
- Result exists → show top crop, confidence, yield estimate, profit estimate, AI explanation, and a "Chat with agent" action (see `agroPlus_chat_agent.md`).

**Note for future work:** when the chat agent is built, it becomes a new interface calling the same four functions above — this card's content area is where its responses will render. No rework of the underlying recommendation logic should be needed at that point.

## 6. Flutter structure

```
lib/features/farm/
├── farm_screen.dart            # page shell, holds the four cards, controls load order
├── farm_profile_card.dart      # Card 1
├── live_conditions_card.dart   # Card 2
├── soil_reading_card.dart      # Card 3 — land-box layout, point buttons, composite display
├── soil_point_modal.dart       # N/P/K/pH entry modal for a single point (add or edit)
├── recommendation_card.dart    # Card 4
└── farm_provider.dart          # fetches farm, conditions, current recommendation; exposes refresh()
```

## 7. Backend structure additions

```
backend/app/
├── services/
│   ├── recommendation_service.py   # get_soil_reading, get_recommendation, get_profit_estimate, get_explanation
│   └── sampling_service.py         # required_points_for_area(size_acres) — single source of truth for point tiers,
│                                    # mirrored in Flutter for layout; backend copy is what validates submissions
├── routers/
│   ├── farms.py                    # existing — add GET /farms/{id}/conditions
│   └── recommendations.py          # GET /farms/{id}/recommendations/current,
│                                    # PUT /farms/{id}/recommendations/current/points/{point_label}
```

Keep `recommendation_service.py` functions pure and independently testable — each takes explicit arguments and returns a value, no hidden shared state — since these become the agent's tool functions later.

## 8. Build order

1. Backend: `sampling_service.py` — `required_points_for_area(size_acres)` tier logic, unit tested against all four tiers including the boundaries (0.5, 2, 5 acres).
2. Backend: `recommendation_service.py` with the four functions, each testable in isolation.
3. Backend: `GET /farms/{id}/conditions` (Open-Meteo integration).
4. Backend: `GET /farms/{id}/recommendations/current` and `PUT .../points/{point_label}` — the PUT handler creates the in-progress recommendation on first call, upserts the point, and triggers the full pipeline when the tier's point set is complete.
5. Flutter: `farm_provider.dart` — fetch farm, conditions, and current recommendation; manage load order.
6. Flutter: `farm_screen.dart` shell + `farm_profile_card.dart` (simplest, static data).
7. Flutter: `live_conditions_card.dart` with refresh action.
8. Flutter: `soil_point_modal.dart` — single-point N/P/K/pH form, since Card 3 depends on it existing.
9. Flutter: `soil_reading_card.dart` — tier-based point layout (mirror `required_points_for_area` logic), filled/unfilled button states, composite display, wired to open the point modal.
10. Flutter: `recommendation_card.dart` — disabled state, populated result display, "Chat with agent" action.

End state: tapping a farm card opens a page showing farm details, current weather conditions, a land-shaped soil reading card whose point layout matches the farm's actual size, and either a disabled recommendation card or the full result with profit and explanation once every required point has been filled.

# AgroPlus — Dashboard + Add Farm Feature Spec

Builds directly on the auth/schema increment already completed (login/logout working). This increment makes the dashboard functional: list existing farms, and add new ones.

## 1. Screen states

**Empty state (already built):** farmer name header, logout icon, centered tractor icon + "You haven't added a farm yet", floating "Add farm" button bottom-right.

**Populated state (new):** same header, replaced by a scrollable list of farm cards, "Add farm" button remains available (as a floating button or pinned bottom action).

## 2. Farm card — component spec

Each card shows:
- Farm icon (leaf/plant icon in a colored tile)
- Farm name (bold, primary text)
- Location + size (`"Rangpur · 4.0 acres"`)
- Last recommendation date, right-aligned (`"2 days ago"`, or `"No checks yet"` if none exist)
- Chevron to indicate it's tappable

Tapping a card navigates to the farm detail screen (recommendation history) — out of scope for this increment, but the tap target should be wired now so it's a one-line change later.

## 3. Add Farm — modal form

Opens as a modal over the dashboard (not a separate screen/route) when "Add farm" is tapped. Scope for this increment is add-only — farm detail/editing is designed later.

| Field | Type | Notes |
|---|---|---|
| Farm name | Text input | Required |
| Location | Text input | Free-text address/description (e.g. "Near Teesta canal, Kaunia") — not used for lookups |
| District | Dropdown of Bangladesh's 64 districts (from `DISTRICT` table), or pre-filled via GPS nearest-district lookup | Required — this is the key used later for price/yield lookups |
| Area | Number input (acres) | Required |
| Soil type | Dropdown — Clay, Loamy, Sandy, Silty | Required |
| Water availability | Dropdown — Irrigated, Rain-fed, Limited | Required |
| Budget | Number input (BDT) | Required — feeds net profit calculation later |
| Target season | Dropdown — Rabi, Aus, Aman | Required |

On submit → `POST /farms` → modal closes, dashboard list refreshes with the new card. Validation (required fields, area/budget must be positive) happens client-side before submit; backend re-validates via Pydantic regardless.

## 4. API endpoints

```
GET    /farms                 Authorization: Bearer <token>   → 200, [FarmOut]  (current farmer's farms)
POST   /farms                 { farm_name, location, district_id, size_acres,
                                 soil_type, water_availability, budget, target_season }  → 201, FarmOut
GET    /farms/{id}            → 200, FarmOut
PATCH  /farms/{id}            { any subset of the above fields }  → 200, FarmOut
DELETE /farms/{id}            → 204
```
All routes protected by the existing `get_current_farmer` dependency — a farm is always created under and scoped to the authenticated farmer; never trust a `farmer_id` from the request body.

`FarmOut` includes a computed `last_recommendation_at` (nullable) for the card's "last checked" display — derived from the farm's most recent `RECOMMENDATION` row, not stored redundantly on `FARM`.

## 5. Flutter structure

```
lib/features/dashboard/
├── dashboard_screen.dart      # farmer header + farm list or empty state
├── farm_card.dart             # single card widget
├── farm_provider.dart         # fetches /farms, holds list state, exposes add/refresh
├── add_farm_modal.dart        # modal form, posts to /farms
```

`farm_provider.dart` should expose a simple `refresh()` so returning from `add_farm_screen` after a successful submit re-fetches the list rather than the UI trying to manually splice in the new farm — simpler and avoids state drift.

## 6. Build order

1. Backend: `Farm` SQLAlchemy model + Alembic migration.
2. Backend: `GET /farms` and `POST /farms`, both behind `get_current_farmer`.
3. Backend: `PATCH`/`DELETE /farms/{id}` (needed eventually, cheap to add now alongside the rest).
4. Flutter: `farm_provider.dart` — fetch and hold farm list state.
5. Flutter: wire `dashboard_screen.dart` to show the populated list vs. the existing empty state based on the fetched data.
6. Flutter: build `farm_card.dart`.
7. Flutter: build `add_farm_modal.dart` form, wire to `POST /farms`, close and refresh dashboard on success.

End state: a farmer can add a farm, see it appear as a card on the dashboard, and the empty state only shows when there are genuinely zero farms.

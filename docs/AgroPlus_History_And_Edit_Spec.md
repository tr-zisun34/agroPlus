# AgroPlus — Recommendation History + Farm Editing

Two independent, self-contained features. Both build on endpoints/components that already exist — no new backend concepts.

---

## Part 1 — Recommendation History

### Entry point
A "View history" link/action on Card 4 (Recommendation), below the current top-3 result. If the farm has no completed recommendation yet, this link is hidden — nothing to show.

### History list screen
- Newest first, one row per completed recommendation: date, rank-1 crop name, confidence.
- Empty state (farm has zero completed recommendations — shouldn't normally be reachable since the entry link is hidden in that case, but handle it defensively anyway): "No recommendations yet."
- Tapping a row opens the detail screen for that recommendation.

### Detail screen
Shows one past recommendation in full:
- Composite N, P, K, pH values used for that reading
- All 3 ranked crops with confidence
- Date/timestamp
- No profit or explanation shown — those fields are still null for every recommendation (per `AgroPlus_Recommendation_Pipeline.md`), current and past alike; this screen doesn't fake or omit-differently for old vs. new records.

### API
```
GET /farms/{id}/recommendations
    → [RecommendationSummary]   -- status="complete" only, newest first
    RecommendationSummary = { id, created_at, top_crop, top_confidence }

GET /farms/{id}/recommendations/{recommendation_id}
    → RecommendationOut         -- full detail, same shape already defined in the pipeline spec
```
Both routes reuse the existing `get_current_farmer` auth dependency and the existing `RecommendationOut`/`RECOMMENDATION`/`RECOMMENDATION_CROP` schema — no schema change needed for this feature.

### Flutter structure
```
lib/features/farm/
├── recommendation_history_screen.dart   # list, newest first
├── recommendation_detail_screen.dart    # composite + top-3 for one record
└── recommendation_provider.dart         # fetches list + individual detail on demand
```

---

## Part 2 — Farm Editing

### Entry point
An edit icon/action on Card 1 (Farm profile). Tapping it opens the **same Add Farm modal**, not a new screen — pre-filled with the farm's current values.

### Modal reuse — add vs. edit mode
`add_farm_modal.dart` takes an optional `existingFarm` parameter:
- `null` → add mode: empty form, submits via `POST /farms`.
- populated → edit mode: form pre-filled from `existingFarm`, submits via `PATCH /farms/{id}`, modal title reads "Edit farm" instead of "Add farm."

Same 8 fields, same validation, same submit button — only the pre-fill and the HTTP verb/endpoint differ. This is a parameterization of the existing component, not a second modal to build and maintain.

### On successful edit
Modal closes, `farm_provider.refresh()` re-fetches the farm so Card 1 (and the dashboard card, if the farm name/location changed) reflect the update immediately — same refresh pattern already used after adding a farm.

### API
```
PATCH /farms/{id}   { any subset of: farm_name, location, district_id, size_acres,
                       soil_type, water_availability, budget, target_season }
    → 200, FarmOut
```
Already defined in `AgroPlus_Dashboard_AddFarm_Spec.md` — no new endpoint needed, just the first time it's actually wired up to the UI.

**One consequence worth flagging:** if `size_acres` is edited across a sampling-tier boundary (e.g. 1.8 → 2.2 acres), the soil reading point layout (Card 3) changes shape — a farm that previously needed 3 points now needs 5. Any `RECOMMENDATION` still `"in_progress"` for that farm should be discarded (not silently reinterpreted) when the tier changes, since its partially-filled points no longer match the new required set. A completed recommendation stays valid as history regardless — it was correct for the farm's size at the time.

---

## Build order

1. Backend: `GET /farms/{id}/recommendations` and `GET /farms/{id}/recommendations/{recommendation_id}` (both simple reads against existing tables).
2. Backend: wire `PATCH /farms/{id}` if not already connected to a router (contract already exists per the dashboard spec).
3. Backend: on `PATCH`, if `size_acres` changes tier, discard any `in_progress` `RECOMMENDATION` row for that farm (see note above).
4. Flutter: `recommendation_provider.dart` — list + detail fetch.
5. Flutter: `recommendation_history_screen.dart` + empty state.
6. Flutter: `recommendation_detail_screen.dart`.
7. Flutter: add "View history" link to Card 4, wired to the history screen.
8. Flutter: parameterize `add_farm_modal.dart` for edit mode (`existingFarm`, verb switch, title switch).
9. Flutter: add edit icon to Card 1, wired to open the modal in edit mode.

End state: a farmer can review every past recommendation for a farm in full detail, and can correct any of a farm's 8 fields after creation without deleting and re-adding it.

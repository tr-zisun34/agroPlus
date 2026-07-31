# AgroPlus — Training & Recommendation Pipeline

## Scope for this increment

**In scope:** train the model on the Kaggle Crop Recommendation dataset, and return the top-3 crops with confidence scores from soil (N/P/K/pH) + weather (temperature, humidity, rainfall) inputs.

**Explicitly deferred (build later, not part of this spec):**
- Season / water-availability / soil-type filtering (the two-stage pipeline discussed separately) — the model output here is agronomic fit only, unfiltered.
- Profit estimation (`get_profit_estimate`) — needs the DAM/BBS yield and price tables, not yet collected.
- AI explanation (`get_explanation`) — needs the BAMIS knowledge base, not yet collected.

The schema and API below are designed so these slot in later without rework — see the nullable fields and the deferred columns noted inline.

## 1. Dataset & training

Kaggle Crop Recommendation Dataset — 2,200 rows, 22 crops, 7 features (`N`, `P`, `K`, `temperature`, `humidity`, `ph`, `rainfall`).

Use `train_model.py` (already delivered) to produce three artifacts:
```
artifacts/xgb_model.joblib
artifacts/rf_model.joblib
artifacts/label_encoder.joblib
```
Run once locally:
```
python train_model.py --data Crop_recommendation.csv --out ./artifacts
```
Copy the three files into `backend/app/ml_artifacts/`.

## 2. Schema change — top-3 results need their own table

`RECOMMENDATION` previously had single `top_crop`/`confidence` fields — insufficient for a top-3 result. Updated:

```
RECOMMENDATION {
  uuid id PK
  uuid farm_id FK -> FARM.id
  timestamp created_at
  string status         -- "in_progress" or "complete"
  float composite_n     -- nullable until complete
  float composite_p     -- nullable until complete
  float composite_k     -- nullable until complete
  float composite_ph    -- nullable until complete
}

RECOMMENDATION_CROP {
  uuid id PK
  uuid recommendation_id FK -> RECOMMENDATION.id
  int rank               -- 1, 2, or 3
  string crop
  float confidence
  float yield_estimate   -- nullable — populated once the profit engine exists (deferred)
  float net_profit       -- nullable — populated once the profit engine exists (deferred)
}
```
This is also reflected in `AgroPlus_Dev_Spec.md`. `yield_estimate`/`net_profit` are already present as nullable columns so the profit engine can populate them later without another migration.

## 3. `recommendation_service.get_recommendation`

Already delivered (`recommendation_service_get_recommendation.py`) — loads both saved models, ensembles their `predict_proba` output (simple average, not a single-model pick), and returns the top 3 as `[{crop, confidence}, ...]`. No changes needed for this increment; it's dataset-only by design already.

## 4. Endpoint integration

`PUT /farms/{id}/recommendations/current/points/{point_label}` (already specified in `agroPlus_farm_card.md`) — the completion branch now does this:

```
on last required point saved:
    composite = average all saved points' (n, p, k, ph)
    conditions = fetch current temperature/humidity/rainfall for the farm's district
    top3 = get_recommendation(
        composite.n, composite.p, composite.k, composite.ph,
        conditions.temperature, conditions.humidity, conditions.rainfall
    )
    save composite onto the RECOMMENDATION row, set status = "complete"
    save each of the 3 results as a RECOMMENDATION_CROP row (rank 1-3, crop, confidence;
        yield_estimate and net_profit left null — profit engine not built yet)
    return the full RecommendationOut
```

## 5. `RecommendationOut` shape

```
RecommendationOut {
  id, farm_id, status, created_at,
  composite_n, composite_p, composite_k, composite_ph,
  top_crops: [
    { rank: 1, crop, confidence, yield_estimate: null, net_profit: null },
    { rank: 2, crop, confidence, yield_estimate: null, net_profit: null },
    { rank: 3, crop, confidence, yield_estimate: null, net_profit: null }
  ]
}
```
`top_crops` is empty while `status = "in_progress"`.

## 6. Card 4 UI impact for this increment

Show the 3 crops ranked with their confidence scores. Since `yield_estimate`/`net_profit` are null for now, don't render blank/zero values for them — omit that row entirely per crop, or show a plain "Profit estimate coming soon" note under the list once, not per crop. Don't fabricate placeholder numbers.

## 7. Build order

1. Backend: run `train_model.py` locally, copy artifacts into `backend/app/ml_artifacts/`.
2. Backend: Alembic migration — restructure `RECOMMENDATION` (drop `top_crop`/`confidence`/`yield_estimate`/`net_profit`), add `RECOMMENDATION_CROP` table.
3. Backend: add `get_recommendation` into `recommendation_service.py` (already written).
4. Backend: update the `PUT .../points/{point_label}` completion branch per §4.
5. Flutter: update `recommendation_card.dart` to render `top_crops` (list of 3) instead of a single crop, omitting yield/profit display for now.

End state: completing a farm's last required soil point returns and stores three ranked crop recommendations with confidence scores — profit and explanation remain visibly "coming soon" rather than faked, and the schema is already shaped for them to be added without another migration.

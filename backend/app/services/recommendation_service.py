"""Independently callable recommendation tools — designed so a chat agent can call these
directly via OpenAI function calling, not just internal helpers for one endpoint.
"""

import pathlib
import uuid

import joblib
import numpy as np
import pandas as pd
from sklearn.tree import export_text
from sqlalchemy.orm import Session

from app.models.crop_economics import CropEconomics
from app.models.recommendation import Recommendation

FEATURE_COLUMNS = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]
_ARTIFACTS_DIR = pathlib.Path(__file__).resolve().parent.parent / "ml_artifacts"
_TRAINING_DATA_PATH = (
    pathlib.Path(__file__).resolve().parent.parent.parent.parent / "docs" / "dataset" / "Crop_recommendation.csv"
)

# Scoped to the crops crop_economics actually has yield+price for (see seed_crop_economics.py).
# The underlying Kaggle model still knows all 22 crops, but for this development phase we only
# want to ever recommend one we can also show a profit number for — so the other 14 (cotton,
# coffee, most fruits, etc.) are masked out of get_recommendation rather than retraining.
SUPPORTED_CROPS = {"rice", "maize", "chickpea", "mungbean", "blackgram", "lentil", "jute", "mango"}

_xgb_model = None
_rf_model = None
_label_encoder = None
_crop_feature_stats: dict | None = None


def get_soil_reading(farm_id: uuid.UUID, db: Session) -> dict | None:
    """Composite N/P/K/pH from the farm's most recent soil reading (averaged across its saved points)."""
    recommendation = (
        db.query(Recommendation)
        .filter(Recommendation.farm_id == farm_id)
        .order_by(Recommendation.created_at.desc())
        .first()
    )
    if recommendation is None or not recommendation.points:
        return None

    points = recommendation.points
    count = len(points)
    return {
        "n": sum(p.n for p in points) / count,
        "p": sum(p.p for p in points) / count,
        "k": sum(p.k for p in points) / count,
        "ph": sum(p.ph for p in points) / count,
    }


def _load_models():
    global _xgb_model, _rf_model, _label_encoder
    if _xgb_model is None:
        _xgb_model = joblib.load(_ARTIFACTS_DIR / "xgb_model.joblib")
        _rf_model = joblib.load(_ARTIFACTS_DIR / "rf_model.joblib")
        _label_encoder = joblib.load(_ARTIFACTS_DIR / "label_encoder.joblib")
    return _xgb_model, _rf_model, _label_encoder


def _print_decision_tree(rf_model, label_encoder) -> None:
    """Print one representative tree (the first of the forest's estimators) as readable ASCII
    text — the full forest has 200 trees, too many to dump to the terminal on every call."""
    tree_text = export_text(
        rf_model.estimators_[0],
        feature_names=FEATURE_COLUMNS,
        class_names=list(label_encoder.classes_),
    )
    print(f"\n--- Random Forest decision tree (1 of {len(rf_model.estimators_)}) ---")
    print(tree_text)
    print("--- end decision tree ---\n")


def get_all_crop_scores(
    n: float, p: float, k: float, temperature: float, humidity: float, ph: float, rainfall: float
) -> list[dict]:
    """Every SUPPORTED_CROPS crop with its confidence, ensembled (simple average) from the
    XGBoost and Random Forest models trained on the Kaggle Crop Recommendation dataset,
    renormalized over just that subset and sorted descending. get_recommendation (the top-3
    shown on the dashboard) and the chat agent's "other crop options" tool both slice this."""
    xgb_model, rf_model, label_encoder = _load_models()

    features = pd.DataFrame([[n, p, k, temperature, humidity, ph, rainfall]], columns=FEATURE_COLUMNS)

    xgb_proba = xgb_model.predict_proba(features)[0]
    rf_proba = rf_model.predict_proba(features)[0]
    avg_proba = (xgb_proba + rf_proba) / 2

    supported_mask = np.array([c in SUPPORTED_CROPS for c in label_encoder.classes_])
    masked_proba = np.where(supported_mask, avg_proba, 0.0)
    masked_proba = masked_proba / masked_proba.sum()

    ranked_indices = [idx for idx in np.argsort(masked_proba)[::-1] if masked_proba[idx] > 0]
    return [
        {"crop": label_encoder.inverse_transform([idx])[0], "confidence": float(masked_proba[idx])}
        for idx in ranked_indices
    ]


def get_recommendation(
    n: float, p: float, k: float, temperature: float, humidity: float, ph: float, rainfall: float
) -> list[dict]:
    """Top-3 crops with confidence — see get_all_crop_scores for the full ranked list."""
    xgb_model, rf_model, label_encoder = _load_models()
    _print_decision_tree(rf_model, label_encoder)
    return get_all_crop_scores(n, p, k, temperature, humidity, ph, rainfall)[:3]


def get_profit_estimate(crop: str, size_acres: float, db: Session) -> dict | None:
    """Yield and net profit for one crop on this farm, from national-average BAMIS/DAM figures.

    Returns None when the crop has no yield/price row at all (e.g. a crop the model considers
    agronomically viable but that isn't traded in Bangladesh markets) — callers should leave
    yield_estimate/net_profit null rather than fabricate a number.

    The ML model only ever outputs a generic crop name (e.g. "rice"), never a market variety,
    but crop_economics keeps every variety (e.g. rice's amon/boro x local/hybrid grades) as its
    own row since they're priced separately. When a crop has several variety rows, this averages
    yield/price/cost across them for this one automatic figure — the per-variety rows themselves
    stay queryable for a future "compare varieties" view.

    Net profit is computed against BAMIS's own per-acre production cost estimate, not the
    farmer's entered budget — that budget is informational (what they plan to spend) rather than
    the basis for this estimate (what BAMIS expects the crop to actually cost to grow).
    """
    rows = db.query(CropEconomics).filter(CropEconomics.crop == crop.lower()).all()
    if not rows or any(r.cost_bdt_per_acre is None for r in rows):
        return None

    avg_yield = sum(r.yield_kg_per_acre for r in rows) / len(rows)
    avg_price = sum(r.price_bdt_per_kg for r in rows) / len(rows)
    avg_cost = sum(r.cost_bdt_per_acre for r in rows) / len(rows)

    total_yield_kg = avg_yield * size_acres
    total_cost = avg_cost * size_acres
    gross_revenue = total_yield_kg * avg_price
    net_profit = gross_revenue - total_cost

    return {"yield_estimate": total_yield_kg, "net_profit": net_profit, "total_cost": total_cost}


def get_crop_detail(crop: str, size_acres: float, db: Session) -> dict | None:
    """Full harvest economics breakdown for one crop on this farm — seed cost, itemized
    fertilizer cost (BAMIS recipe x DAM fertilizer prices), other costs (whatever's left of
    BAMIS's bundled total after subtracting seed + fertilizer), cultivation season, yield,
    price, gross revenue, and net profit. Used by the per-crop detail screen a farmer reaches
    after picking one of the top-3 recommended crops.

    Returns None under the same condition as get_profit_estimate (no economics row for this crop).
    """
    rows = db.query(CropEconomics).filter(CropEconomics.crop == crop.lower()).all()
    if not rows or any(r.cost_bdt_per_acre is None for r in rows):
        return None

    avg_yield = sum(r.yield_kg_per_acre for r in rows) / len(rows)
    avg_price = sum(r.price_bdt_per_kg for r in rows) / len(rows)
    avg_cost = sum(r.cost_bdt_per_acre for r in rows) / len(rows)
    seed_costs = [r.seed_cost_bdt_per_acre for r in rows if r.seed_cost_bdt_per_acre is not None]
    avg_seed_cost = sum(seed_costs) / len(seed_costs) if seed_costs else None
    fertilizer_costs = [r.fertilizer_cost_bdt_per_acre for r in rows if r.fertilizer_cost_bdt_per_acre is not None]
    avg_fertilizer_cost = sum(fertilizer_costs) / len(fertilizer_costs) if fertilizer_costs else None
    other_costs = [r.other_cost_bdt_per_acre for r in rows if r.other_cost_bdt_per_acre is not None]
    avg_other_cost = sum(other_costs) / len(other_costs) if other_costs else None
    fertilizer_breakdown_per_acre = next((r.fertilizer_breakdown for r in rows if r.fertilizer_breakdown), None)
    season_label = next((r.season_label for r in rows if r.season_label), None)

    total_yield_kg = avg_yield * size_acres
    gross_revenue = total_yield_kg * avg_price
    total_cost = avg_cost * size_acres
    seed_cost = avg_seed_cost * size_acres if avg_seed_cost is not None else None
    fertilizer_cost = avg_fertilizer_cost * size_acres if avg_fertilizer_cost is not None else None
    other_cost = avg_other_cost * size_acres if avg_other_cost is not None else None
    net_profit = gross_revenue - total_cost

    fertilizer_breakdown = None
    if fertilizer_breakdown_per_acre:
        fertilizer_breakdown = {
            fert_type: {
                "qty_kg": item["qty_kg_per_acre"] * size_acres,
                "price_bdt_per_kg": item["price_bdt_per_kg"],
                "cost_bdt": item["cost_bdt_per_acre"] * size_acres,
            }
            for fert_type, item in fertilizer_breakdown_per_acre.items()
        }

    return {
        "crop": crop.lower(),
        "yield_estimate": total_yield_kg,
        "price_bdt_per_kg": avg_price,
        "gross_revenue": gross_revenue,
        "seed_cost": seed_cost,
        "fertilizer_cost": fertilizer_cost,
        "fertilizer_breakdown": fertilizer_breakdown,
        "other_cost": other_cost,
        "total_cost": total_cost,
        "net_profit": net_profit,
        "season_label": season_label,
    }


def _load_crop_feature_stats() -> dict:
    """Per-crop min/max/mean for each feature, computed once from the same training CSV the
    model was built from, cached for the life of the process — same lazy-load-once pattern as
    _load_models()."""
    global _crop_feature_stats
    if _crop_feature_stats is None:
        df = pd.read_csv(_TRAINING_DATA_PATH)
        stats: dict[str, dict[str, dict[str, float]]] = {}
        for crop, group in df.groupby("label"):
            stats[crop] = {
                feature: {
                    "min": float(group[feature].min()),
                    "max": float(group[feature].max()),
                    "mean": float(group[feature].mean()),
                }
                for feature in FEATURE_COLUMNS
            }
        _crop_feature_stats = stats
    return _crop_feature_stats


def get_recommendation_explanation(
    crop: str, n: float, p: float, k: float, temperature: float, humidity: float, ph: float, rainfall: float
) -> dict | None:
    """Grounds "why this crop?" in real numbers instead of letting a chat agent guess: this
    farm's actual feature values compared against the typical (min/max/mean) range for the
    given crop in the training data, plus the model's global feature importances (which inputs
    the ensemble weighs most heavily overall — not specific to this one prediction, since that
    would need per-instance explainability like SHAP, out of scope here).

    Returns None if the crop isn't one the model was trained on at all (shouldn't happen for
    anything get_recommendation/get_all_crop_scores would have returned, but defends against a
    typo'd crop name reaching this from the chat agent).
    """
    feature_stats = _load_crop_feature_stats()
    if crop.lower() not in feature_stats:
        return None

    xgb_model, _, _ = _load_models()
    farm_values = {
        "N": n,
        "P": p,
        "K": k,
        "temperature": temperature,
        "humidity": humidity,
        "ph": ph,
        "rainfall": rainfall,
    }
    crop_stats = feature_stats[crop.lower()]

    feature_comparison = [
        {
            "feature": feature,
            "farm_value": farm_values[feature],
            "typical_min": crop_stats[feature]["min"],
            "typical_max": crop_stats[feature]["max"],
            "typical_mean": crop_stats[feature]["mean"],
            "in_range": crop_stats[feature]["min"] <= farm_values[feature] <= crop_stats[feature]["max"],
        }
        for feature in FEATURE_COLUMNS
    ]

    model_feature_importance = [
        {"feature": feature, "importance": float(importance)}
        for feature, importance in zip(FEATURE_COLUMNS, xgb_model.feature_importances_)
    ]

    return {
        "crop": crop.lower(),
        "feature_comparison": feature_comparison,
        "model_feature_importance": sorted(model_feature_importance, key=lambda x: -x["importance"]),
    }

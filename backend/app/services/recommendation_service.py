"""Independently callable recommendation tools — designed so a future chat agent can call
these directly via OpenAI function calling, not just internal helpers for one endpoint.

get_soil_reading and get_recommendation are implemented for this increment.
get_profit_estimate and get_explanation depend on yield/price lookup tables and an OpenAI
integration that don't exist yet — deferred to a later increment.
"""

import pathlib
import uuid

import joblib
import numpy as np
import pandas as pd
from sklearn.tree import export_text
from sqlalchemy.orm import Session

from app.models.recommendation import Recommendation

FEATURE_COLUMNS = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]
_ARTIFACTS_DIR = pathlib.Path(__file__).resolve().parent.parent / "ml_artifacts"

_xgb_model = None
_rf_model = None
_label_encoder = None


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


def get_recommendation(
    n: float, p: float, k: float, temperature: float, humidity: float, ph: float, rainfall: float
) -> list[dict]:
    """Top-3 crops with confidence, ensembled (simple average) from the XGBoost and Random
    Forest models trained on the Kaggle Crop Recommendation dataset."""
    xgb_model, rf_model, label_encoder = _load_models()
    _print_decision_tree(rf_model, label_encoder)

    features = pd.DataFrame([[n, p, k, temperature, humidity, ph, rainfall]], columns=FEATURE_COLUMNS)

    xgb_proba = xgb_model.predict_proba(features)[0]
    rf_proba = rf_model.predict_proba(features)[0]
    avg_proba = (xgb_proba + rf_proba) / 2

    top3_indices = np.argsort(avg_proba)[::-1][:3]
    return [
        {"crop": label_encoder.inverse_transform([idx])[0], "confidence": float(avg_proba[idx])}
        for idx in top3_indices
    ]

"""Train XGBoost + Random Forest crop classifiers on the Kaggle Crop Recommendation dataset.

Usage:
    python train_model.py --data Crop_recommendation.csv --out ./artifacts

Produces three artifacts in --out:
    xgb_model.joblib
    rf_model.joblib
    label_encoder.joblib

Copy them into backend/app/ml_artifacts/ for the API to load.
"""

import argparse
import pathlib

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier

FEATURE_COLUMNS = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]
LABEL_COLUMN = "label"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", required=True, help="Path to Crop_recommendation.csv")
    parser.add_argument("--out", required=True, help="Output directory for trained artifacts")
    args = parser.parse_args()

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(args.data)
    X = df[FEATURE_COLUMNS]

    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(df[LABEL_COLUMN])

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    xgb_model = XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        random_state=42,
        eval_metric="mlogloss",
    )
    xgb_model.fit(X_train, y_train)
    xgb_accuracy = accuracy_score(y_test, xgb_model.predict(X_test))
    print(f"XGBoost holdout accuracy: {xgb_accuracy:.4f}")

    rf_model = RandomForestClassifier(n_estimators=200, max_depth=None, random_state=42)
    rf_model.fit(X_train, y_train)
    rf_accuracy = accuracy_score(y_test, rf_model.predict(X_test))
    print(f"Random Forest holdout accuracy: {rf_accuracy:.4f}")

    # Refit both on the full dataset for the shipped artifacts — the holdout split above is
    # only to report a generalization estimate.
    xgb_model.fit(X, y)
    rf_model.fit(X, y)

    joblib.dump(xgb_model, out_dir / "xgb_model.joblib")
    joblib.dump(rf_model, out_dir / "rf_model.joblib")
    joblib.dump(label_encoder, out_dir / "label_encoder.joblib")
    print(f"Saved artifacts to {out_dir.resolve()}")


if __name__ == "__main__":
    main()

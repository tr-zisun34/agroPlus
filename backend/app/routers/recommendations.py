import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.db.session import get_db
from app.models.farm import Farm
from app.models.farmer import Farmer
from app.models.recommendation import Recommendation
from app.models.recommendation_crop import RecommendationCrop
from app.models.sample_point import SamplePoint
from app.schemas.recommendation import CropDetailOut, RecommendationOut, RecommendationSummary, SamplePointIn
from app.services.recommendation_service import (
    build_multi_crop_plan,
    crops_at_rotation_limit,
    get_crop_detail,
    get_profit_estimate,
    get_recommendation,
)
from app.services.sampling_service import required_points_for_area
from app.services.weather_service import WeatherServiceError, fetch_current_conditions

router = APIRouter(prefix="/farms", tags=["recommendations"])


def _get_owned_farm(farm_id: uuid.UUID, farmer: Farmer, db: Session) -> Farm:
    farm = db.query(Farm).filter(Farm.id == farm_id, Farm.farmer_id == farmer.id).first()
    if farm is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farm not found")
    return farm


def _get_current_recommendation(farm_id: uuid.UUID, db: Session) -> Recommendation | None:
    return (
        db.query(Recommendation)
        .filter(Recommendation.farm_id == farm_id)
        .order_by(Recommendation.created_at.desc())
        .first()
    )


@router.get("/{farm_id}/recommendations/current", response_model=RecommendationOut | None)
def get_current_recommendation(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    _get_owned_farm(farm_id, current_farmer, db)
    recommendation = _get_current_recommendation(farm_id, db)
    return recommendation


@router.get("/{farm_id}/recommendations", response_model=list[RecommendationSummary])
def list_recommendations(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    _get_owned_farm(farm_id, current_farmer, db)

    completed = (
        db.query(Recommendation)
        .filter(Recommendation.farm_id == farm_id, Recommendation.status == "complete")
        .order_by(Recommendation.created_at.desc())
        .all()
    )
    return [
        RecommendationSummary(
            id=rec.id,
            created_at=rec.created_at,
            top_crop=rec.top_crops[0].crop,
            top_confidence=rec.top_crops[0].confidence,
        )
        for rec in completed
        if rec.top_crops
    ]


@router.get("/{farm_id}/recommendations/{recommendation_id}", response_model=RecommendationOut)
def get_recommendation_detail(
    farm_id: uuid.UUID,
    recommendation_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    _get_owned_farm(farm_id, current_farmer, db)

    recommendation = (
        db.query(Recommendation)
        .filter(Recommendation.id == recommendation_id, Recommendation.farm_id == farm_id)
        .first()
    )
    if recommendation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recommendation not found")

    return recommendation


@router.get("/{farm_id}/recommendations/current/crops/{crop}", response_model=CropDetailOut)
def get_recommended_crop_detail(
    farm_id: uuid.UUID,
    crop: str,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)

    detail = get_crop_detail(crop=crop, size_acres=farm.size_acres, db=db)
    if detail is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No economics data for this crop")

    return detail


@router.put("/{farm_id}/recommendations/current/points/{point_label}", response_model=RecommendationOut)
async def upsert_point(
    farm_id: uuid.UUID,
    point_label: str,
    payload: SamplePointIn,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)

    required = required_points_for_area(farm.size_acres)
    if point_label not in required:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"'{point_label}' is not a valid point for this farm's current tier: {required}",
        )

    recommendation = _get_current_recommendation(farm_id, db)
    if recommendation is None:
        recommendation = Recommendation(farm_id=farm.id, status="in_progress")
        db.add(recommendation)
        db.flush()

    existing_point = (
        db.query(SamplePoint)
        .filter(SamplePoint.recommendation_id == recommendation.id, SamplePoint.point_label == point_label)
        .first()
    )
    if existing_point is None:
        db.add(
            SamplePoint(
                recommendation_id=recommendation.id,
                point_label=point_label,
                n=payload.n,
                p=payload.p,
                k=payload.k,
                ph=payload.ph,
            )
        )
    else:
        existing_point.n = payload.n
        existing_point.p = payload.p
        existing_point.k = payload.k
        existing_point.ph = payload.ph

    db.commit()
    db.refresh(recommendation)

    required_points = [pt for pt in recommendation.points if pt.point_label in required]
    if {pt.point_label for pt in required_points} >= set(required):
        count = len(required_points)
        recommendation.composite_n = sum(pt.n for pt in required_points) / count
        recommendation.composite_p = sum(pt.p for pt in required_points) / count
        recommendation.composite_k = sum(pt.k for pt in required_points) / count
        recommendation.composite_ph = sum(pt.ph for pt in required_points) / count
        recommendation.status = "complete"

        # Re-run the pipeline every time the required set is (re)satisfied — including
        # re-edits of an already-complete reading — so results never go stale.
        for existing_crop in recommendation.top_crops:
            db.delete(existing_crop)
        db.flush()

        if farm.district.center_lat is not None and farm.district.center_lng is not None:
            try:
                conditions = await fetch_current_conditions(farm.district.center_lat, farm.district.center_lng)
                previous_crops = [farm.previous_crop_1, farm.previous_crop_2]

                if farm.cropping_pattern == "single":
                    exclude_crops = crops_at_rotation_limit(previous_crops)
                    top3 = get_recommendation(
                        n=recommendation.composite_n,
                        p=recommendation.composite_p,
                        k=recommendation.composite_k,
                        temperature=conditions["temperature"],
                        humidity=conditions["humidity"],
                        ph=recommendation.composite_ph,
                        rainfall=conditions["rainfall"],
                        exclude_crops=exclude_crops,
                    )
                    for rank, item in enumerate(top3, start=1):
                        profit = get_profit_estimate(crop=item["crop"], size_acres=farm.size_acres, db=db)
                        db.add(
                            RecommendationCrop(
                                recommendation_id=recommendation.id,
                                rank=rank,
                                crop=item["crop"],
                                confidence=item["confidence"],
                                yield_estimate=profit["yield_estimate"] if profit else None,
                                net_profit=profit["net_profit"] if profit else None,
                                total_cost=profit["total_cost"] if profit else None,
                            )
                        )
                else:
                    plan = build_multi_crop_plan(
                        n=recommendation.composite_n,
                        p=recommendation.composite_p,
                        k=recommendation.composite_k,
                        temperature=conditions["temperature"],
                        humidity=conditions["humidity"],
                        ph=recommendation.composite_ph,
                        rainfall=conditions["rainfall"],
                        size_acres=farm.size_acres,
                        pattern=farm.cropping_pattern,
                        previous_crops=previous_crops,
                        db=db,
                    )
                    for rank, item in enumerate(plan, start=1):
                        db.add(
                            RecommendationCrop(
                                recommendation_id=recommendation.id,
                                rank=rank,
                                crop=item["crop"],
                                confidence=item["confidence"],
                                yield_estimate=item["yield_estimate"],
                                net_profit=item["net_profit"],
                                total_cost=item["total_cost"],
                                season=item["season"],
                                rotation_note=item["rotation_note"],
                            )
                        )
            except WeatherServiceError:
                # Composite still saves; crops stay empty until the farmer retries (e.g. by
                # re-editing a point), rather than failing the point save outright.
                pass

        db.commit()
        db.refresh(recommendation)

    return recommendation

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.db.session import get_db
from app.models.district import District
from app.models.farm import Farm
from app.models.farmer import Farmer
from app.models.recommendation import Recommendation
from app.schemas.district import DistrictOut
from app.schemas.farm import ConditionsOut, FarmCreate, FarmOut, FarmUpdate, ForecastDayOut
from app.services.sampling_service import required_points_for_area
from app.services.weather_service import WeatherServiceError, fetch_current_conditions, fetch_forecast

router = APIRouter(prefix="/farms", tags=["farms"])


def _to_farm_out(farm: Farm, db: Session) -> FarmOut:
    last_recommendation = (
        db.query(Recommendation)
        .filter(Recommendation.farm_id == farm.id, Recommendation.status == "complete")
        .order_by(Recommendation.created_at.desc())
        .first()
    )

    return FarmOut(
        id=farm.id,
        farm_name=farm.farm_name,
        location=farm.location,
        district=DistrictOut.model_validate(farm.district),
        size_acres=farm.size_acres,
        soil_type=farm.soil_type,
        water_availability=farm.water_availability,
        budget=farm.budget,
        target_season=farm.target_season,
        created_at=farm.created_at,
        last_recommendation_at=last_recommendation.created_at if last_recommendation else None,
    )


def _get_owned_farm(farm_id: uuid.UUID, farmer: Farmer, db: Session) -> Farm:
    farm = db.query(Farm).filter(Farm.id == farm_id, Farm.farmer_id == farmer.id).first()
    if farm is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Farm not found")
    return farm


@router.get("", response_model=list[FarmOut])
def list_farms(
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farms = (
        db.query(Farm)
        .filter(Farm.farmer_id == current_farmer.id)
        .order_by(Farm.created_at.desc())
        .all()
    )
    return [_to_farm_out(f, db) for f in farms]


@router.post("", response_model=FarmOut, status_code=status.HTTP_201_CREATED)
def create_farm(
    payload: FarmCreate,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    district = db.get(District, payload.district_id)
    if district is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown district_id")

    farm = Farm(
        farmer_id=current_farmer.id,
        farm_name=payload.farm_name,
        location=payload.location,
        district_id=payload.district_id,
        size_acres=payload.size_acres,
        soil_type=payload.soil_type,
        water_availability=payload.water_availability,
        budget=payload.budget,
        target_season=payload.target_season,
    )
    db.add(farm)
    db.commit()
    db.refresh(farm)
    return _to_farm_out(farm, db)


@router.get("/{farm_id}", response_model=FarmOut)
def get_farm(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)
    return _to_farm_out(farm, db)


@router.get("/{farm_id}/conditions", response_model=ConditionsOut)
async def get_farm_conditions(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)

    if farm.district.center_lat is None or farm.district.center_lng is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Weather data unavailable for this district",
        )

    try:
        conditions = await fetch_current_conditions(farm.district.center_lat, farm.district.center_lng)
    except WeatherServiceError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Could not fetch live conditions right now",
        )

    return ConditionsOut(**conditions)


@router.get("/{farm_id}/forecast", response_model=list[ForecastDayOut])
async def get_farm_forecast(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)

    if farm.district.center_lat is None or farm.district.center_lng is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Weather data unavailable for this district",
        )

    try:
        forecast = await fetch_forecast(farm.district.center_lat, farm.district.center_lng)
    except WeatherServiceError:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Could not fetch forecast right now",
        )

    return [ForecastDayOut(**day) for day in forecast]


@router.patch("/{farm_id}", response_model=FarmOut)
def update_farm(
    farm_id: uuid.UUID,
    payload: FarmUpdate,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)

    updates = payload.model_dump(exclude_unset=True)
    if "district_id" in updates and db.get(District, updates["district_id"]) is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown district_id")

    old_size_acres = farm.size_acres
    for field, value in updates.items():
        setattr(farm, field, value)

    if "size_acres" in updates and required_points_for_area(old_size_acres) != required_points_for_area(
        farm.size_acres
    ):
        # The point layout for this farm's tier just changed shape — any in-progress reading's
        # partially-filled points no longer match the new required set, so it can't continue.
        # A completed reading stays valid as history; it was correct for the size at the time.
        stale_recommendation = (
            db.query(Recommendation)
            .filter(Recommendation.farm_id == farm.id, Recommendation.status == "in_progress")
            .first()
        )
        if stale_recommendation is not None:
            db.delete(stale_recommendation)

    db.commit()
    db.refresh(farm)
    return _to_farm_out(farm, db)


@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farm(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)
    db.delete(farm)
    db.commit()

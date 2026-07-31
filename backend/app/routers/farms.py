import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.db.session import get_db
from app.models.district import District
from app.models.farm import Farm
from app.models.farmer import Farmer
from app.schemas.district import DistrictOut
from app.schemas.farm import FarmCreate, FarmOut, FarmUpdate

router = APIRouter(prefix="/farms", tags=["farms"])


def _to_farm_out(farm: Farm) -> FarmOut:
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
        # No RECOMMENDATION table yet (future increment) — always null for now.
        last_recommendation_at=None,
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
    return [_to_farm_out(farm) for farm in farms]


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
    return _to_farm_out(farm)


@router.get("/{farm_id}", response_model=FarmOut)
def get_farm(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)
    return _to_farm_out(farm)


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

    for field, value in updates.items():
        setattr(farm, field, value)

    db.commit()
    db.refresh(farm)
    return _to_farm_out(farm)


@router.delete("/{farm_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_farm(
    farm_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_farmer: Farmer = Depends(get_current_farmer),
):
    farm = _get_owned_farm(farm_id, current_farmer, db)
    db.delete(farm)
    db.commit()

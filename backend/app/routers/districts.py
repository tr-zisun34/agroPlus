from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer
from app.db.session import get_db
from app.models.district import District
from app.schemas.district import DistrictOut

router = APIRouter(prefix="/districts", tags=["districts"])


@router.get("", response_model=list[DistrictOut])
def list_districts(
    db: Session = Depends(get_db),
    _current_farmer=Depends(get_current_farmer),
):
    return db.query(District).order_by(District.name).all()

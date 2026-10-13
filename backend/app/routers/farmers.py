from fastapi import APIRouter, Depends

from app.core.dependencies import get_current_farmer
from app.models.farmer import Farmer
from app.schemas.farmer import FarmerOut

router = APIRouter(prefix="/farmers", tags=["farmers"])


@router.get("/me", response_model=FarmerOut)
def read_current_farmer(current_farmer: Farmer = Depends(get_current_farmer)):
    return current_farmer

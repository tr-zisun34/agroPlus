import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.district import DistrictOut

SoilType = Literal["Clay", "Loamy", "Sandy", "Silty"]
WaterAvailability = Literal["Irrigated", "Rain-fed", "Limited"]
TargetSeason = Literal["Rabi", "Aus", "Aman"]


class FarmCreate(BaseModel):
    farm_name: str = Field(min_length=1)
    location: str = Field(min_length=1)
    district_id: uuid.UUID
    size_acres: float = Field(gt=0)
    soil_type: SoilType
    water_availability: WaterAvailability
    budget: float = Field(gt=0)
    target_season: TargetSeason


class FarmUpdate(BaseModel):
    farm_name: str | None = Field(default=None, min_length=1)
    location: str | None = Field(default=None, min_length=1)
    district_id: uuid.UUID | None = None
    size_acres: float | None = Field(default=None, gt=0)
    soil_type: SoilType | None = None
    water_availability: WaterAvailability | None = None
    budget: float | None = Field(default=None, gt=0)
    target_season: TargetSeason | None = None


class FarmOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_name: str
    location: str
    district: DistrictOut
    size_acres: float
    soil_type: str
    water_availability: str
    budget: float
    target_season: str
    created_at: datetime
    last_recommendation_at: datetime | None = None


class ConditionsOut(BaseModel):
    temperature: float
    humidity: float
    rainfall: float
    fetched_at: datetime


class ForecastDayOut(BaseModel):
    date: str
    temp_max_c: float
    temp_min_c: float
    precipitation_mm: float

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SamplePointIn(BaseModel):
    n: float = Field(ge=0)
    p: float = Field(ge=0)
    k: float = Field(ge=0)
    ph: float = Field(ge=0, le=14)


class SamplePointOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    point_label: str
    n: float
    p: float
    k: float
    ph: float


class RecommendationCropOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    rank: int
    crop: str
    confidence: float
    yield_estimate: float | None
    net_profit: float | None


class RecommendationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    farm_id: uuid.UUID
    created_at: datetime
    status: str
    composite_n: float | None
    composite_p: float | None
    composite_k: float | None
    composite_ph: float | None
    points: list[SamplePointOut]
    top_crops: list[RecommendationCropOut]


class RecommendationSummary(BaseModel):
    id: uuid.UUID
    created_at: datetime
    top_crop: str
    top_confidence: float

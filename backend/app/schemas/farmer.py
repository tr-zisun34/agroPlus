import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, ConfigDict


class FarmerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    email: EmailStr
    phone: str
    home_address: str | None
    created_at: datetime


class FarmerUpdate(BaseModel):
    name: str | None = None
    phone: str | None = None
    home_address: str | None = None

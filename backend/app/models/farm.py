import uuid
from datetime import datetime, timezone

from sqlalchemy import CheckConstraint, DateTime, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.district import District

SOIL_TYPES = ("Clay", "Loamy", "Sandy", "Silty")
WATER_AVAILABILITY_OPTIONS = ("Irrigated", "Rain-fed", "Limited")
TARGET_SEASONS = ("Rabi", "Aus", "Aman")


class Farm(Base):
    __tablename__ = "farm"
    __table_args__ = (
        CheckConstraint(f"soil_type IN {SOIL_TYPES}", name="ck_farm_soil_type"),
        CheckConstraint(f"water_availability IN {WATER_AVAILABILITY_OPTIONS}", name="ck_farm_water_availability"),
        CheckConstraint(f"target_season IN {TARGET_SEASONS}", name="ck_farm_target_season"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farmer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("farmer.id", ondelete="CASCADE"), nullable=False, index=True
    )
    farm_name: Mapped[str] = mapped_column(String, nullable=False)
    location: Mapped[str] = mapped_column(String, nullable=False)
    district_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("district.id"), nullable=False
    )
    district: Mapped[District] = relationship(lazy="joined")
    size_acres: Mapped[float] = mapped_column(Float, nullable=False)
    soil_type: Mapped[str] = mapped_column(String, nullable=False)
    water_availability: Mapped[str] = mapped_column(String, nullable=False)
    budget: Mapped[float] = mapped_column(Float, nullable=False)
    target_season: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

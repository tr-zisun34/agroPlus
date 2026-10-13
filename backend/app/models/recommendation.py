import uuid
from datetime import datetime, timezone

from sqlalchemy import CheckConstraint, DateTime, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

RECOMMENDATION_STATUSES = ("in_progress", "complete")


class Recommendation(Base):
    __tablename__ = "recommendation"
    __table_args__ = (
        CheckConstraint(f"status IN {RECOMMENDATION_STATUSES}", name="ck_recommendation_status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("farm.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    status: Mapped[str] = mapped_column(String, nullable=False, default="in_progress")

    composite_n: Mapped[float | None] = mapped_column(Float, nullable=True)
    composite_p: Mapped[float | None] = mapped_column(Float, nullable=True)
    composite_k: Mapped[float | None] = mapped_column(Float, nullable=True)
    composite_ph: Mapped[float | None] = mapped_column(Float, nullable=True)

    points: Mapped[list["SamplePoint"]] = relationship(
        back_populates="recommendation", cascade="all, delete-orphan", lazy="selectin"
    )
    top_crops: Mapped[list["RecommendationCrop"]] = relationship(
        back_populates="recommendation",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="RecommendationCrop.rank",
    )

import uuid

from sqlalchemy import Float, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class RecommendationCrop(Base):
    __tablename__ = "recommendation_crop"
    __table_args__ = (
        UniqueConstraint("recommendation_id", "rank", name="uq_recommendation_crop_rank"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recommendation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("recommendation.id", ondelete="CASCADE"), nullable=False, index=True
    )
    rank: Mapped[int] = mapped_column(Integer, nullable=False)
    crop: Mapped[str] = mapped_column(String, nullable=False)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    yield_estimate: Mapped[float | None] = mapped_column(Float, nullable=True)
    net_profit: Mapped[float | None] = mapped_column(Float, nullable=True)
    total_cost: Mapped[float | None] = mapped_column(Float, nullable=True)

    recommendation: Mapped["Recommendation"] = relationship(back_populates="top_crops")

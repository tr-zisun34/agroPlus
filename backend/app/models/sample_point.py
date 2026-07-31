import uuid

from sqlalchemy import Float, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class SamplePoint(Base):
    __tablename__ = "sample_point"
    __table_args__ = (
        UniqueConstraint("recommendation_id", "point_label", name="uq_sample_point_recommendation_label"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recommendation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("recommendation.id", ondelete="CASCADE"), nullable=False, index=True
    )
    point_label: Mapped[str] = mapped_column(String, nullable=False)
    n: Mapped[float] = mapped_column(Float, nullable=False)
    p: Mapped[float] = mapped_column(Float, nullable=False)
    k: Mapped[float] = mapped_column(Float, nullable=False)
    ph: Mapped[float] = mapped_column(Float, nullable=False)

    recommendation: Mapped["Recommendation"] = relationship(back_populates="points")

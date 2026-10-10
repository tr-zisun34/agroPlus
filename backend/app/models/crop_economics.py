import uuid
from datetime import date

from sqlalchemy import JSON, Date, Float, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class CropEconomics(Base):
    """National-average yield/price per crop(/variety) — not farmer-editable, seeded from
    DAM (price) and BAMIS (yield). Values are normalized to kg and BDT/kg regardless of the
    source document's original units (e.g. quintal, bigha), so downstream math never has to
    convert. Varieties (e.g. rice's amon/boro x local/hybrid grades) are kept as distinct rows
    rather than averaged away, since DAM prices them separately and the app may let a farmer
    pick a variety later; the ML model only ever outputs a generic crop name, so
    get_profit_estimate averages across a crop's variety rows for that single automatic figure."""

    __tablename__ = "crop_economics"
    __table_args__ = (UniqueConstraint("crop", "variety", name="uq_crop_economics_crop_variety"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    crop: Mapped[str] = mapped_column(String, index=True, nullable=False)
    variety: Mapped[str] = mapped_column(String, nullable=False, default="")
    yield_kg_per_acre: Mapped[float] = mapped_column(Float, nullable=False)
    price_bdt_per_kg: Mapped[float] = mapped_column(Float, nullable=False)
    # BAMIS's own bundled per-acre production cost estimate (seed + fertilizer + labor +
    # irrigation, not broken out) — this is what drives net_profit now, not the farmer's budget.
    cost_bdt_per_acre: Mapped[float | None] = mapped_column(Float, nullable=True)
    # BADC/DAM seed price x BAMIS seed rate — one line item within cost_bdt_per_acre.
    seed_cost_bdt_per_acre: Mapped[float | None] = mapped_column(Float, nullable=True)
    # BAMIS's per-crop fertilizer recipe (Urea/TSP/DAP/MoP/Gypsum/Zinc, kg/acre) costed out
    # against real DAM fertilizer prices — the other sourced line item within cost_bdt_per_acre.
    # Null when the recipe can't be priced (e.g. Mango's is per-tree, not per-acre).
    fertilizer_cost_bdt_per_acre: Mapped[float | None] = mapped_column(Float, nullable=True)
    # {"urea": {"qty_kg_per_acre": ..., "price_bdt_per_kg": ..., "cost_bdt_per_acre": ...}, ...}
    fertilizer_breakdown: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    # Whatever's left of cost_bdt_per_acre after subtracting seed + fertilizer — labor,
    # irrigation, land prep, etc. that neither BAMIS nor DAM price out individually. Always
    # seed_cost + fertilizer_cost + other_cost == cost_bdt_per_acre.
    other_cost_bdt_per_acre: Mapped[float | None] = mapped_column(Float, nullable=True)
    # Verbatim BAMIS cultivation-season text (e.g. "Kharif-2 (Jul - Dec)") — shown as-is rather
    # than converted to a day count, since several crops have dual/ambiguous seasons.
    season_label: Mapped[str | None] = mapped_column(String, nullable=True)
    source: Mapped[str | None] = mapped_column(String, nullable=True)
    as_of_date: Mapped[date | None] = mapped_column(Date, nullable=True)

"""seed district coordinates

Revision ID: d3b7b2b4892c
Revises: 076253ea38ba
Create Date: 2026-07-31 14:19:14.463248

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd3b7b2b4892c'
down_revision: Union[str, Sequence[str], None] = '076253ea38ba'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Approximate district-town coordinates (2 decimal places) — precise enough for
# district-level weather lookups, not survey-grade.
DISTRICT_COORDINATES = {
    "Barisal": (22.70, 90.37), "Barguna": (22.09, 90.11), "Bhola": (22.68, 90.65),
    "Jhalokati": (22.64, 90.20), "Patuakhali": (22.35, 90.33), "Pirojpur": (22.59, 89.97),
    "Bandarban": (22.20, 92.22), "Brahmanbaria": (23.96, 91.11), "Chandpur": (23.23, 90.65),
    "Chattogram": (22.36, 91.78), "Cumilla": (23.46, 91.18), "Cox's Bazar": (21.44, 91.98),
    "Feni": (23.02, 91.40), "Khagrachhari": (23.12, 91.98), "Lakshmipur": (22.94, 90.83),
    "Noakhali": (22.87, 91.10), "Rangamati": (22.65, 92.17),
    "Dhaka": (23.81, 90.41), "Faridpur": (23.60, 89.84), "Gazipur": (23.99, 90.42),
    "Gopalganj": (23.01, 89.83), "Kishoreganj": (24.44, 90.78), "Madaripur": (23.16, 90.19),
    "Manikganj": (23.86, 90.00), "Munshiganj": (23.54, 90.53), "Narayanganj": (23.62, 90.50),
    "Narsingdi": (23.92, 90.72), "Rajbari": (23.76, 89.65), "Shariatpur": (23.24, 90.43),
    "Tangail": (24.25, 89.92),
    "Bagerhat": (22.65, 89.79), "Chuadanga": (23.64, 88.84), "Jashore": (23.17, 89.21),
    "Jhenaidah": (23.54, 89.15), "Khulna": (22.82, 89.55), "Kushtia": (23.90, 89.12),
    "Magura": (23.49, 89.42), "Meherpur": (23.76, 88.63), "Narail": (23.17, 89.51),
    "Satkhira": (22.71, 89.07),
    "Jamalpur": (24.94, 89.94), "Mymensingh": (24.75, 90.40), "Netrokona": (24.87, 90.73),
    "Sherpur": (25.02, 90.02),
    "Bogura": (24.85, 89.37), "Chapainawabganj": (24.60, 88.28), "Joypurhat": (25.10, 89.02),
    "Naogaon": (24.80, 88.94), "Natore": (24.42, 88.98), "Pabna": (24.00, 89.24),
    "Rajshahi": (24.37, 88.60), "Sirajganj": (24.45, 89.70),
    "Dinajpur": (25.63, 88.64), "Gaibandha": (25.33, 89.53), "Kurigram": (25.81, 89.63),
    "Lalmonirhat": (25.92, 89.44), "Nilphamari": (25.93, 88.86), "Panchagarh": (26.34, 88.56),
    "Rangpur": (25.75, 89.25), "Thakurgaon": (26.03, 88.47),
    "Habiganj": (24.38, 91.42), "Moulvibazar": (24.48, 91.78), "Sunamganj": (25.07, 91.40),
    "Sylhet": (24.90, 91.87),
}


def upgrade() -> None:
    """Upgrade schema."""
    district_table = sa.table(
        "district",
        sa.column("name", sa.String()),
        sa.column("center_lat", sa.Float()),
        sa.column("center_lng", sa.Float()),
    )
    connection = op.get_bind()
    for name, (lat, lng) in DISTRICT_COORDINATES.items():
        connection.execute(
            district_table.update()
            .where(district_table.c.name == name)
            .values(center_lat=lat, center_lng=lng)
        )


def downgrade() -> None:
    """Downgrade schema."""
    district_table = sa.table(
        "district",
        sa.column("center_lat", sa.Float()),
        sa.column("center_lng", sa.Float()),
    )
    op.execute(district_table.update().values(center_lat=None, center_lng=None))

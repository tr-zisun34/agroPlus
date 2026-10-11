"""add cropping pattern, rotation history, and season classification

Revision ID: a7709154522d
Revises: f8d47b7e05bd
Create Date: 2026-10-10 23:13:15.191900

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a7709154522d'
down_revision: Union[str, Sequence[str], None] = 'f8d47b7e05bd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('crop_economics', sa.Column('season', sa.String(), nullable=True))
    op.add_column(
        'farm',
        sa.Column('cropping_pattern', sa.String(), nullable=False, server_default='single'),
    )
    op.add_column('farm', sa.Column('previous_crop_1', sa.String(), nullable=True))
    op.add_column('farm', sa.Column('previous_crop_2', sa.String(), nullable=True))
    op.create_check_constraint(
        'ck_farm_cropping_pattern', 'farm', "cropping_pattern IN ('single', 'double', 'triple')"
    )
    op.add_column('recommendation_crop', sa.Column('season', sa.String(), nullable=True))
    op.add_column('recommendation_crop', sa.Column('rotation_note', sa.String(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('recommendation_crop', 'rotation_note')
    op.drop_column('recommendation_crop', 'season')
    op.drop_constraint('ck_farm_cropping_pattern', 'farm', type_='check')
    op.drop_column('farm', 'previous_crop_2')
    op.drop_column('farm', 'previous_crop_1')
    op.drop_column('farm', 'cropping_pattern')
    op.drop_column('crop_economics', 'season')

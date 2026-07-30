from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


# Import all models here so Alembic autogenerate can discover them via Base.metadata.
from app.models.farmer import Farmer  # noqa: E402,F401

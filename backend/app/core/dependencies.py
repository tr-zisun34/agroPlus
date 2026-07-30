import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_token
from app.db.session import get_db
from app.models.farmer import Farmer

bearer_scheme = HTTPBearer()


def get_current_farmer(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Farmer:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = decode_token(credentials.credentials)
    if payload is None or payload.get("type") != "access":
        raise credentials_exception

    try:
        farmer_id = uuid.UUID(payload.get("sub"))
    except (TypeError, ValueError):
        raise credentials_exception

    farmer = db.get(Farmer, farmer_id)
    if farmer is None:
        raise credentials_exception

    return farmer

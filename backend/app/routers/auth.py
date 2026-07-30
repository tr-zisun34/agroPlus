import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.db.session import get_db
from app.models.farmer import Farmer
from app.schemas.auth import (
    AccessTokenResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(Farmer).filter(Farmer.email == payload.email).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    farmer = Farmer(
        name=payload.name,
        email=payload.email,
        phone=payload.phone,
        password_hash=hash_password(payload.password),
    )
    db.add(farmer)
    db.commit()
    db.refresh(farmer)

    return TokenResponse(
        access_token=create_access_token(farmer.id),
        refresh_token=create_refresh_token(farmer.id),
    )


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    farmer = db.query(Farmer).filter(Farmer.email == payload.email).first()
    if farmer is None or not verify_password(payload.password, farmer.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    return TokenResponse(
        access_token=create_access_token(farmer.id),
        refresh_token=create_refresh_token(farmer.id),
    )


@router.post("/refresh", response_model=AccessTokenResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    invalid_token_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token"
    )

    token_payload = decode_token(payload.refresh_token)
    if token_payload is None or token_payload.get("type") != "refresh":
        raise invalid_token_exception

    try:
        farmer_id = uuid.UUID(token_payload.get("sub"))
    except (TypeError, ValueError):
        raise invalid_token_exception

    farmer = db.get(Farmer, farmer_id)
    if farmer is None:
        raise invalid_token_exception

    return AccessTokenResponse(access_token=create_access_token(farmer.id))

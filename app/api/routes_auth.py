import logging
import re
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from app.schemas.auth import LoginRequest, TokenResponse, TokenDataResponse
from app.core.security import create_jwt, get_current_user
from app.db.session import SessionLocal
from app.models.staff import Staff

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["auth"])

DATE_FORMATS = (
    "%d/%m/%Y",
    "%d-%m-%Y",
    "%Y-%m-%d",
    "%Y/%m/%d",
    "%d%m%Y",
    "%Y%m%d",
)


def digits_only(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\D", "", value)


def normalize_dob(value: str | None) -> str | None:
    if not value:
        return None
    text = value.strip()
    if not text:
        return None
    for fmt in DATE_FORMATS:
        try:
            parsed = datetime.strptime(text, fmt)
            return parsed.strftime("%d%m%Y")
        except ValueError:
            continue
    digits = digits_only(text)
    return digits if digits else None


def matches_dob_password(password: str, dob: str | None) -> bool:
    dob_digits = normalize_dob(dob)
    if not dob_digits:
        return False
    candidate = digits_only(password)
    if candidate == dob_digits:
        return True
    # Accept DDMMYY if the stored DOB is DDMMYYYY
    if len(dob_digits) == 8 and len(candidate) == 6 and dob_digits.endswith(candidate[-6:]):
        return True
    return False


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, response: Response, db: Session = Depends(get_db)):
    username = (payload.username or "").strip()
    password = (payload.password or "").strip()
    if not password or not username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Username and password required"
        )
    contact_digits = digits_only(username)
    user = (
        db.query(Staff)
        .filter(
            or_(
                func.lower(Staff.name) == func.lower(username),
                Staff.contact == username,
                Staff.contact == contact_digits,
            )
        )
        .first()
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    valid_password = user.password == password or matches_dob_password(password, user.dob)
    if not valid_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    token = create_jwt(
        {
            "user_id": user.id,
            "role": user.role,
            "department_id": user.department_id,
            "name": user.name,
            "designation": user.designation,
        }
    )
    token_response = TokenResponse(
        access_token=token,
        role=user.role,
        name=user.name,
        department_id=user.department_id,
        user_id=user.id,
        designation=user.designation,
    )
    response.set_cookie(
        "token",
        token,
        httponly=True,
        secure=False,
        samesite="lax",
        path="/",
    )
    logger.info("login response %s", token_response.dict(exclude={"access_token"}))
    return token_response


@router.get("/users", response_model=list[str])
def list_users(q: str | None = None, limit: int = 50, db: Session = Depends(get_db)):
    query = db.query(Staff.name)
    if q:
        query = query.filter(Staff.name.ilike(f"%{q}%"))
    names = query.order_by(Staff.name).limit(limit).all()
    return [name for name, in names]


@router.get("/me", response_model=TokenDataResponse)
def me(user=Depends(get_current_user)):
    return TokenDataResponse(
        user_id=user.user_id,
        role=user.role,
        name=user.name,
        department_id=user.department_id,
        designation=user.designation,
    )


@router.post("/logout")
def logout(response: Response):
    response.delete_cookie("token", path="/")
    return {"detail": "Logged out"}

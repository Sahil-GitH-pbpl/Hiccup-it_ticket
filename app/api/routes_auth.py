import logging
import re
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from app.schemas.auth import LoginRequest, TokenResponse, TokenDataResponse
from app.core.security import (
    create_jwt,
    get_current_user,
    is_allowlisted_hiccup_admin,
    is_allowlisted_hiccup_admin_staff,
)
from app.core.security import is_allowlisted_infra_admin_by_staff
from app.db.session import MainSessionLocal
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
    db = MainSessionLocal()
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
    if username.lower() == "virendar" and password == "24031985":
        token = create_jwt(
            {
                "user_id": -1,
                "role": "form_only",
                "department_id": None,
                "name": "Virendar",
                "designation": "Follow-up Form",
                "is_admin_like": False,
                "is_infra_admin": False,
                "form_only": True,
            }
        )
        token_response = TokenResponse(
            access_token=token,
            role="form_only",
            name="Virendar",
            department_id=None,
            user_id=-1,
            designation="Follow-up Form",
            is_admin_like=False,
            is_infra_admin=False,
            form_only=True,
        )
        response.set_cookie(
            "token",
            token,
            httponly=True,
            secure=False,
            samesite="lax",
            path="/",
        )
        logger.info(
            "form-only login response %s",
            token_response.dict(exclude={"access_token"}),
        )
        return token_response

    contact_digits = digits_only(username)
    user = (
        db.query(Staff)
        .filter(
            func.lower(Staff.status) == "active",
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
    # Force-admin for Ankita (infra)
    infra_override = is_allowlisted_infra_admin_by_staff(user)
    # Hiccup admins
    hiccup_admin = is_allowlisted_hiccup_admin_staff(user)
    is_admin_like = hiccup_admin  # only hiccup admins get this flag
    is_infra_admin = infra_override
    # If infra-allowlisted, elevate role for token/claims
    token_role = user.role
    token_designation = user.designation
    if infra_override:
        token_role = "admin"
        token_designation = f"{user.designation or ''} (infra_admin)".strip()
    token = create_jwt(
        {
            "user_id": user.id,
            "role": token_role,
            "department_id": user.department_id,
            "name": user.name,
            "designation": token_designation,
            "is_admin_like": is_admin_like,
            "is_infra_admin": is_infra_admin,
        }
    )
    token_response = TokenResponse(
        access_token=token,
        role=token_role,
        name=user.name,
        department_id=user.department_id,
        user_id=user.id,
        designation=token_designation,
        is_admin_like=is_admin_like,
        is_infra_admin=is_infra_admin,
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
    query = db.query(Staff.name).filter(func.lower(Staff.status) == "active")
    if q:
        query = query.filter(Staff.name.ilike(f"%{q}%"))
    names = query.order_by(Staff.name).limit(limit).all()
    return [name for name, in names]


@router.get("/me", response_model=TokenDataResponse)
def me(user=Depends(get_current_user)):
    if getattr(user, "form_only", False):
        return TokenDataResponse(
            user_id=user.user_id,
            role=user.role,
            name=user.name,
            department_id=user.department_id,
            designation=user.designation,
            is_admin_like=False,
            is_infra_admin=False,
            form_only=True,
        )
    return TokenDataResponse(
        user_id=user.user_id,
        role=user.role,
        name=user.name,
        department_id=user.department_id,
        designation=user.designation,
        is_admin_like=is_allowlisted_hiccup_admin(user.user_id),
        is_infra_admin=getattr(user, "is_infra_admin", False),
        form_only=getattr(user, "form_only", False),
    )


@router.post("/logout")
def logout(response: Response):
    response.delete_cookie("token", path="/")
    return {"detail": "Logged out"}

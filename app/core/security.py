from base64 import urlsafe_b64decode, urlsafe_b64encode
from datetime import datetime, timedelta
from typing import Optional
import hmac
import hashlib
import re
import time

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError

from app.core.config import get_settings
from app.db.session import MainSessionLocal
from app.models.staff import Staff

settings = get_settings()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)

ALLOWED_HICCUP_ADMINS = [
    {"name": "dr vishu bhasin", "contact": "9810637037", "dob": "24031985"},
    {"name": "dr vipul bhasin", "contact": "9810030372", "dob": "21031991"},
]

# Allowlisted infra admin (ankita)
ALLOWED_INFRA_ADMINS = [
    {"name": "ankita", "contact": "8700004157", "employee_code": "PBPL00188"},
]


def _digits(value: Optional[str]) -> str:
    return re.sub(r"\D", "", value or "")


def is_allowlisted_infra_admin_by_staff(staff: Staff) -> bool:
    """
    Allowlist specific staff for infra admin rights based on name/contact and optional employee code.
    We try multiple fields because the schema lacks a dedicated employee_code column.
    """
    if not staff:
        return False
    normalized_name = (staff.name or "").strip().lower()
    mobile_number = _digits(staff.contact)

    candidate_codes = set()
    for val in [
        getattr(staff, "employee_code", None),  # if such a column exists
        staff.password,  # stored code in this schema
        staff.departments,
        staff.role,
        staff.designation,
        staff.department_id,
    ]:
        if val is None:
            continue
        text = str(val).strip()
        if text:
            candidate_codes.add(text.upper())

    for entry in ALLOWED_INFRA_ADMINS:
        if normalized_name != entry["name"]:
            continue
        if mobile_number != entry["contact"]:
            continue
        code_needed = entry.get("employee_code")
        if not code_needed:
            return True
        if code_needed in candidate_codes:
            return True
        # If code is not present in schema, still allow based on name+contact to avoid false block
        if not candidate_codes:
            return True
    return False


def is_allowlisted_hiccup_admin(user_id: Optional[int]) -> bool:
    if not user_id:
        return False
    db = MainSessionLocal()
    try:
        staff = db.query(Staff).filter(Staff.id == user_id).first()
        return is_allowlisted_hiccup_admin_staff(staff)
    finally:
        try:
            db.close()
        except Exception:
            pass


def is_allowlisted_hiccup_admin_staff(staff: Optional[Staff]) -> bool:
    if not staff:
        return False
    # Hiccup admins: explicit allowlist only (no infra override)
    name = (staff.name or "").strip().lower()
    contact = _digits(staff.contact)
    dob_digits = _digits(staff.dob)
    for entry in ALLOWED_HICCUP_ADMINS:
        if (
            name == entry["name"]
            and contact == entry["contact"]
            and dob_digits == entry["dob"]
        ):
            return True
    return False


class TokenData:
    def __init__(
        self,
        user_id: int,
        role: str,
        department_id: Optional[int],
        name: str,
        designation: Optional[str] = None,
        is_admin_like: bool = False,
        is_infra_admin: bool = False,
    ):
        self.user_id = user_id
        self.role = role
        self.department_id = department_id
        self.name = name
        self.designation = designation or ""
        self.is_admin_like = is_admin_like
        self.is_infra_admin = is_infra_admin


def create_jwt(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=8))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.jwt_secret, algorithm=settings.jwt_algo
    )
    return encoded_jwt


def _pad_base64(value: str) -> str:
    return value + "=" * (-len(value) % 4)


def _to_int(value):
    try:
        return int(value)
    except Exception:
        return None


def _sign_compact(body: bytes, length: int = 8) -> bytes:
    return hmac.new(
        settings.jwt_secret.encode("utf-8"), body, hashlib.sha256
    ).digest()[:length]


def create_public_response_token(
    data: dict, expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create a compact, signed public-response token (shorter than a JWT).
    Layout (pipe-delimited): hiccup_id|user_id|role|department_id|exp_epoch
    Signed with HMAC-SHA256 (truncated) and base64url encoded with prefix c2.
    """
    expires = datetime.utcnow() + (expires_delta or timedelta(days=3))
    fields = [
        str(data.get("hiccup_id") or ""),
        str(data.get("user_id") or ""),
        str(data.get("role") or "external"),
        "" if data.get("department_id") is None else str(data.get("department_id")),
        str(int(expires.timestamp())),
    ]
    body = "|".join(fields).encode("utf-8")
    signature = _sign_compact(body, length=8)
    token_bytes = body + b"." + signature
    token = urlsafe_b64encode(token_bytes).decode("utf-8").rstrip("=")
    return f"c2.{token}"


def decode_jwt(token: str) -> TokenData:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algo])
        return TokenData(
            user_id=int(payload.get("user_id")),
            role=payload.get("role"),
            department_id=payload.get("department_id"),
            name=payload.get("name", "User"),
            designation=payload.get("designation"),
            is_admin_like=bool(payload.get("is_admin_like")),
            is_infra_admin=bool(payload.get("is_infra_admin")),
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
        )


def _get_token_from_request(
    request: Request, token: Optional[str] = Depends(oauth2_scheme)
) -> str:
    if token:
        return token
    cookie_token = request.cookies.get("token")
    if cookie_token:
        return cookie_token
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated"
    )


def get_current_user(token: str = Depends(_get_token_from_request)) -> TokenData:
    return decode_jwt(token)


def _has_management_access(designation: Optional[str], role: Optional[str]) -> bool:
    """
    Determine if a user should have management/admin access.
    Primary check: designation contains management keywords.
    Fallback: role is admin/management (for older tokens or data without designation).
    """
    keywords = ["management", "manager", "admin", "supervisor", "lead"]
    if designation:
        text = designation.lower()
        if any(key in text for key in keywords):
            return True
    if role:
        role_text = role.lower()
        if role_text in {"admin", "management"}:
            return True
    return False


def require_management(user: TokenData = Depends(get_current_user)) -> TokenData:
    if not is_allowlisted_hiccup_admin(user.user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Management designation required"
        )
    return user


def require_admin(user: TokenData = Depends(get_current_user)) -> TokenData:
    if not is_allowlisted_hiccup_admin(user.user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin role required"
        )
    return user


def _try_decode_compact_public_token_v2(token: str) -> Optional[dict]:
    """
    Decode the short c2.* token (pipe-delimited payload + truncated HMAC).
    """
    if not token.startswith("c2."):
        return None
    raw = token[3:]
    try:
        decoded = urlsafe_b64decode(_pad_base64(raw))
        body, signature = decoded.rsplit(b".", 1)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid public token"
        )
    expected = _sign_compact(body, length=len(signature))
    if not hmac.compare_digest(signature, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid public token"
        )
    try:
        hiccup_id, user_id_raw, role, dept_raw, exp_raw = body.decode("utf-8").split(
            "|", 4
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid public token"
        )
    exp_ts = _to_int(exp_raw)
    if exp_ts and exp_ts < int(time.time()):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Public token expired"
        )
    return {
        "purpose": "response_link",
        "hiccup_id": hiccup_id,
        "user_id": _to_int(user_id_raw),
        "role": role or "external",
        "department_id": _to_int(dept_raw),
        "name": None,
    }


def _decode_public_jwt(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algo])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid public token"
        )
    return payload


def decode_public_token(token: str, *, purpose: str) -> dict:
    """Decode an externally issued token (e.g. public response link)."""
    payload = _try_decode_compact_public_token_v2(token)
    if payload is None:
        payload = _decode_public_jwt(token)
    if payload.get("purpose") != purpose:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token does not match expected purpose",
        )
    return payload

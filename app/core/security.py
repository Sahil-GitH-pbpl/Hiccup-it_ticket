from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError

from app.core.config import get_settings

settings = get_settings()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)


class TokenData:
    def __init__(
        self,
        user_id: int,
        role: str,
        department_id: Optional[int],
        name: str,
        designation: Optional[str] = None,
    ):
        self.user_id = user_id
        self.role = role
        self.department_id = department_id
        self.name = name
        self.designation = designation or ""


def create_jwt(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=8))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.jwt_secret, algorithm=settings.jwt_algo
    )
    return encoded_jwt


def decode_jwt(token: str) -> TokenData:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algo])
        return TokenData(
            user_id=int(payload.get("user_id")),
            role=payload.get("role"),
            department_id=payload.get("department_id"),
            name=payload.get("name", "User"),
            designation=payload.get("designation"),
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
    if not _has_management_access(user.designation, user.role):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Management designation required"
        )
    return user


def require_admin(user: TokenData = Depends(get_current_user)) -> TokenData:
    if not _has_management_access(user.designation, user.role):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin role required"
        )
    return user


def decode_public_token(token: str, *, purpose: str) -> dict:
    """Decode an externally issued token (e.g. public response link)."""
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algo])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid public token"
        )
    if payload.get("purpose") != purpose:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token does not match expected purpose",
        )
    return payload

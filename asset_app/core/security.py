from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.security import decode_jwt as decode_hiccup_jwt
from asset_app.core.config import settings
from asset_app.db.session import get_db
from asset_app.models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)
ROLE_CODES = {1: "administrator", 2: "technician", 3: "asset_manager", 7: "employee"}


def load_active_user(db: Session, user_id: int) -> User:
    user = db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Inactive or missing user")
    if (
        user.role_id not in ROLE_CODES
        or user.role_name != ROLE_CODES[user.role_id]
        or user.role is None
    ):
        raise HTTPException(status_code=403, detail="Invalid asset role assignment")
    return user


def create_token(user: User) -> str:
    return jwt.encode(
        {"sub": str(user.id), "role": user.role.name,
         "exp": datetime.now(timezone.utc) + timedelta(hours=8)},
        settings.secret_key, algorithm="HS256",
    )


def current_user(
    request: Request,
    token: str | None = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    if token:
        try:
            payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
            user_id = int(payload["sub"])
        except (JWTError, KeyError, TypeError, ValueError):
            raise HTTPException(status_code=401, detail="Invalid authentication")
    else:
        cookie_token = request.cookies.get("token")
        if not cookie_token:
            raise HTTPException(status_code=401, detail="Not authenticated")
        user_id = decode_hiccup_jwt(cookie_token).user_id

    # Token identifies the user; current DB role/status decides access.
    user = load_active_user(db, user_id)
    db.commit()
    return user


def require_roles(*roles: str):
    def checker(user: User = Depends(current_user)):
        if user.role.name not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permission"
            )
        return user
    return checker

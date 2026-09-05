from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from asset_app.core.config import settings
from asset_app.db.session import get_db
from asset_app.models import Role, User
from app.core.security import decode_jwt as decode_hiccup_jwt
from app.core.security import is_allowlisted_hiccup_admin_staff
from app.db.session import MainSessionLocal
from app.models.staff import Staff

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)


def create_token(user: User) -> str:
    return jwt.encode({"sub": str(user.id), "role": user.role.name, "exp": datetime.now(timezone.utc)+timedelta(hours=8)}, settings.secret_key, algorithm="HS256")


def _asset_role_for_hiccup_user(staff: Staff | None, token_data) -> Role:
    role_name = "Employee"
    if bool(getattr(token_data, "is_admin_like", False)) or is_allowlisted_hiccup_admin_staff(staff):
        role_name = "Administrator"
    elif (
        bool(getattr(token_data, "is_infra_admin", False))
        or "admin" in (getattr(token_data, "role", "") or "").lower()
        or "it" in (getattr(token_data, "designation", "") or "").lower()
        or "infra" in (getattr(token_data, "designation", "") or "").lower()
    ):
        role_name = "Asset Manager"
    return role_name


def _sync_hiccup_user(db: Session, request: Request) -> User | None:
    cookie_token = request.cookies.get("token")
    if not cookie_token:
        return None
    token_data = decode_hiccup_jwt(cookie_token)
    main_db = MainSessionLocal()
    try:
        staff = main_db.get(Staff, token_data.user_id)
    finally:
        main_db.close()
    role_name = _asset_role_for_hiccup_user(staff, token_data)
    role = db.query(Role).filter(Role.name == role_name).first()
    if not role:
        role = db.query(Role).filter(Role.name == "Employee").first()
    user = db.get(User, token_data.user_id)
    if not user:
        contact = getattr(staff, "contact", None) or str(token_data.user_id)
        user = User(
            id=token_data.user_id,
            name=getattr(staff, "name", None) or token_data.name,
            password=getattr(staff, "password", None) or "",
            contact=contact,
            departments=str(getattr(staff, "departments", "") or ""),
            dob=getattr(staff, "dob", None),
            designation=getattr(staff, "designation", None) or token_data.designation,
            department_id=getattr(staff, "department_id", None) or token_data.department_id,
            role_name=role_name.lower().replace(" ", "_"),
            role_id=role.id if role else 7,
            status="Active",
        )
        db.add(user)
    else:
        user.name = getattr(staff, "name", None) or token_data.name
        user.designation = getattr(staff, "designation", None) or token_data.designation
        user.department_id = getattr(staff, "department_id", None) or token_data.department_id
        user.status = "Active"
    db.commit()
    db.refresh(user)
    _ = user.role.name
    return user


def current_user(
    request: Request,
    token: str | None = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    if not token:
        synced_user = _sync_hiccup_user(db, request)
        if synced_user:
            return synced_user
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload=jwt.decode(token, settings.secret_key, algorithms=['HS256'])
        user_id=int(payload['sub'])
    except (JWTError, KeyError, ValueError): raise HTTPException(status_code=401, detail="Invalid authentication")
    user=db.get(User,user_id)
    if not user or not user.is_active: raise HTTPException(status_code=401, detail="Inactive user")
    # Finish authentication's read transaction so workflow endpoints can open
    # their own explicit atomic transaction on the same request session.
    _ = user.role.name
    db.commit()
    return user
def require_roles(*roles: str):
    def checker(user: User = Depends(current_user)):
        if user.role.name not in roles: raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,detail="Insufficient permission")
        return user
    return checker

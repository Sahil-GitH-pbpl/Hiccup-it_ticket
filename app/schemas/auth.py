from typing import Optional
from pydantic import BaseModel


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    name: str
    department_id: Optional[int] = None
    user_id: int
    designation: Optional[str] = None
    is_admin_like: bool = False
    is_infra_admin: bool = False
    form_only: bool = False


class TokenDataResponse(BaseModel):
    user_id: int
    role: str
    name: str
    department_id: Optional[int]
    designation: Optional[str] = None
    is_admin_like: bool = False
    is_infra_admin: bool = False
    form_only: bool = False

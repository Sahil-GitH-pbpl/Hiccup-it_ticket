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


class TokenDataResponse(BaseModel):
    user_id: int
    role: str
    name: str
    department_id: Optional[int]
    designation: Optional[str] = None

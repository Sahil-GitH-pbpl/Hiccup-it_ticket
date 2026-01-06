from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.schemas.hiccup import AutoGenerateRequest, HiccupResponse
from app.core.config import get_settings
from app.services import hiccup_service
from app.integrations.whatsapp_client import send_bulk
from app.services.notification_service import notify_on_creation
from app.models.staff import Staff
from app.core.security import TokenData

router = APIRouter(prefix="/api/hiccup", tags=["internal"])
settings = get_settings()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/auto_generate", response_model=dict, status_code=201)
def auto_generate(
    payload: AutoGenerateRequest,
    x_internal_token: str = Header(""),
    db: Session = Depends(get_db),
):
    if x_internal_token != settings.internal_service_token:
        raise HTTPException(status_code=401, detail="Invalid token")
    system_user = db.query(Staff).filter(Staff.name == "System").first()
    if not system_user:
        system_user = Staff(name="System", role="Admin", department_id=None)
        db.add(system_user)
        db.commit()
        db.refresh(system_user)
    pseudo_user = TokenData(
        user_id=system_user.id,
        role=system_user.role,
        department_id=system_user.department_id,
        name=system_user.name,
    )
    data = payload
    if data.hiccup_type != "System Related":
        raise HTTPException(
            status_code=400, detail="Auto generation only for system hiccups"
        )
    hiccup = hiccup_service.create_hiccup(
        db, pseudo_user, data, [], is_auto=True, source_module=data.source_module
    )
    notify_on_creation(db, hiccup)
    return {"status": "success", "hiccup_id": hiccup.hiccup_id}

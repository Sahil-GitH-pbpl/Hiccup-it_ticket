from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.core.security import get_current_user
from app.services.report_service import dashboard_summary

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/summary")
def get_dashboard_summary(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return dashboard_summary(db, user.user_id)

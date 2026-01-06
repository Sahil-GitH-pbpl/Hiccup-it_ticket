from datetime import datetime
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.hiccup import Hiccup


def generate_hiccup_id(db: Session) -> str:
    year_suffix = datetime.utcnow().strftime("%y")
    count = (
        db.query(func.count(Hiccup.hiccup_id))
        .filter(Hiccup.hiccup_id.like(f"HCP-{year_suffix}-%"))
        .scalar()
    )
    seq = count + 1
    return f"HCP-{year_suffix}-{seq:03d}"

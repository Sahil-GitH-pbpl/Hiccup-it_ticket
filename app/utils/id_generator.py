from datetime import datetime
from sqlalchemy.orm import Session

from app.models.hiccup import Hiccup


def _parse_seq(hiccup_id: str) -> int:
    try:
        return int(hiccup_id.split("-")[-1])
    except Exception:
        return 0


def generate_hiccup_id(db: Session) -> str:
    """
    Generate HCP-YY-NNN that won't collide if rows are deleted (uses max seq, not count).
    """
    year_suffix = datetime.utcnow().strftime("%y")
    prefix = f"HCP-{year_suffix}-"
    rows = (
        db.query(Hiccup.hiccup_id)
        .filter(Hiccup.hiccup_id.like(f"{prefix}%"))
        .all()
    )
    last_seq = max((_parse_seq(row[0]) for row in rows), default=0)
    seq = last_seq + 1
    return f"{prefix}{seq:03d}"

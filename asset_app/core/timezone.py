from datetime import datetime
from zoneinfo import ZoneInfo


IST = ZoneInfo("Asia/Kolkata")


def now_ist() -> datetime:
    """Return current Indian time as a naive datetime for existing DB columns."""
    return datetime.now(IST).replace(tzinfo=None)

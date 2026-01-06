from datetime import datetime, timedelta, timezone

# Fixed Indian Standard Time (UTC+05:30)
IST = timezone(timedelta(hours=5, minutes=30))


def now_ist() -> datetime:
    """Return timezone-aware datetime in IST."""
    return datetime.now(IST)


def now_ist_naive() -> datetime:
    """Return IST time as naive datetime for DB fields without tz support."""
    return now_ist().replace(tzinfo=None)

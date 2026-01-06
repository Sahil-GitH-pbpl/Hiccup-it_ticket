from datetime import datetime
from pytz import timezone

from app.core.config import get_settings

settings = get_settings()


def now_local():
    tz = timezone(settings.timezone)
    return datetime.now(tz)


def now_local_naive():
    # Some DB columns are stored without tz info; strip tz to keep inserts simple.
    return now_local().replace(tzinfo=None)

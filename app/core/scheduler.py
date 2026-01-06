import logging
from datetime import datetime, timedelta

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from pytz import timezone
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.services.hiccup_service import mark_overdue_flags
from app.services.notification_service import (
    send_daily_summary,
    send_response_reminders,
)

logger = logging.getLogger(__name__)
settings = get_settings()


def get_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler(timezone=settings.timezone)
    return scheduler


def start_scheduler():
    scheduler = get_scheduler()

    def hourly_job():
        logger.info("Running hourly SLA check")
        db: Session = SessionLocal()
        try:
            mark_overdue_flags(db)
            send_response_reminders(db)
            db.commit()
        except Exception as exc:  # noqa: BLE001
            logger.exception("Error in SLA check: %s", exc)
            db.rollback()
        finally:
            db.close()

    def daily_summary_job():
        logger.info("Running daily summary job")
        db: Session = SessionLocal()
        try:
            send_daily_summary(db)
            db.commit()
        except Exception as exc:  # noqa: BLE001
            logger.exception("Daily summary failed: %s", exc)
            db.rollback()
        finally:
            db.close()

    scheduler.add_job(
        hourly_job, "interval", minutes=60, id="sla-check", replace_existing=True
    )
    scheduler.add_job(
        daily_summary_job,
        trigger=CronTrigger(hour=11, minute=0, timezone=timezone(settings.timezone)),
        id="daily-summary",
        replace_existing=True,
    )
    scheduler.start()
    return scheduler

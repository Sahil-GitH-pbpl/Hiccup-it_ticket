import logging
import os
from datetime import timedelta
from pathlib import Path

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from pytz import timezone
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.services.hiccup_service import mark_overdue_flags
from app.services.notification_service import (
    send_daily_summary,
    send_hiccup_whatsapp_reports_separately,
    send_response_reminders,
)
from app.utils.time_utils import now_local

logger = logging.getLogger(__name__)
settings = get_settings()
SCHEDULER_LOCK_PATH = Path("/tmp") / "hiccup_scheduler.lock"


def get_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler(timezone=settings.timezone)
    return scheduler


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _acquire_scheduler_lock(lock_path: Path) -> bool:
    """
    Acquire singleton lock so only one worker starts APScheduler.
    Reclaims stale locks from dead processes.
    """
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    pid = os.getpid()
    try:
        fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.write(fd, str(pid).encode())
        os.close(fd)
        return True
    except FileExistsError:
        try:
            existing_pid = int((lock_path.read_text() or "0").strip())
        except Exception:
            existing_pid = 0
        if existing_pid and _pid_alive(existing_pid):
            logger.info(
                "Scheduler already running in pid=%s; skipping start in pid=%s",
                existing_pid,
                pid,
            )
            return False
        # Stale lock: reclaim
        try:
            lock_path.unlink()
        except Exception:
            pass
        try:
            fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, str(pid).encode())
            os.close(fd)
            return True
        except Exception:
            logger.info("Scheduler lock contention; skipping start in pid=%s", pid)
            return False


def start_scheduler():
    if not _acquire_scheduler_lock(SCHEDULER_LOCK_PATH):
        return None

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

    def previous_day_hiccup_report_job():
        report_date = now_local().date() - timedelta(days=1)
        logger.info("Running previous-day Hiccup WhatsApp report for %s", report_date)
        db: Session = SessionLocal()
        try:
            send_hiccup_whatsapp_reports_separately(db, report_date=report_date)
            db.commit()
        except Exception as exc:  # noqa: BLE001
            logger.exception(
                "Previous-day Hiccup WhatsApp report failed for %s: %s",
                report_date,
                exc,
            )
            db.rollback()
        finally:
            db.close()

    scheduler.add_job(
        hourly_job, "interval", minutes=60, id="sla-check", replace_existing=True
    )
    scheduler.add_job(
        daily_summary_job,
        trigger=CronTrigger(hour=23, minute=59, timezone=timezone(settings.timezone)),
        id="daily-summary",
        replace_existing=True,
    )
    scheduler.add_job(
        previous_day_hiccup_report_job,
        trigger=CronTrigger(hour=0, minute=2, timezone=timezone(settings.timezone)),
        id="previous-day-hiccup-whatsapp-report",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("Scheduler started in pid=%s", os.getpid())
    return scheduler

import logging
from datetime import timedelta

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from pytz import timezone
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.api.routes_infra import (
    _send_pick_reminders,
    generate_infra_pick_sla_hiccups,
    generate_infra_resolution_sla_hiccups,
    is_infra_sla_check_window,
)
from app.services.hiccup_service import mark_overdue_flags
from app.services.notification_service import (
    send_daily_summary,
    send_hiccup_whatsapp_reports_separately,
    send_response_reminders,
)
from app.utils.time_utils import now_local

logger = logging.getLogger(__name__)
settings = get_settings()
_scheduler_instance: BackgroundScheduler | None = None


def get_scheduler() -> BackgroundScheduler:
    scheduler = BackgroundScheduler(timezone=settings.timezone)
    return scheduler


def start_scheduler():
    global _scheduler_instance
    if _scheduler_instance and _scheduler_instance.running:
        logger.info("Scheduler already running in this process; skipping duplicate start")
        return _scheduler_instance

    scheduler = get_scheduler()

    def hourly_job():
        logger.info("Running hourly SLA check")
        db: Session = SessionLocal()
        try:
            mark_overdue_flags(db)
            send_response_reminders(db)
            _send_pick_reminders(db)
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

    def infra_pick_sla_job():
        logger.info("Running infra pick SLA auto-hiccup check")
        if not is_infra_sla_check_window():
            logger.info("Skipping infra pick SLA check outside working window")
            return
        db: Session = SessionLocal()
        try:
            pick_created_count = generate_infra_pick_sla_hiccups(db)
            resolution_created_count = generate_infra_resolution_sla_hiccups(db)
            db.commit()
            if pick_created_count:
                logger.info("Infra pick SLA auto-hiccup created %s hiccups", pick_created_count)
            if resolution_created_count:
                logger.info(
                    "Infra resolution SLA auto-hiccup created %s hiccups",
                    resolution_created_count,
                )
        except Exception as exc:  # noqa: BLE001
            logger.exception("Infra pick SLA auto-hiccup check failed: %s", exc)
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
        infra_pick_sla_job,
        "interval",
        minutes=10,
        id="infra-pick-sla-auto-hiccup",
        replace_existing=True,
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
    _scheduler_instance = scheduler
    logger.info("Scheduler started")
    return _scheduler_instance

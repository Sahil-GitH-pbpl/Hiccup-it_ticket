from __future__ import annotations

import logging
import threading
from datetime import timedelta

from sqlalchemy.orm import Session

from app.db.session import SessionLocal, engine
from app.integrations.whatsapp_client import send_whatsapp_message
from app.models.whatsapp_outbox import WhatsAppOutbox
from app.utils.time_utils import now_local_naive

logger = logging.getLogger(__name__)
_outbox_table_ready = False


def ensure_whatsapp_outbox_table() -> None:
    global _outbox_table_ready
    if _outbox_table_ready:
        return
    WhatsAppOutbox.__table__.create(bind=engine, checkfirst=True)
    _outbox_table_ready = True


def enqueue_whatsapp(
    db: Session,
    target: str | None,
    message: str | None,
    *,
    context: str | None = None,
    next_attempt_at=None,
) -> WhatsAppOutbox | None:
    target = (target or "").strip()
    message = (message or "").strip()
    if not target or not message:
        logger.warning("WhatsApp queue skipped; target/message missing context=%s", context)
        return None
    ensure_whatsapp_outbox_table()

    row = WhatsAppOutbox(
        target=target,
        message=message,
        context=context,
        status="PENDING",
        next_attempt_at=next_attempt_at or now_local_naive(),
    )
    db.add(row)
    return row


def send_whatsapp_async_or_queue(
    target: str | None,
    message: str | None,
    *,
    context: str | None = None,
) -> None:
    """Try sending immediately in the background; queue only when send fails.

    This keeps the request fast while avoiding scheduler delay when WhatsApp is
    available.
    """

    target = (target or "").strip()
    message = (message or "").strip()
    if not target or not message:
        logger.warning("WhatsApp send skipped; target/message missing context=%s", context)
        return

    def _worker() -> None:
        try:
            if send_whatsapp_message(target, message):
                logger.info("WhatsApp sent immediately context=%s target=%s", context, target)
                return
        except Exception as exc:  # noqa: BLE001
            logger.exception("Immediate WhatsApp send crashed context=%s: %s", context, exc)

        db = SessionLocal()
        try:
            enqueue_whatsapp(db, target, message, context=context)
            db.commit()
            logger.info("WhatsApp queued after immediate failure context=%s target=%s", context, target)
        except Exception as exc:  # noqa: BLE001
            db.rollback()
            logger.exception("WhatsApp queue fallback failed context=%s: %s", context, exc)
        finally:
            db.close()

    threading.Thread(target=_worker, daemon=True).start()


def process_whatsapp_outbox(db: Session, *, limit: int = 30) -> dict[str, int]:
    ensure_whatsapp_outbox_table()
    now = now_local_naive()
    rows = (
        db.query(WhatsAppOutbox)
        .filter(
            WhatsAppOutbox.status.in_(["PENDING", "FAILED"]),
            WhatsAppOutbox.next_attempt_at <= now,
        )
        .order_by(WhatsAppOutbox.next_attempt_at.asc(), WhatsAppOutbox.id.asc())
        .limit(limit)
        .all()
    )
    sent = 0
    failed = 0
    for row in rows:
        row.attempts = (row.attempts or 0) + 1
        try:
            ok = send_whatsapp_message(row.target, row.message)
        except Exception as exc:  # noqa: BLE001
            ok = False
            row.last_error = str(exc)
            logger.exception("WhatsApp outbox send crashed id=%s context=%s", row.id, row.context)

        if ok:
            row.status = "SENT"
            row.sent_at = now_local_naive()
            row.last_error = None
            sent += 1
            continue

        failed += 1
        row.status = "FAILED"
        if not row.last_error:
            row.last_error = "WhatsApp API returned failure"
        delay_minutes = 120 if (row.context or "").startswith("hiccup:") else min(60, max(1, 2 ** min(row.attempts, 6)))
        row.next_attempt_at = now_local_naive() + timedelta(minutes=delay_minutes)

    if rows:
        db.commit()
    return {"picked": len(rows), "sent": sent, "failed": failed}

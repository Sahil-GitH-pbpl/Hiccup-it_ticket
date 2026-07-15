from pathlib import Path
from typing import Optional
from datetime import datetime, timedelta, date, time as dt_time
import time
import logging
import threading
import uuid

import requests
from fastapi import APIRouter, Depends, Form, Request, UploadFile, File, Query
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import case, func, or_

from app.core.config import get_settings
from app.core.templating import CompatJinja2Templates
from app.core.security import is_allowlisted_infra_admin_by_staff
from app.db.session import MainSessionLocal
from app.core.security import TokenData, get_current_user
from app.db.session import SessionLocal
from app.models.infra import InfraTicket, InfraTicketImage, InfraUpdate
from app.models.hiccup import Hiccup, HiccupAuditLog
from app.models.staff import Staff
from app.services.notification_service import enqueue_creation_notification
from app.utils.id_generator import generate_hiccup_id
from app.utils.time_utils import now_local, now_local_naive


router = APIRouter()
templates = CompatJinja2Templates(directory="app/templates")
settings = get_settings()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _infra_redirect_url(return_to: Optional[str] = None) -> str:
    if return_to:
        candidate = return_to.strip()
        if candidate.startswith("/infra/all"):
            return candidate
    return "/infra/all"

UPLOAD_DIR = Path("uploads/infra")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

WHATSAPP_API_URL = settings.whatsapp_api_url
WHATSAPP_ACCOUNT_ID = settings.whatsapp_account_id
WHATSAPP_GROUP_TARGET = (
    (settings.management_group_numbers.split(",")[0].strip())
    if settings.management_group_numbers
    else ""
)
REMINDER_THRESHOLD_HOURS = 24
REMINDER_INTERVAL_SECONDS = 60 * 60  # 1 hour
DELAYED_FLAGS_REFRESH_INTERVAL_SECONDS = 30
AUTO_HICCUP_CREATED_BY_ID = 125
AUTO_HICCUP_CREATED_BY_NAME = "Dr Vipul Bhasin"
AUTO_HICCUP_SOURCE = "infra_pick_sla"
RESOLVE_SLA_HICCUP_SOURCE = "infra_resolution_sla"
AUTO_HICCUP_OWNER_MAP = {
    "software": [8, 52, 2241],
    "hardware": [2318, 41],
    "office infra": [41],
}
_delayed_flags_lock = threading.Lock()
_last_delayed_flags_refresh = 0.0


def _is_admin(user: TokenData) -> bool:
    """
    Admin check: only allow users whose designation or role contains 'admin'.
    (e.g., 'Admin', 'System Admin', 'Admin Head').
    """
    # Token flag short-circuit (infra-specific)
    if getattr(user, "is_infra_admin", False):
        return True
    # Allowlist override (e.g., Ankita)
    try:
        if user and getattr(user, "user_id", None):
            db_main = MainSessionLocal()
            staff = db_main.query(Staff).filter(Staff.id == user.user_id).first()
            if staff and is_allowlisted_infra_admin_by_staff(staff):
                return True
    except Exception:
        # Fallback to designation/role checks
        pass
    finally:
        try:
            db_main.close()
        except Exception:
            pass

    designation = (user.designation or "").lower()
    role = (user.role or "").lower()
    keywords = ("admin", "it", "infra")
    return any(key in designation for key in keywords) or any(key in role for key in keywords)


logger = logging.getLogger(__name__)
if not logger.handlers:
    log_format = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"

    # Console logging
    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
    )

    # File logging (for local debugging of WhatsApp sends)
    logs_dir = Path("logs")
    logs_dir.mkdir(exist_ok=True)
    file_handler = logging.FileHandler(logs_dir / "infra_alerts.log", encoding="utf-8")
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(logging.Formatter(log_format))
    logger.addHandler(file_handler)


def send_whatsapp_to_number(target: str, message: str):
    """
    Local WhatsApp relay wrapper with basic logging.
    """
    req_id = str(uuid.uuid4())[:8]

    if not target:
        logger.error("WA[%s] missing target; skipping send", req_id)
        return 400, "missing target"

    normalized_target = target.strip()
    if normalized_target and "@g.us" not in normalized_target:
        digits = normalized_target.replace("+", "").replace(" ", "")
        if digits.startswith("0"):
            digits = digits.lstrip("0")
        if not digits.startswith("91"):
            digits = f"91{digits}"
        normalized_target = digits

    try:
        logger.info(
            "WA[%s] -> sendMessage | target=%s | len=%s",
            req_id,
            normalized_target,
            len(message or ""),
        )

        r = requests.post(
            WHATSAPP_API_URL,
            json={
                "accountId": WHATSAPP_ACCOUNT_ID,
                "target": normalized_target,
                "message": message,
            },
            timeout=10,
        )

        logger.info(
            "WA[%s] <- status=%s | body=%s",
            req_id,
            r.status_code,
            (r.text[:500] if r.text else ""),
        )

        return r.status_code, r.text
    except Exception as e:
        logger.exception("WA[%s] send_whatsapp_to_number exception: %s", req_id, e)
        return 500, str(e)


def _build_ticket_message(ticket: InfraTicket) -> str:
    """
    Format WhatsApp message for a newly created infra ticket.
    """
    created_at = getattr(ticket, "created_at", None)
    created_str = created_at.strftime("%d-%b-%Y %I:%M %p") if created_at else now_local_naive().strftime("%d-%b-%Y %I:%M %p")

    lines = [
        "*New Infra Ticket Created*",
        f"*Ticket:* #{ticket.ticket_id}",
        f"*Created By:* {ticket.created_by or '-'}",
        f"*Department:* {ticket.department or '-'}",
        f"*Category:* {ticket.category or '-'} / {ticket.subcategory or '-'}",
        f"*Workstation:* {ticket.workstation or '-'}",
        f"*Status:* {ticket.status}",
        f"*Description:* {ticket.description or '-'}",
        f"_Created At:_ {created_str}",
    ]
    return "\n".join(lines)


def notify_new_ticket_async(ticket: InfraTicket):
    """
    Fire-and-forget WhatsApp alert for new tickets.
    """
    if not WHATSAPP_GROUP_TARGET:
        logger.warning("WA notify skipped: WHATSAPP_GROUP_TARGET missing")
        return

    def _worker():
        try:
            msg = _build_ticket_message(ticket)
            logger.info(
                "InfraAlert -> sending WA for ticket_id=%s | msg_len=%s",
                ticket.ticket_id,
                len(msg),
            )
            status, resp = send_whatsapp_to_number(WHATSAPP_GROUP_TARGET, msg)
            if status in (200, 201):
                logger.info("InfraAlert sent | status=%s | resp=%s", status, (resp[:300] if resp else ""))
            else:
                logger.error("InfraAlert failed | status=%s | resp=%s", status, (resp[:500] if resp else ""))
        except Exception as e:
            logger.exception("InfraAlert exception: %s", e)

    threading.Thread(target=_worker, daemon=True).start()


def _build_pick_reminder_message(ticket: InfraTicket) -> str:
    created_at = getattr(ticket, "created_at", None)
    created_str = created_at.strftime("%d-%b-%Y %I:%M %p") if created_at else "-"
    lines = [
        "*Ticket Reminder*",
        f"*Ticket:* #{ticket.ticket_id}",
        f"*Raised By:* {ticket.created_by or '-'}",
        f"*Department:* {ticket.department or '-'}",
        f"*Category:* {ticket.category or '-'} / {ticket.subcategory or '-'}",
        f"*Description:* {ticket.description or '-'}",
        f"*Created:* {created_str}",
        "",
        "*Status:* Unpicked for 24 hours. Please assign/pick ASAP.",
    ]
    return "\n".join(lines)


def _build_pick_confirmation_message(ticket: InfraTicket) -> str:
    commitment = getattr(ticket, "commitment_time", None)
    commitment_str = commitment.strftime("%d-%b-%Y %I:%M %p") if commitment else "Not provided"
    assignee = ticket.assigned_to or "-"
    lines = [
        "*Ticket Update*",
        f"Ticket #{ticket.ticket_id} has been picked by {assignee}.",
        f"Commitment Time: {commitment_str}",
        "",
        "We'll keep you posted!",
    ]
    return "\n".join(lines)


def _build_invalid_message(ticket: InfraTicket) -> str:
    assigned = ticket.assigned_to or "the assigned member"
    reason = (ticket.invalid_reason or "Not provided").strip()
    lines = [
        "❌ *Ticket Update*",
        f"Ticket #{ticket.ticket_id} has been marked Silly by {assigned}.",
        "",
        f"*Reason:* {reason}",
        "",
        "If you believe this is incorrect, please raise a fresh ticket or reach out for clarification.",
        "",
        "IT Team, Dr Bhasin's Lab",
    ]
    return "\n".join(lines)


def _build_resolved_message(ticket: InfraTicket) -> str:
    resolver = ticket.assigned_to or "IT team"
    commitment = ticket.commitment_time.strftime("%d-%b-%Y %I:%M %p") if ticket.commitment_time else "-"
    lines = [
        "✅ *Ticket Resolved*",
        f"Ticket #{ticket.ticket_id} has been resolved by {resolver}.",
        f"Commitment Time: {commitment}",
        "",
        "Thank you for your patience!",
        "",
        "IT Team, Dr Bhasin's Lab",
    ]
    return "\n".join(lines)


def _send_pick_reminders(db: Session):
    """
    Send WhatsApp reminders for tickets older than REMINDER_THRESHOLD_HOURS that remain unassigned.
    """
    if not WHATSAPP_GROUP_TARGET:
        logger.warning("WA reminder skipped: WHATSAPP_GROUP_TARGET missing")
        return

    cutoff = now_local_naive() - timedelta(hours=REMINDER_THRESHOLD_HOURS)
    pending = (
        db.query(InfraTicket)
        .filter(
            InfraTicket.status == "New",
            or_(InfraTicket.assigned_to.is_(None), InfraTicket.assigned_to == ""),
            InfraTicket.is_invalid == False,
            InfraTicket.reminder_sent == False,
            InfraTicket.created_at <= cutoff,
        )
        .all()
    )

    if not pending:
        return

    logger.info("InfraReminder -> processing %s pending tickets", len(pending))
    updated = False

    for ticket in pending:
        msg = _build_pick_reminder_message(ticket)
        status, resp = send_whatsapp_to_number(WHATSAPP_GROUP_TARGET, msg)
        if status in (200, 201):
            ticket.reminder_sent = True
            updated = True
            logger.info(
                "InfraReminder sent | ticket_id=%s status=%s",
                ticket.ticket_id,
                status,
            )
        else:
            logger.error(
                "InfraReminder failed | ticket_id=%s status=%s resp=%s",
                ticket.ticket_id,
                status,
                (resp[:300] if resp else ""),
            )

    if updated:
        db.commit()


def _parse_hhmm(value: str, default: dt_time) -> dt_time:
    try:
        hour, minute = (value or "").strip().split(":", 1)
        return dt_time(hour=int(hour), minute=int(minute))
    except Exception:
        return default


def _infra_sla_holidays() -> set[date]:
    holidays: set[date] = set()
    for raw in (settings.infra_sla_holidays or "").split(","):
        text_value = raw.strip()
        if not text_value:
            continue
        try:
            holidays.add(date.fromisoformat(text_value))
        except ValueError:
            logger.warning("Ignoring invalid INFRA_SLA_HOLIDAYS value: %s", text_value)
    return holidays


def _is_infra_sla_working_day(day: date) -> bool:
    # Sunday is treated as non-working; explicit holidays are also skipped.
    return day.weekday() != 6 and day not in _infra_sla_holidays()


def _next_infra_sla_working_day(day: date) -> date:
    candidate = day
    while not _is_infra_sla_working_day(candidate):
        candidate = candidate + timedelta(days=1)
    return candidate


def is_infra_sla_check_window(moment: Optional[datetime] = None) -> bool:
    current = moment or now_local_naive()
    if not _is_infra_sla_working_day(current.date()):
        return False
    start_time = _parse_hhmm(settings.infra_pick_sla_start, dt_time(12, 0))
    end_time = _parse_hhmm(settings.infra_pick_sla_end, dt_time(16, 0))
    return start_time <= current.time() <= end_time


def calculate_pick_sla_deadline(created_at: Optional[datetime]) -> datetime:
    """
    Infra pick SLA: every ticket gets 4 working hours to be picked.
    Working window is configurable, default 12 PM to 4 PM.

    - Created before the window -> timer starts same working day at 12 PM.
    - Created during the window -> timer starts immediately.
    - Created after the window/off/holiday -> timer starts next working day at 12 PM.
    """
    created = created_at or now_local_naive()
    start_time = _parse_hhmm(settings.infra_pick_sla_start, dt_time(12, 0))
    end_time = _parse_hhmm(settings.infra_pick_sla_end, dt_time(16, 0))
    remaining = timedelta(hours=4)

    current_day = _next_infra_sla_working_day(created.date())
    if current_day != created.date():
        cursor = datetime.combine(current_day, start_time)
    elif created.time() < start_time:
        cursor = datetime.combine(created.date(), start_time)
    elif created.time() >= end_time:
        current_day = _next_infra_sla_working_day(created.date() + timedelta(days=1))
        cursor = datetime.combine(current_day, start_time)
    else:
        cursor = created

    while remaining > timedelta(0):
        current_day = _next_infra_sla_working_day(cursor.date())
        if current_day != cursor.date():
            cursor = datetime.combine(current_day, start_time)
            continue

        window_end = datetime.combine(cursor.date(), end_time)
        if cursor >= window_end:
            next_day = _next_infra_sla_working_day(cursor.date() + timedelta(days=1))
            cursor = datetime.combine(next_day, start_time)
            continue

        available = window_end - cursor
        if remaining <= available:
            return cursor + remaining

        remaining -= available
        next_day = _next_infra_sla_working_day(cursor.date() + timedelta(days=1))
        cursor = datetime.combine(next_day, start_time)

    return cursor


def _infra_auto_hiccup_owner_ids(ticket: InfraTicket) -> list[int]:
    category = (ticket.category or "").strip().lower()
    subcategory = (ticket.subcategory or "").strip().lower()
    if category == "office infra" or subcategory == "office infra":
        return AUTO_HICCUP_OWNER_MAP["office infra"]
    if category == "software":
        return AUTO_HICCUP_OWNER_MAP["software"]
    if category == "hardware":
        return AUTO_HICCUP_OWNER_MAP["hardware"]
    return []


def _staff_map_for_ids(db: Session, staff_ids: list[int]) -> dict[int, Staff]:
    if not staff_ids:
        return {}
    rows = db.query(Staff).filter(Staff.id.in_(staff_ids)).all()
    return {staff.id: staff for staff in rows}


def _find_staff_by_name(db: Session, name: Optional[str]) -> Optional[Staff]:
    normalized = (name or "").strip().lower()
    if not normalized:
        return None
    return db.query(Staff).filter(func.lower(Staff.name) == normalized).first()


def _create_infra_pick_sla_hiccup(db: Session, ticket: InfraTicket, owner: Staff, group_names: str) -> Hiccup:
    hiccup_id = generate_hiccup_id(db)
    deadline = ticket.pick_sla_deadline_at or calculate_pick_sla_deadline(ticket.created_at)
    created_str = ticket.created_at.strftime("%d-%b-%Y %I:%M %p") if ticket.created_at else "-"
    deadline_str = deadline.strftime("%d-%b-%Y %I:%M %p") if deadline else "-"
    description = "\n".join(
        [
            f"Infra ticket #{ticket.ticket_id} was not picked within the working-hour SLA.",
            "",
            f"Ticket created by: {ticket.created_by or '-'}",
            f"Department/location: {ticket.department or '-'}",
            f"Category/type: {ticket.category or '-'} / {ticket.subcategory or '-'}",
            f"Workstation: {ticket.workstation or '-'}",
            f"Created at: {created_str}",
            f"Pick deadline: {deadline_str}",
            f"Responsible group: {group_names or owner.name or owner.id}",
            "",
            f"Ticket description: {ticket.description or '-'}",
        ]
    )
    current_ts = now_local()
    hiccup = Hiccup(
        hiccup_id=hiccup_id,
        raised_by=AUTO_HICCUP_CREATED_BY_ID,
        raised_by_name=AUTO_HICCUP_CREATED_BY_NAME,
        raised_by_department=None,
        hiccup_type="Person Related",
        raised_against=str(owner.id),
        raised_against_name=owner.name,
        raised_against_department=getattr(owner, "department_id", None),
        raised_against_department_name=getattr(owner, "departments", None),
        description=description,
        immediate_effect="Infra ticket remained unpicked during the 12 PM to 4 PM working SLA window.",
        status="Open",
        is_auto_generated=True,
        source_module=AUTO_HICCUP_SOURCE,
        confidential_flag=False,
        created_at=current_ts,
        updated_at=current_ts,
    )
    db.add(hiccup)
    db.add(
        HiccupAuditLog(
            hiccup_id=hiccup_id,
            action="Created",
            performed_by=AUTO_HICCUP_CREATED_BY_ID,
            remarks=f"Auto-created from infra ticket #{ticket.ticket_id}",
        )
    )
    db.flush()
    return hiccup


def _create_infra_resolution_sla_hiccup(
    db: Session, ticket: InfraTicket, creator: Staff, assignee: Staff
) -> Hiccup:
    hiccup_id = generate_hiccup_id(db)
    created_str = ticket.created_at.strftime("%d-%b-%Y %I:%M %p") if ticket.created_at else "-"
    commitment_str = (
        ticket.commitment_time.strftime("%d-%b-%Y %I:%M %p")
        if ticket.commitment_time
        else "-"
    )
    description = "\n".join(
        [
            f"Infra ticket #{ticket.ticket_id} was picked but not resolved within the committed SLA time.",
            "",
            f"Ticket created by: {ticket.created_by or '-'}",
            f"Picked/assigned to: {ticket.assigned_to or '-'}",
            f"Department/location: {ticket.department or '-'}",
            f"Category/type: {ticket.category or '-'} / {ticket.subcategory or '-'}",
            f"Workstation: {ticket.workstation or '-'}",
            f"Created at: {created_str}",
            f"Commitment time: {commitment_str}",
            "",
            f"Ticket description: {ticket.description or '-'}",
        ]
    )
    current_ts = now_local()
    hiccup = Hiccup(
        hiccup_id=hiccup_id,
        raised_by=creator.id,
        raised_by_name=creator.name,
        raised_by_department=getattr(creator, "department_id", None),
        hiccup_type="Person Related",
        raised_against=str(assignee.id),
        raised_against_name=assignee.name,
        raised_against_department=getattr(assignee, "department_id", None),
        raised_against_department_name=getattr(assignee, "departments", None),
        description=description,
        immediate_effect="Infra ticket resolution SLA was breached after the ticket was picked.",
        status="Open",
        is_auto_generated=True,
        source_module=RESOLVE_SLA_HICCUP_SOURCE,
        confidential_flag=False,
        created_at=current_ts,
        updated_at=current_ts,
    )
    db.add(hiccup)
    db.add(
        HiccupAuditLog(
            hiccup_id=hiccup_id,
            action="Created",
            performed_by=creator.id,
            remarks=f"Auto-created from infra ticket #{ticket.ticket_id} resolution SLA breach",
        )
    )
    db.flush()
    return hiccup


def _generate_resolution_sla_hiccup_for_ticket(db: Session, ticket: InfraTicket) -> Optional[Hiccup]:
    if not ticket:
        return None
    if ticket.resolve_sla_hiccup_generated:
        return None
    if not ticket.commitment_time or ticket.commitment_time > now_local_naive():
        return None
    if not ticket.pick_sla_deadline_at:
        return None
    if ticket.status == "Resolved" or ticket.is_invalid:
        return None
    if not (ticket.assigned_to or "").strip():
        return None

    creator = _find_staff_by_name(db, ticket.created_by)
    assignee = _find_staff_by_name(db, ticket.assigned_to)
    if not creator or not assignee:
        logger.warning(
            "Infra resolution SLA hiccup skipped: staff not found | ticket_id=%s creator=%s assignee=%s",
            ticket.ticket_id,
            ticket.created_by,
            ticket.assigned_to,
        )
        return None

    hiccup = _create_infra_resolution_sla_hiccup(db, ticket, creator, assignee)
    ticket.resolve_sla_hiccup_generated = True
    ticket.resolve_sla_hiccup_id = hiccup.hiccup_id
    ticket.resolve_sla_hiccup_generated_at = now_local_naive()
    ticket.is_delayed_pick = True
    logger.info(
        "Infra resolution SLA hiccup generated | ticket_id=%s hiccup=%s",
        ticket.ticket_id,
        hiccup.hiccup_id,
    )
    return hiccup


def generate_infra_pick_sla_hiccups(db: Session) -> int:
    """
    Create automatic hiccups for New/unpicked infra tickets once their 4 PM
    working-day pick deadline has passed.
    """
    now = now_local_naive()
    pending = (
        db.query(InfraTicket)
        .filter(
            InfraTicket.status == "New",
            or_(InfraTicket.assigned_to.is_(None), InfraTicket.assigned_to == ""),
            InfraTicket.is_invalid == False,
            InfraTicket.auto_hiccup_generated == False,
            InfraTicket.pick_sla_deadline_at.isnot(None),
            InfraTicket.pick_sla_deadline_at <= now,
        )
        .all()
    )
    if not pending:
        return 0

    created_count = 0
    for ticket in pending:
        owner_ids = _infra_auto_hiccup_owner_ids(ticket)
        staff_map = _staff_map_for_ids(db, owner_ids)
        owners = [staff_map[owner_id] for owner_id in owner_ids if owner_id in staff_map]
        if not owners:
            logger.warning(
                "Infra auto hiccup skipped: no mapped owners found for ticket_id=%s category=%s subcategory=%s",
                ticket.ticket_id,
                ticket.category,
                ticket.subcategory,
            )
            ticket.auto_hiccup_generated = True
            ticket.auto_hiccup_generated_at = now
            continue

        group_names = ", ".join(owner.name for owner in owners if owner.name)
        generated_ids: list[str] = []
        for owner in owners:
            hiccup = _create_infra_pick_sla_hiccup(db, ticket, owner, group_names)
            generated_ids.append(hiccup.hiccup_id)
            created_count += 1

        ticket.auto_hiccup_generated = True
        ticket.auto_hiccup_id = ", ".join(generated_ids)
        ticket.auto_hiccup_generated_at = now
        logger.info(
            "Infra auto hiccup generated | ticket_id=%s hiccups=%s",
            ticket.ticket_id,
            ticket.auto_hiccup_id,
        )

    if created_count:
        db.commit()
    else:
        db.commit()
    for ticket in pending:
        if ticket.auto_hiccup_id:
            for hiccup_id in [part.strip() for part in ticket.auto_hiccup_id.split(",") if part.strip()]:
                enqueue_creation_notification(hiccup_id)
    return created_count


def generate_infra_resolution_sla_hiccups(db: Session) -> int:
    now = now_local_naive()
    pending = (
        db.query(InfraTicket)
        .filter(
            InfraTicket.status != "Resolved",
            InfraTicket.assigned_to.isnot(None),
            InfraTicket.assigned_to != "",
            InfraTicket.is_invalid == False,
            InfraTicket.commitment_time.isnot(None),
            InfraTicket.commitment_time < now,
            InfraTicket.pick_sla_deadline_at.isnot(None),
            InfraTicket.resolve_sla_hiccup_generated == False,
        )
        .all()
    )
    created_count = 0
    generated_ids: list[str] = []
    for ticket in pending:
        hiccup = _generate_resolution_sla_hiccup_for_ticket(db, ticket)
        if hiccup:
            generated_ids.append(hiccup.hiccup_id)
            created_count += 1
    if created_count:
        db.commit()
    for hiccup_id in generated_ids:
        enqueue_creation_notification(hiccup_id)
    return created_count


# -------------------------------------------------------------
# HELPER: UPDATE DELAYED FLAGS (SLA BREACH)
# -------------------------------------------------------------
def _update_delayed_flags(db: Session):
    """
    Mark tickets as delayed if:
    - commitment_time is set
    - now is past commitment_time
    - status is not Resolved
    - is_delayed_pick is still False
    """
    global _last_delayed_flags_refresh

    now_ts = time.monotonic()
    with _delayed_flags_lock:
        if now_ts - _last_delayed_flags_refresh < DELAYED_FLAGS_REFRESH_INTERVAL_SECONDS:
            return
        _last_delayed_flags_refresh = now_ts

    now = now_local_naive()

    updated_rows = (
        db.query(InfraTicket)
        .filter(
            InfraTicket.commitment_time.isnot(None),
            InfraTicket.commitment_time < now,
            InfraTicket.status != "Resolved",
            InfraTicket.is_delayed_pick == False,
        )
        .update({InfraTicket.is_delayed_pick: True}, synchronize_session=False)
    )

    if updated_rows:
        db.commit()


def _infra_status_counts(query, status_column, *, open_excludes_rejected: bool = False):
    open_status_filter = status_column != "Resolved"
    if open_excludes_rejected:
        open_status_filter = status_column.notin_(["Resolved", "Rejected"])

    row = query.with_entities(
        func.count().label("total"),
        func.sum(case((open_status_filter, 1), else_=0)).label("open_count"),
        func.sum(case((status_column == "Resolved", 1), else_=0)).label("resolved_count"),
        func.sum(case((status_column == "Rejected", 1), else_=0)).label("rejected_count"),
    ).one()

    return {
        "total": int(row.total or 0),
        "open": int(row.open_count or 0),
        "resolved": int(row.resolved_count or 0),
        "rejected": int(row.rejected_count or 0),
    }


# -------------------------------------------------------------
# SHOW TICKET CREATE FORM (LOGIN REQUIRED)
# -------------------------------------------------------------
@router.get("/infra/create-form", response_class=HTMLResponse)
def show_create_ticket_form(
    request: Request,
    message: Optional[str] = None,
    error: Optional[str] = None,
    user: TokenData = Depends(get_current_user),
):
    return templates.TemplateResponse(
        "infra/create_ticket.html",
        {
            "request": request,
            "message": message,
            "error": error,
            "username": user.name if user else None,
            "user": user,
        },
    )


# -------------------------------------------------------------
# CREATE TICKET SUBMIT (LOGIN REQUIRED)
# -------------------------------------------------------------
@router.post("/infra/create", response_class=HTMLResponse)
async def create_ticket(
    request: Request,
    created_by: str = Form(...),   # kept for form compatibility; we use the logged-in user
    department: str = Form(...),
    category: str = Form(...),
    subcategory: str = Form(...),
    workstation: str = Form(""),
    description: str = Form(...),
    photos: list[UploadFile] | None = File(None),
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    username = user.name if user else None

    if not description.strip():
        return templates.TemplateResponse(
            "infra/create_ticket.html",
            {
                "request": request,
                "error": "Description is required.",
                "message": None,
                "username": username,
                "user": user,
            },
            status_code=400,
        )

    saved_image_paths: list[str] = []
    if photos:
        for idx, upload in enumerate(photos):
            if not upload or not upload.filename:
                continue
            timestamp = now_local_naive().strftime("%Y%m%d%H%M%S")
            safe_name = Path(upload.filename).name.replace(" ", "_")
            unique_suffix = uuid.uuid4().hex[:6]
            file_name = f"{timestamp}_{unique_suffix}_{safe_name}"
            file_path = UPLOAD_DIR / file_name

            with file_path.open("wb") as f:
                f.write(await upload.read())

            saved_image_paths.append(str(file_path))

    primary_image_path: Optional[str] = saved_image_paths[0] if saved_image_paths else None

    user_contact: Optional[str] = None
    creator = None
    if user and user.user_id:
        creator = db.query(Staff).filter(Staff.id == user.user_id).first()
    if not creator and username:
        normalized_username = (username or "").strip().lower()
        creator = (
            db.query(Staff)
            .filter(func.lower(Staff.name) == normalized_username)
            .first()
        )
    if creator and getattr(creator, "contact", None):
        user_contact = (creator.contact or "").strip()

    ticket = InfraTicket(
        created_by=username,
        department=department,
        category=category,
        subcategory=subcategory,
        workstation=workstation.strip() if workstation else None,
        description=description.strip(),
        status="New",
        image_path=primary_image_path,
        contact=user_contact,
        pick_sla_deadline_at=calculate_pick_sla_deadline(now_local_naive()),
    )

    db.add(ticket)
    db.commit()
    db.refresh(ticket)

    if saved_image_paths:
        attachments = [
            InfraTicketImage(ticket_id=ticket.ticket_id, image_path=path)
            for path in saved_image_paths
        ]
        db.bulk_save_objects(attachments)
        db.commit()
        db.refresh(ticket)

    # Fire-and-forget WhatsApp alert; no impact on user flow if it fails.
    logger.info(
        "InfraAlert trigger -> ticket_id=%s created_by=%s dept=%s category=%s",
        ticket.ticket_id,
        ticket.created_by,
        ticket.department,
        ticket.category,
    )
    notify_new_ticket_async(ticket)

    return templates.TemplateResponse(
        "infra/create_ticket.html",
        {
            "request": request,
            "error": None,
            "message": f"Ticket #{ticket.ticket_id} created successfully.",
            "username": username,
            "user": user,
        },
    )


# -------------------------------------------------------------
# MY TICKETS PAGE (LOGIN REQUIRED)
# -------------------------------------------------------------
@router.get("/my-tickets", response_class=HTMLResponse)
def my_tickets(
    request: Request,
    page: int = Query(1, ge=1),
    search: str = "",
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    username = user.name if user else None

    # update delayed flags before showing user's tickets
    _update_delayed_flags(db)

    base_q = db.query(InfraTicket).filter(InfraTicket.created_by == username)

    normalized_search = (search or "").strip()
    if normalized_search:
        ilike_term = f"%{normalized_search}%"
        search_filters = [
            InfraTicket.description.ilike(ilike_term),
            InfraTicket.department.ilike(ilike_term),
            InfraTicket.category.ilike(ilike_term),
            InfraTicket.subcategory.ilike(ilike_term),
            InfraTicket.status.ilike(ilike_term),
            InfraTicket.assigned_to.ilike(ilike_term),
            InfraTicket.workstation.ilike(ilike_term),
        ]
        if normalized_search.isdigit():
            search_filters.append(InfraTicket.ticket_id == int(normalized_search))
        base_q = base_q.filter(or_(*search_filters))

    counts = _infra_status_counts(
        base_q,
        InfraTicket.status,
        open_excludes_rejected=True,
    )
    total_count = counts["total"]
    open_count = counts["open"]
    resolved_count = counts["resolved"]
    rejected_count = counts["rejected"]

    page_size = 15
    total_pages = max((total_count + page_size - 1) // page_size, 1)
    current_page = min(page, total_pages) if total_count else 1
    offset = (current_page - 1) * page_size if total_count else 0

    tickets = (
        base_q.options(selectinload(InfraTicket.images))
        .order_by(InfraTicket.ticket_id.desc())
        .offset(offset)
        .limit(page_size)
        .all()
    )

    return templates.TemplateResponse(
        "infra/my_tickets.html",
        {
            "request": request,
            "username": username,
            "user": user,
            "tickets": tickets,
            "stats": {
                "total": total_count,
                "open": open_count,
                "resolved": resolved_count,
                "rejected": rejected_count,
            },
            "pagination": {
                "page": current_page,
                "page_size": page_size,
                "total": total_count,
                "total_pages": total_pages if total_count else 1,
                "has_prev": current_page > 1,
                "has_next": current_page < total_pages if total_count else False,
                "start": offset + 1 if total_count else 0,
                "end": min(offset + len(tickets), total_count),
            },
            "filters": {
                "search": normalized_search,
            },
        },
    )


# -------------------------------------------------------------
# ALL TICKETS (IT / ADMIN VIEW) + FILTERS
# -------------------------------------------------------------
@router.get("/infra/all", response_class=HTMLResponse)
def all_tickets(
    request: Request,
    status: str = "",
    department: str = "",
    category: str = "",
    only_delayed: bool = Query(False),
    search: str = "",
    assigned_me: str = Query(""),
    page: int = Query(1, ge=1),
    view: str = Query("active"),
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    if not _is_admin(user):
        return RedirectResponse(url="/my-tickets", status_code=302)

    username = user.name if user else None
    username_norm = username.lower() if username else ""

    # update delayed flags before listing
    _update_delayed_flags(db)

    q = db.query(InfraTicket).options(selectinload(InfraTicket.images))

    if status:
        q = q.filter(InfraTicket.status == status)
    else:
        normalized_view = (view or "").lower()
        if normalized_view == "completed":
            q = q.filter(InfraTicket.status.in_(["Resolved", "Rejected"]))
        else:
            q = q.filter(InfraTicket.status.notin_(["Resolved", "Rejected"]))

    if department:
        q = q.filter(InfraTicket.department == department)

    if category:
        q = q.filter(InfraTicket.category == category)

    if only_delayed:
        q = q.filter(InfraTicket.is_delayed_pick == True)

    normalized_search = (search or "").strip()
    if normalized_search:
        ilike_term = f"%{normalized_search}%"
        search_filters = [
            InfraTicket.description.ilike(ilike_term),
            InfraTicket.created_by.ilike(ilike_term),
            InfraTicket.department.ilike(ilike_term),
            InfraTicket.category.ilike(ilike_term),
            InfraTicket.subcategory.ilike(ilike_term),
            InfraTicket.assigned_to.ilike(ilike_term),
        ]
        if normalized_search.isdigit():
            search_filters.append(InfraTicket.ticket_id == int(normalized_search))
        q = q.filter(or_(*search_filters))

    normalized_assigned_me = (assigned_me or "").strip().lower()
    assigned_me_enabled = normalized_assigned_me == "true"

    # if the checkbox is enabled, keep only tickets assigned to this user
    if assigned_me_enabled:
        q = q.filter(InfraTicket.assigned_to == username)

    page_size = 15
    total_count = q.count()
    total_pages = max((total_count + page_size - 1) // page_size, 1)
    current_page = min(page, total_pages) if total_count else 1
    offset = (current_page - 1) * page_size if total_count else 0

    tickets = (
        q.order_by(InfraTicket.ticket_id.desc(), InfraTicket.created_at.desc())
        .offset(offset)
        .limit(page_size)
        .all()
    )

    context = {
        "request": request,
        "username": username,
        "username_norm": username_norm,
        "user": user,
        "tickets": tickets,
        "pagination": {
            "page": current_page,
            "page_size": page_size,
            "total": total_count,
            "total_pages": total_pages if total_count else 1,
            "has_prev": current_page > 1,
            "has_next": current_page < total_pages if total_count else False,
            "start": offset + 1 if total_count else 0,
            "end": min(offset + len(tickets), total_count),
        },
        "filters": {
            "status": status,
            "department": department,
            "category": category,
            "only_delayed": only_delayed,
            "assigned_me": assigned_me_enabled,
            "search": normalized_search,
            "page": current_page,
            "view": (view or "active").lower(),
        },
    }

    if request.headers.get("X-Requested-With") == "XMLHttpRequest":
        partial = templates.get_template("infra/partials/tickets_block.html").render(context)
        return JSONResponse({"html": partial})

    return templates.TemplateResponse("infra/all_tickets.html", context)


# -------------------------------------------------------------
# DASHBOARD (IT / ADMIN)
# -------------------------------------------------------------
@router.get("/infra/dashboard", response_class=HTMLResponse)
def infra_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    if not _is_admin(user):
        return RedirectResponse(url="/my-tickets", status_code=302)

    # update delayed flags before computing stats
    _update_delayed_flags(db)

    summary = db.query(
        func.count().label("total"),
        func.sum(case((InfraTicket.status != "Resolved", 1), else_=0)).label("open_count"),
        func.sum(case((InfraTicket.status == "Resolved", 1), else_=0)).label("resolved_count"),
        func.sum(case((InfraTicket.is_delayed_pick.is_(True), 1), else_=0)).label("delayed_count"),
    ).one()

    total = int(summary.total or 0)
    open_count = int(summary.open_count or 0)
    resolved = int(summary.resolved_count or 0)
    delayed = int(summary.delayed_count or 0)

    dept_data = (
        db.query(InfraTicket.department, func.count())
        .group_by(InfraTicket.department)
        .all()
    )

    return templates.TemplateResponse(
        "infra/dashboard.html",
        {
            "request": request,
            "user": user,
            "total": total,
            "open": open_count,
            "resolved": resolved,
            "delayed": delayed,
            "dept_data": dept_data,
        },
    )


# -------------------------------------------------------------
# VIEW UPDATES FOR A TICKET
# -------------------------------------------------------------
@router.get("/infra/updates/{ticket_id}", response_class=HTMLResponse)
def view_updates(
    ticket_id: int,
    request: Request,
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    ticket = (
        db.query(InfraTicket)
        .filter(InfraTicket.ticket_id == ticket_id)
        .first()
    )

    if not ticket:
        return RedirectResponse(url="/infra/all", status_code=303)

    updates = (
        db.query(InfraUpdate)
        .filter(InfraUpdate.ticket_id == ticket_id)
        .order_by(InfraUpdate.created_at.asc())
        .all()
    )

    return templates.TemplateResponse(
        "infra/ticket_updates.html",
        {
            "request": request,
            "ticket": ticket,
            "updates": updates,
            "user": user,
        },
    )


# -------------------------------------------------------------
# ADD UPDATE TO A TICKET (BLOCK IF RESOLVED / INVALID)
# -------------------------------------------------------------
@router.post("/infra/update/{ticket_id}")
def add_update(
    ticket_id: int,
    request: Request,
    note: str = Form(...),
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    username = user.name if user else None

    ticket = (
        db.query(InfraTicket)
        .filter(InfraTicket.ticket_id == ticket_id)
        .first()
    )

    if not ticket:
        return RedirectResponse(url="/infra/all", status_code=303)

    # Only assigned member can add updates once assigned
    username_norm = username.lower() if username else ""
    if ticket.assigned_to and ticket.assigned_to.lower() != username_norm:
        return RedirectResponse(url=f"/infra/updates/{ticket_id}", status_code=303)

    # Block updates once resolved or invalid
    if ticket.status == "Resolved" or ticket.is_invalid:
        return RedirectResponse(url=f"/infra/updates/{ticket_id}", status_code=303)

    note = note.strip()
    if note:
        upd = InfraUpdate(
            ticket_id=ticket.ticket_id,
            note=note,
            created_by=username,
        )
        db.add(upd)
        db.commit()

    return RedirectResponse(url=f"/infra/updates/{ticket_id}", status_code=303)


# -------------------------------------------------------------
# PICK TICKET + SET COMMITMENT + ASSIGN (IT ONLY)
# -------------------------------------------------------------
@router.post("/infra/pick/{ticket_id}")
def pick_ticket(
    ticket_id: int,
    request: Request,
    commitment_time: str = Form(None),
    commitment_predefined: str = Form(None),
    commitment_date: str = Form(None),
    callback_time: str = Form(None),
    commitment_at: str = Form(None),
    preset_hours: str = Form(None),
    return_to: str = Form(None),
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    if not _is_admin(user):
        return RedirectResponse(url="/my-tickets", status_code=302)

    username = user.name if user else None

    ticket = (
        db.query(InfraTicket)
        .filter(InfraTicket.ticket_id == ticket_id)
        .first()
    )

    if not ticket:
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    # If another member already owns this ticket, block reassignment
    if ticket.assigned_to and ticket.assigned_to != username:
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    # Calculate commitment time based on different input methods
    ct = None
    
    # Method 1: Direct commitment_time (old method)
    if commitment_time:
        try:
            ct = datetime.strptime(commitment_time, "%Y-%m-%dT%H:%M")
        except ValueError:
            pass
    
    # Method 2: Quick commitment with predefined options
    elif commitment_predefined:
        try:
            if preset_hours:
                hours = float(preset_hours)
            else:
                # Fallback: parse from commitment_predefined string
                hours = parse_predefined_to_hours(commitment_predefined)

            # Round to top of the hour and add fractional hours precisely
            ct = now_local_naive().replace(second=0, microsecond=0, minute=0)
            ct = ct + timedelta(hours=hours)
        except (ValueError, TypeError):
            pass
    
    # Method 3: Custom commitment with date and time
    elif commitment_date and callback_time:
        try:
            datetime_str = f"{commitment_date} {callback_time}"
            ct = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M")
        except ValueError:
            pass
    
    # Method 4: Normalized commitment_at field
    elif commitment_at:
        try:
            # Handle different datetime formats
            if 'T' in commitment_at:
                ct = datetime.strptime(commitment_at, "%Y-%m-%dT%H:%M")
            else:
                ct = datetime.strptime(commitment_at, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            pass
    
    # Fallback: If no valid method found, use default 2 hours
    if ct is None:
        ct = now_local_naive().replace(second=0, microsecond=0)
        ct = ct.replace(minute=0)
        ct = ct.replace(hour=ct.hour + 2)

    # Validate commitment time is in future
    if ct <= now_local_naive():
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    is_delayed = now_local_naive() > ct

    # Use explicit UPDATE to avoid stale rowcount errors on legacy tables
    db.query(InfraTicket).filter(InfraTicket.ticket_id == ticket_id).update(
        {
            InfraTicket.commitment_time: ct,
            InfraTicket.assigned_to: username,
            InfraTicket.status: "In Progress",
            InfraTicket.is_delayed_pick: is_delayed,
        },
        synchronize_session=False,
    )

    # Create an update entry for the pick action
    update_note = (
        f"Ticket picked by {username}. Commitment set to {ct.strftime('%d-%m-%Y %H:%M')}"
    )
    db.add(
        InfraUpdate(
            ticket_id=ticket.ticket_id,
            note=update_note,
            created_by=username,
        )
    )

    db.commit()

    if ticket.contact:
        msg = _build_pick_confirmation_message(ticket)
        status, resp = send_whatsapp_to_number(ticket.contact, msg)
        if status in (200, 201):
            logger.info("PickNotify sent to %s | ticket_id=%s", ticket.contact, ticket.ticket_id)
        else:
            logger.error(
                "PickNotify failed | ticket_id=%s status=%s resp=%s",
                ticket.ticket_id,
                status,
                (resp[:300] if resp else ""),
            )
    return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

def parse_predefined_to_hours(predefined):
    """Parse predefined time string to hours"""
    mapping = {
        '15 mins': 0.25,
        '30 mins': 0.5,
        '1 Hour': 1,
        '2 Hour': 2,
        '3 Hour': 3,
        '6 Hour': 6,
        '24 Hour': 24,
        '2 Days': 48,
        '3 Days': 72,
        '7 Days': 168
    }
    return mapping.get(predefined, 2)  # default to 2 hours

# -------------------------------------------------------------
# RESOLVE TICKET (IT ONLY)
# -------------------------------------------------------------
@router.post("/infra/resolve/{ticket_id}")
def resolve_ticket(
    ticket_id: int,
    request: Request,
    return_to: str = Form(None),
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    if not _is_admin(user):
        return RedirectResponse(url="/my-tickets", status_code=302)

    ticket = (
        db.query(InfraTicket)
        .filter(InfraTicket.ticket_id == ticket_id)
        .first()
    )

    if not ticket:
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    # Only the assigned member can resolve
    username = user.name if user else None
    username_norm = username.lower() if username else ""
    if ticket.assigned_to and ticket.assigned_to.lower() != username_norm:
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    # If resolving after commitment time, mark delayed
    generated_resolution_hiccup_id = None
    if ticket.commitment_time and now_local_naive() > ticket.commitment_time:
        ticket.is_delayed_pick = True
        generated_resolution_hiccup = _generate_resolution_sla_hiccup_for_ticket(db, ticket)
        if generated_resolution_hiccup:
            generated_resolution_hiccup_id = generated_resolution_hiccup.hiccup_id

    db.query(InfraTicket).filter(InfraTicket.ticket_id == ticket_id).update(
        {
            InfraTicket.status: "Resolved",
            InfraTicket.is_delayed_pick: ticket.is_delayed_pick,
        },
        synchronize_session=False,
    )
    db.commit()
    if generated_resolution_hiccup_id:
        enqueue_creation_notification(generated_resolution_hiccup_id)

    if ticket.contact:
        msg = _build_resolved_message(ticket)
        status, resp = send_whatsapp_to_number(ticket.contact, msg)
        if status in (200, 201):
            logger.info("ResolveNotify sent | ticket_id=%s contact=%s", ticket.ticket_id, ticket.contact)
        else:
            logger.error(
                "ResolveNotify failed | ticket_id=%s status=%s resp=%s",
                ticket.ticket_id,
                status,
                (resp[:300] if resp else ""),
            )

    return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)


# -------------------------------------------------------------
# MARK TICKET INVALID (IT ONLY) → STATUS = REJECTED
# -------------------------------------------------------------
@router.post("/infra/invalid/{ticket_id}")
def mark_invalid(
    ticket_id: int,
    request: Request,
    invalid_reason: str = Form(...),
    return_to: str = Form(None),
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    if not _is_admin(user):
        return RedirectResponse(url="/my-tickets", status_code=302)

    ticket = (
        db.query(InfraTicket)
        .filter(InfraTicket.ticket_id == ticket_id)
        .first()
    )

    if not ticket:
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    # Only the assigned member can mark invalid
    username = user.name if user else None
    username_norm = username.lower() if username else ""
    if ticket.assigned_to and ticket.assigned_to.lower() != username_norm:
        return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

    db.query(InfraTicket).filter(InfraTicket.ticket_id == ticket_id).update(
        {
            InfraTicket.is_invalid: True,
            InfraTicket.invalid_reason: invalid_reason.strip()
            or "Marked invalid by IT.",
            InfraTicket.status: "Rejected",
        },
        synchronize_session=False,
    )

    db.commit()

    if ticket.contact:
        msg = _build_invalid_message(ticket)
        status, resp = send_whatsapp_to_number(ticket.contact, msg)
        if status in (200, 201):
            logger.info("InvalidNotify sent | ticket_id=%s contact=%s", ticket.ticket_id, ticket.contact)
        else:
            logger.error(
                "InvalidNotify failed | ticket_id=%s status=%s resp=%s",
                ticket.ticket_id,
                status,
                (resp[:300] if resp else ""),
            )

    return RedirectResponse(url=_infra_redirect_url(return_to), status_code=303)

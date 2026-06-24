import logging
import threading
from collections import Counter
from datetime import date, datetime, time, timedelta
from typing import List, Optional
from urllib.parse import quote_plus

from sqlalchemy.orm import Session

from app.integrations.whatsapp_client import send_bulk
from app.core.config import get_settings
from app.db.session import SessionLocal
from app.services.report_service import recent_stats
from app.services.hiccup_service import mark_overdue_flags, trend_alerts
from app.models.department import Department
from app.models.hiccup import Hiccup
from app.models.staff import Staff
from app.utils.time_utils import now_local
from app.core.security import create_public_response_token
from pytz import timezone
from urllib.parse import quote_plus

logger = logging.getLogger(__name__)
settings = get_settings()


def _dedup_numbers(numbers: List[str]) -> List[str]:
    seen = set()
    deduped = []
    for n in numbers:
        v = (n or "").strip()
        if not v or v in seen:
            continue
        seen.add(v)
        deduped.append(v)
    return deduped


def _localize_timestamp(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is not None:
        return value
    tz = timezone(settings.timezone)
    return tz.localize(value)


def _date_bounds_naive(report_date: date | None = None) -> tuple[datetime, datetime, str]:
    today = report_date or now_local().date()
    return (
        datetime.combine(today, time.min),
        datetime.combine(today, time.max),
        today.strftime("%Y-%m-%d"),
    )


def _today_bounds_naive() -> tuple[datetime, datetime, str]:
    return _date_bounds_naive()


def _person_label(value: str | None, fallback: str | None = None) -> str:
    text = (value or fallback or "").strip()
    return text if text else "Not specified"


def _short_text(value: str | None, limit: int = 700) -> str:
    text = " ".join((value or "").split())
    if not text:
        return "N/A"
    if len(text) <= limit:
        return text
    return f"{text[: limit - 3].rstrip()}..."


def _format_hiccup_basic(hiccup: Hiccup, index: int) -> list[str]:
    return [
        f"{index}. *Hiccup ID:* {hiccup.hiccup_id}",
        f"   *Raised By:* {_person_label(hiccup.raised_by_name)}",
        f"   *Raised Against:* {_person_label(hiccup.raised_against_name, hiccup.raised_against)}",
        f"   *Type:* {hiccup.hiccup_type or 'N/A'}",
        f"   *Hiccup Text:* {_short_text(hiccup.description)}",
    ]


def _format_hiccup_section(
    title: str,
    hiccups: list[Hiccup],
    *,
    include_response: bool = False,
) -> list[str]:
    lines = [title, f"Count: {len(hiccups)}"]
    if not hiccups:
        lines.append("No records.")
        return lines
    for index, hiccup in enumerate(hiccups, start=1):
        lines.append("")
        lines.extend(_format_hiccup_basic(hiccup, index))
        if include_response:
            lines.append(f"   *Response:* {_short_text(hiccup.response_text)}")
    return lines


def build_hiccup_whatsapp_report(db: Session, report_date: date | None = None) -> str:
    """
    Build the three-part Hiccup report for the current local date.
    """
    mark_overdue_flags(db)
    db.flush()

    today_start, today_end, today_label = _date_bounds_naive(report_date)
    blocked_72_start = today_start - timedelta(hours=72)
    blocked_72_end = today_end - timedelta(hours=72)

    today_open = (
        db.query(Hiccup)
        .filter(
            Hiccup.created_at >= today_start,
            Hiccup.created_at <= today_end,
            Hiccup.status == "Open",
            Hiccup.response_text.is_(None),
        )
        .order_by(Hiccup.created_at.asc(), Hiccup.hiccup_id.asc())
        .all()
    )

    blocked_today = (
        db.query(Hiccup)
        .filter(
            Hiccup.created_at >= blocked_72_start,
            Hiccup.created_at <= blocked_72_end,
            Hiccup.status == "Open",
            Hiccup.response_blocked.is_(True),
        )
        .order_by(Hiccup.created_at.asc(), Hiccup.hiccup_id.asc())
        .all()
    )

    responded_today = (
        db.query(Hiccup)
        .filter(
            Hiccup.created_at >= today_start,
            Hiccup.created_at <= today_end,
            Hiccup.response_text.isnot(None),
            Hiccup.response_text != "",
        )
        .order_by(Hiccup.created_at.asc(), Hiccup.hiccup_id.asc())
        .all()
    )

    lines = [
        "Daily Hiccup Report",
        f"Date: {today_label}",
        "",
    ]
    lines.extend(_format_hiccup_section("1) Today's Open Hiccups - Response Pending", today_open))
    lines.extend(["", "------------------------------", ""])
    lines.extend(_format_hiccup_section("2) 72 Hours Completed - Response Blocked Today", blocked_today))
    lines.extend(["", "------------------------------", ""])
    lines.extend(
        _format_hiccup_section(
            "3) Today's Hiccups With Response",
            responded_today,
            include_response=True,
        )
    )
    return "\n".join(lines)


def build_today_hiccup_whatsapp_report(db: Session) -> str:
    return build_hiccup_whatsapp_report(db)


def build_hiccup_whatsapp_messages(
    db: Session,
    report_date: date | None = None,
) -> list[str]:
    """
    Build three separate Hiccup WhatsApp messages for the current local date.
    """
    mark_overdue_flags(db)
    db.flush()

    today_start, today_end, today_label = _date_bounds_naive(report_date)
    blocked_72_start = today_start - timedelta(hours=72)
    blocked_72_end = today_end - timedelta(hours=72)

    today_open = (
        db.query(Hiccup)
        .filter(
            Hiccup.created_at >= today_start,
            Hiccup.created_at <= today_end,
            Hiccup.status == "Open",
            Hiccup.response_text.is_(None),
        )
        .order_by(Hiccup.created_at.asc(), Hiccup.hiccup_id.asc())
        .all()
    )
    blocked_today = (
        db.query(Hiccup)
        .filter(
            Hiccup.created_at >= blocked_72_start,
            Hiccup.created_at <= blocked_72_end,
            Hiccup.status == "Open",
            Hiccup.response_blocked.is_(True),
        )
        .order_by(Hiccup.created_at.asc(), Hiccup.hiccup_id.asc())
        .all()
    )
    responded_today = (
        db.query(Hiccup)
        .filter(
            Hiccup.created_at >= today_start,
            Hiccup.created_at <= today_end,
            Hiccup.response_text.isnot(None),
            Hiccup.response_text != "",
        )
        .order_by(Hiccup.created_at.asc(), Hiccup.hiccup_id.asc())
        .all()
    )

    messages = []
    section = ["Daily Hiccup Report", f"Date: {today_label}", ""]
    section.extend(_format_hiccup_section("1) Today's Open Hiccups - Response Pending", today_open))
    messages.append("\n".join(section))

    section = ["Daily Hiccup Report", f"Date: {today_label}", ""]
    section.extend(_format_hiccup_section("2) 72 Hours Completed - Response Blocked Today", blocked_today))
    messages.append("\n".join(section))

    section = ["Daily Hiccup Report", f"Date: {today_label}", ""]
    section.extend(
        _format_hiccup_section(
            "3) Today's Hiccups With Response",
            responded_today,
            include_response=True,
        )
    )
    messages.append("\n".join(section))

    return messages


def build_today_hiccup_whatsapp_messages(db: Session) -> list[str]:
    return build_hiccup_whatsapp_messages(db)


def send_today_hiccup_whatsapp_report(
    db: Session,
    to_number: str = "919810030372",
) -> bool:
    message = build_today_hiccup_whatsapp_report(db)
    return send_bulk(_dedup_numbers([to_number]), message)


def send_today_hiccup_whatsapp_reports_separately(
    db: Session,
    to_number: str = "919810030372",
) -> bool:
    success = False
    numbers = _dedup_numbers([to_number])
    for message in build_today_hiccup_whatsapp_messages(db):
        success = send_bulk(numbers, message) or success
    return success


def send_hiccup_whatsapp_reports_separately(
    db: Session,
    report_date: date,
    to_number: str = "919810030372",
) -> bool:
    success = False
    numbers = _dedup_numbers([to_number])
    for message in build_hiccup_whatsapp_messages(db, report_date=report_date):
        success = send_bulk(numbers, message) or success
    return success


def notify_on_creation(db: Session, hiccup: Hiccup):
    numbers: List[str] = []
    target_label = (
        hiccup.raised_against_name or hiccup.raised_against or "Not specified"
    )
    public_token = None
    if hiccup.hiccup_type == "Person Related" and hiccup.raised_against:
        staff = _get_staff(db, hiccup.raised_against)
        if staff and staff.contact:
            numbers.append(staff.contact)
            public_token = create_public_response_token(
                {
                    "user_id": staff.id,
                    "role": "external",
                    "department_id": staff.department_id,
                    "name": staff.name,
                    "hiccup_id": hiccup.hiccup_id,
                    "purpose": "response_link",
                },
                expires_delta=timedelta(days=3),
            )
    else:
        numbers.extend(
            [
                n.strip()
                for n in settings.management_group_numbers.split(",")
                if n.strip()
            ]
        )

    if not numbers:
        return
    internal_host = settings.whatsapp_response_base_url or settings.frontend_base_url
    external_host = settings.external_whatsapp_response_base_url or internal_host

    if public_token:
        token_param = quote_plus(public_token)
        internal_url = f"{internal_host}/wa/redirect/{hiccup.hiccup_id}?t={token_param}"
        external_url = f"{external_host}/wa/redirect/{hiccup.hiccup_id}?t={token_param}"
    else:
        internal_url = f"{internal_host}/hiccups/{hiccup.hiccup_id}"
        external_url = f"{external_host}/hiccups/{hiccup.hiccup_id}"

    message_lines = [
        "New Hiccup Raised!",
        f"ID: {hiccup.hiccup_id}",
        f"Raised By: {hiccup.raised_by_name} ({_resolve_department(db, hiccup.raised_by_department)})",
        f"Raised Against: {target_label}",
        f"Type: {hiccup.hiccup_type}",
        f"Time: {hiccup.created_at.strftime('%Y-%m-%d %H:%M')}",
        f"Summary: {(hiccup.description or '').strip()[:120] or 'N/A'}",
        "Tap to respond (choose link based on location):",
        f"- In office (192.168.0.173): {internal_url}",
        f"- Outside office (internet): {external_url}",
        "Copy-paste the text box, submit it, and you're done.",
    ]

    send_bulk(_dedup_numbers(numbers), "\n".join(message_lines))


def enqueue_creation_notification(hiccup_id: str) -> None:
    def _worker():
        db = SessionLocal()
        try:
            hiccup = db.query(Hiccup).filter(Hiccup.hiccup_id == hiccup_id).first()
            if hiccup:
                notify_on_creation(db, hiccup)
        except Exception as exc:  # pragma: no cover
            logger.exception("Creation notification failed for %s: %s", hiccup_id, exc)
        finally:
            db.close()

    threading.Thread(target=_worker, daemon=True).start()


def _build_response_token(staff: Staff, hiccup: Hiccup) -> str:
    return create_public_response_token(
        {
            "user_id": staff.id,
            "role": "external",
            "department_id": staff.department_id,
            "name": staff.name,
            "hiccup_id": hiccup.hiccup_id,
            "purpose": "response_link",
        },
        expires_delta=timedelta(days=3),
    )                   


def _build_response_urls(hiccup: Hiccup, token: str) -> tuple[str, str]:
    """
    Build both internal (office) and external (internet) response links for a hiccup.
    """
    internal_host = settings.whatsapp_response_base_url or settings.frontend_base_url
    external_host = settings.external_whatsapp_response_base_url or internal_host
    params = quote_plus(token)
    internal_url = f"{internal_host}/wa/redirect/{hiccup.hiccup_id}?t={params}"
    external_url = f"{external_host}/wa/redirect/{hiccup.hiccup_id}?t={params}"
    return internal_url, external_url


def send_daily_summary(db: Session):
    today_start = now_local().replace(hour=0, minute=0, second=0, microsecond=0)
    stats = recent_stats(db)
    dept_counts = _department_counts(db, today_start)
    trend_list = trend_alerts(db)
    trend_lines = [
        f"{alert['label']} has {alert['count']} hiccups in last 7 days"
        for alert in trend_list
    ]
    samples = _fetch_samples(db, today_start, limit=2)
    dept_lines = [f"{dept}: {count}" for dept, count in dept_counts.items()]
    sample_lines = [_format_sample(sample) for sample in samples]
    message_lines = [
        "Daily Hiccup Summary",
        f"Date: {today_start.strftime('%Y-%m-%d')}",
        "",
        "Today's summary:",
        f"- Raised: {stats['raised_today']}",
        f"- Responded: {stats['responded_today']}",
        f"- Closed: {stats['closed_today']}",
        f"- Escalated to NC: {stats['escalated_today']}",
        "",
        "Per-department counts:",
        *(dept_lines if dept_lines else ["None registered today"]),
        "",
        "Trend alerts:",
        *(trend_lines if trend_lines else ["No trend alerts today"]),
        "",
        "Sample hiccups:",
        *(sample_lines if sample_lines else ["None yet today"]),
    ]
    numbers = _dedup_numbers(
        [n.strip() for n in settings.management_group_numbers.split(",") if n.strip()]
    )
    # Disabled: summary WhatsApp blast to management group
    # if numbers:
    #     send_bulk(numbers, "\n".join(message_lines))


def _resolve_department(db: Session, department_id: Optional[int]) -> str:
    if not department_id:
        return "Unassigned"
    dept = db.query(Department).filter(Department.id == department_id).first()
    return dept.name if dept else f"Dept {department_id}"


def _get_staff(db: Session, raised_against: str | None) -> Optional[Staff]:
    if not raised_against:
        return None
    try:
        staff_id = int(raised_against)
    except ValueError:
        return None
    return db.query(Staff).filter(Staff.id == staff_id).first()


def _department_counts(db: Session, since: datetime) -> Counter:
    departments = {d.id: d.name for d in db.query(Department).all()}
    counts: Counter = Counter()
    rows = db.query(Hiccup).filter(Hiccup.created_at >= since).all()
    for hiccup in rows:
        label = departments.get(hiccup.raised_by_department, "Unassigned")
        counts[label] += 1
    return counts


def _fetch_samples(db: Session, since: datetime, limit: int = 2) -> List[Hiccup]:
    return (
        db.query(Hiccup)
        .filter(Hiccup.created_at >= since)
        .order_by(Hiccup.created_at.desc())
        .limit(limit)
        .all()
    )


def _format_sample(hiccup: Hiccup) -> str:
    target = hiccup.raised_against_name or hiccup.raised_against or "N/A"
    summary = (hiccup.description or "").strip()
    if len(summary) > 80:
        summary = f"{summary[:77].rstrip()}..."
    return f"{hiccup.hiccup_id} ({hiccup.status}) - {target}: {summary or 'No description'}"


def send_nc_assignment_notice(db: Session, hiccup: Hiccup):
    """
    Notify the staff member when a hiccup is escalated to NC and assigned to them.
    """
    staff_id = getattr(hiccup, "nc_assigned_staff_id", None)
    if not staff_id:
        return
    staff = db.query(Staff).filter(Staff.id == staff_id).first()
    if not staff or not staff.contact:
        logger.info(
            "NC assignment notice skipped: no contact for staff_id=%s", staff_id
        )
        return
    summary = (hiccup.description or "").strip()
    if len(summary) > 140:
        summary = f"{summary[:137].rstrip()}..."
    assigned_link_external = f"{settings.external_whatsapp_response_base_url or settings.frontend_base_url}/assigned"
    assigned_link_internal = f"{settings.whatsapp_response_base_url or settings.frontend_base_url}/assigned"
    hiccup_link = f"{settings.frontend_base_url}/hiccups/{hiccup.hiccup_id}"
    message_lines = [
        "Hiccup escalated to NC and assigned to you.",
        f"ID: {hiccup.hiccup_id}",
        f"Type: {hiccup.hiccup_type or 'N/A'}",
        f"Raised by: {hiccup.raised_by_name or 'Unknown'}",
        f"Summary: {summary or 'N/A'}",
        "",
        "Steps:",
        "- Login to the portal.",
        "- Open 'Assigned to Me' and use the Hiccup ID above.",
        "Assigned list:",
        f"- In office (192.168.0.173): {assigned_link_internal}",
        f"- Outside office (internet): {assigned_link_external}",
        f"Hiccup page: {hiccup_link}",
    ]
    logger.info(
        "Sending NC assignment notice for %s to %s", hiccup.hiccup_id, staff.contact
    )
    send_bulk(_dedup_numbers([staff.contact]), "\n".join(message_lines))


def send_nc_escalated_notice_to_target(db: Session, hiccup: Hiccup):
    """
    Notify the staff member against whom the hiccup was raised when it is escalated to NC.
    """
    target_staff = _get_staff(db, hiccup.raised_against)
    if not target_staff or not target_staff.contact:
        logger.info(
            "NC target notice skipped: no contact for raised_against=%s",
            hiccup.raised_against,
        )
        return

    assigned_staff_name = "Not assigned"
    if getattr(hiccup, "nc_assigned_staff_id", None):
        assigned_staff = (
            db.query(Staff).filter(Staff.id == hiccup.nc_assigned_staff_id).first()
        )
        if assigned_staff and assigned_staff.name:
            assigned_staff_name = assigned_staff.name

    escalated_by_name = "Unknown"
    if getattr(hiccup, "escalated_by", None):
        escalated_by_staff = db.query(Staff).filter(Staff.id == hiccup.escalated_by).first()
        if escalated_by_staff and escalated_by_staff.name:
            escalated_by_name = escalated_by_staff.name

    summary = (hiccup.description or "").strip()
    if len(summary) > 140:
        summary = f"{summary[:137].rstrip()}..."

    message_lines = [
        "Hiccup Update",
        "",
        f"Hiccup #{hiccup.hiccup_id} related to you has been escalated to NC for further review.",
        "",
        f"Escalated by: {escalated_by_name}",
        f"Raised by: {hiccup.raised_by_name or 'Unknown'}",
        f"Type: {hiccup.hiccup_type or 'N/A'}",
        f"Summary: {summary or 'N/A'}",
        f"Assigned to: {assigned_staff_name}",
    ]
    logger.info(
        "Sending NC target notice for %s to %s",
        hiccup.hiccup_id,
        target_staff.contact,
    )
    send_bulk(_dedup_numbers([target_staff.contact]), "\n".join(message_lines))


def enqueue_nc_assignment_notice(hiccup_id: str) -> None:
    def _worker():
        db = SessionLocal()
        try:
            hiccup = db.query(Hiccup).filter(Hiccup.hiccup_id == hiccup_id).first()
            if hiccup:
                send_nc_assignment_notice(db, hiccup)
                send_nc_escalated_notice_to_target(db, hiccup)
        except Exception as exc:  # pragma: no cover
            logger.exception(
                "NC assignment notification failed for %s: %s", hiccup_id, exc
            )
        finally:
            db.close()

    threading.Thread(target=_worker, daemon=True).start()


def send_response_reminders(db: Session):
    now = now_local()
    hinges = (
        db.query(Hiccup)
        .filter(
            Hiccup.status == "Open",
            Hiccup.raised_against.isnot(None),
            Hiccup.response_blocked.is_(False),
            (Hiccup.reminder_sent.is_(False))
            | (Hiccup.overdue_msg_sent.is_(False))
            | (Hiccup.escalate_msg_sent.is_(False)),
        )
        .all()
    )
    logger.info("send_response_reminders triggered for %d open hiccups", len(hinges))
    management_numbers = [
        n.strip() for n in settings.management_group_numbers.split(",") if n.strip()
    ]
    staff_ids = set()
    for hiccup in hinges:
        try:
            staff_ids.add(int(hiccup.raised_against))
        except (TypeError, ValueError):
            continue
    staff_map = {}
    if staff_ids:
        staff_rows = db.query(Staff).filter(Staff.id.in_(staff_ids)).all()
        staff_map = {staff.id: staff for staff in staff_rows}
    for hiccup in hinges:
        try:
            staff = staff_map.get(int(hiccup.raised_against))
        except (TypeError, ValueError):
            staff = None
        if not staff or not staff.contact:
            continue
        created_at = _localize_timestamp(hiccup.created_at)
        if not created_at:
            continue
        age = now - created_at
        if hiccup.response_blocked:
            logger.info(
                "Skipping response reminder for blocked hiccup %s",
                hiccup.hiccup_id,
            )
            continue
        reminder_delta = timedelta(minutes=settings.response_reminder_minutes)
        overdue_delta = timedelta(minutes=settings.response_overdue_minutes)
        escalate_delta = timedelta(minutes=settings.response_escalate_minutes)
        numbers = [staff.contact]
        if age >= escalate_delta and not hiccup.escalate_msg_sent:
            token = _build_response_token(staff, hiccup)
            internal_url, external_url = _build_response_urls(hiccup, token)
            hours_old = int(age.total_seconds() // 3600)
            # User-facing message (with links)
            message = "\n".join(
                [
                    f"Hiccup {hiccup.hiccup_id} is {hours_old}+ hours old.",
                    "Management will escalate to NC soon.",
                    f"Overdue flag: {hiccup.is_response_overdue}",
                    "Respond here (choose based on location):",
                    f"- In office (192.168.0.173): {internal_url}",
                    f"- Outside office (internet): {external_url}",
                ]
            )
            sent = send_bulk(numbers, message)
            if sent:
                hiccup.escalate_msg_sent = True
                logger.info(
                    "Escalation notice sent for %s -> %s",
                    hiccup.hiccup_id,
                    numbers,
                )
            else:
                logger.warning(
                    "Escalation notice failed, will retry next run for %s",
                    hiccup.hiccup_id,
                )
            if management_numbers:
                mgmt_message = "\n".join(
                    [
                        f"Hiccup {hiccup.hiccup_id} is {hours_old}+ hours old.",
                        "No response yet — please take action.",
                        f"Overdue flag: {hiccup.is_response_overdue}",
                    ]
                )
                logger.info(
                    "Escalation notice for %s -> %s",
                    hiccup.hiccup_id,
                    management_numbers,
                )
                # send_bulk(management_numbers, mgmt_message)  # Disabled: escalation to group
        elif age >= overdue_delta and not hiccup.overdue_msg_sent:
            token = _build_response_token(staff, hiccup)
            internal_url, external_url = _build_response_urls(hiccup, token)
            message = "\n".join(
                [
                    f"Hiccup {hiccup.hiccup_id} is overdue (24h).",
                    "This hiccup is now marked response_overdue.",
                    "Please respond (choose based on location):",
                    f"- In office (192.168.0.173): {internal_url}",
                    f"- Outside office (internet): {external_url}",
                ]
            )
            sent = send_bulk(numbers, message)
            if sent:
                hiccup.overdue_msg_sent = True
                logger.info(
                    "Overdue reminder sent for %s -> %s",
                    hiccup.hiccup_id,
                    staff.contact,
                )
            else:
                logger.warning(
                    "Overdue reminder failed, will retry next run for %s",
                    hiccup.hiccup_id,
                )
        elif age >= reminder_delta and not hiccup.reminder_sent:
            token = _build_response_token(staff, hiccup)
            internal_url, external_url = _build_response_urls(hiccup, token)
            message = "\n".join(
                [
                    f"Reminder: Hiccup {hiccup.hiccup_id} needs response soon.",
                    "Submit within 24 hours to avoid overdue flag.",
                    "Respond here (choose based on location):",
                    f"- In office (192.168.0.173): {internal_url}",
                    f"- Outside office (internet): {external_url}",
                ]
            )
            sent = send_bulk(numbers, message)
            if sent:
                hiccup.reminder_sent = True
                logger.info(
                    "Reminder message sent for %s -> %s",
                    hiccup.hiccup_id,
                    staff.contact,
                )
            else:
                logger.warning(
                    "Reminder send failed, will retry next run for %s",
                    hiccup.hiccup_id,
                )

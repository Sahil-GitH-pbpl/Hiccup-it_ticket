import sys
from datetime import date, datetime, time, timedelta

from app.db.session import SessionLocal
from app.integrations.whatsapp_client import send_bulk
from app.models.hiccup import Hiccup
from app.services.hiccup_service import mark_overdue_flags
from app.utils.time_utils import now_local


def _date_bounds_naive(report_date=None):
    today = report_date or now_local().date()
    return (
        datetime.combine(today, time.min),
        datetime.combine(today, time.max),
        today.strftime("%Y-%m-%d"),
    )


def _person_label(value, fallback=None):
    text = (value or fallback or "").strip()
    return text if text else "Not specified"


def _short_text(value, limit=700):
    text = " ".join((value or "").split())
    if not text:
        return "N/A"
    if len(text) <= limit:
        return text
    return f"{text[: limit - 3].rstrip()}..."


def _format_hiccup_basic(hiccup, index):
    return [
        f"{index}. *Hiccup ID:* {hiccup.hiccup_id}",
        f"   *Raised By:* {_person_label(hiccup.raised_by_name)}",
        f"   *Raised Against:* {_person_label(hiccup.raised_against_name, hiccup.raised_against)}",
        f"   *Type:* {hiccup.hiccup_type or 'N/A'}",
        f"   *Hiccup Text:* {_short_text(hiccup.description)}",
    ]


def _format_section(title, hiccups, include_response=False):
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


def build_messages(db, report_date=None):
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

    lines = ["Daily Hiccup Report", f"Date: {today_label}", ""]
    lines.extend(_format_section("1) Today's Open Hiccups - Response Pending", today_open))
    messages.append("\n".join(lines))

    lines = ["Daily Hiccup Report", f"Date: {today_label}", ""]
    lines.extend(_format_section("2) 72 Hours Completed - Response Blocked Today", blocked_today))
    messages.append("\n".join(lines))

    lines = ["Daily Hiccup Report", f"Date: {today_label}", ""]
    lines.extend(
        _format_section(
            "3) Today's Hiccups With Response",
            responded_today,
            include_response=True,
        )
    )
    messages.append("\n".join(lines))

    return messages


def main():
    report_date = None
    if len(sys.argv) > 1:
        report_date = date.fromisoformat(sys.argv[1])
    db = SessionLocal()
    try:
        ok = False
        for index, message in enumerate(build_messages(db, report_date), start=1):
            print(f"--- message {index} ---")
            print(message)
            sent = send_bulk(["919810030372"], message)
            print(f"message_{index}_sent={sent}")
            ok = sent or ok
        db.commit()
        print(f"any_sent={ok}")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()

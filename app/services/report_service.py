from datetime import datetime, timedelta
from collections import Counter, defaultdict
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.hiccup import Hiccup
from app.models.escalation import NCEscalationForm
from app.models.staff import Staff
from app.services.hiccup_service import format_target_label, trend_alerts
from app.utils.time_utils import now_local


def learning_digest(db: Session, month: int, year: int):
    start = datetime(year, month, 1)
    if month == 12:
        end = datetime(year + 1, 1, 1)
    else:
        end = datetime(year, month + 1, 1)
    rows = (
        db.query(Hiccup)
        .filter(Hiccup.created_at >= start, Hiccup.created_at < end)
        .all()
    )
    by_type = Counter([h.hiccup_type for h in rows])
    by_root = Counter([h.root_cause_category for h in rows if h.root_cause_category])
    target_labels = [
        format_target_label(h.raised_against_name, h.raised_against) for h in rows
    ]
    top_recurring = [
        f"{label} ({count})" for label, count in Counter(target_labels).most_common(5)
    ]
    corrective_summaries = [h.corrective_action for h in rows if h.corrective_action]
    return {
        "month": start.strftime("%B %Y"),
        "total": len(rows),
        "by_type": dict(by_type),
        "by_root_cause_category": dict(by_root),
        "top_recurring": top_recurring,
        "corrective_summaries": corrective_summaries,
    }


def trend_buckets(db: Session):
    by_department = defaultdict(int)
    by_type = defaultdict(int)
    by_source = defaultdict(int)
    by_time_bucket = defaultdict(int)
    rows = db.query(
        Hiccup.hiccup_type,
        Hiccup.raised_by_department,
        Hiccup.source_module,
        Hiccup.created_at,
    ).all()
    for h in rows:
        by_type[h.hiccup_type] += 1
        if h.raised_by_department:
            by_department[str(h.raised_by_department)] += 1
        if h.source_module:
            by_source[h.source_module] += 1
        bucket = "Morning"
        if h.created_at.hour >= 12 and h.created_at.hour < 18:
            bucket = "Evening"
        elif h.created_at.hour >= 18:
            bucket = "Night"
        by_time_bucket[bucket] += 1
    return {
        "by_department": by_department,
        "by_type": by_type,
        "by_source": by_source,
        "by_time_bucket": by_time_bucket,
    }


def recent_stats(db: Session):
    today = now_local().date()
    start = datetime(today.year, today.month, today.day)
    base_filter = [Hiccup.created_at >= start]
    raised_today = (
        db.query(func.count(Hiccup.hiccup_id)).filter(*base_filter).scalar() or 0
    )
    responded_today = (
        db.query(func.count(Hiccup.hiccup_id))
        .filter(*(base_filter + [Hiccup.status == "Responded"]))
        .scalar()
        or 0
    )
    closed_today = (
        db.query(func.count(Hiccup.hiccup_id))
        .filter(*(base_filter + [Hiccup.status == "Closed"]))
        .scalar()
        or 0
    )
    escalated_today = (
        db.query(func.count(Hiccup.hiccup_id))
        .filter(*(base_filter + [Hiccup.status == "Escalated to NC"]))
        .scalar()
        or 0
    )
    return {
        "raised_today": raised_today,
        "responded_today": responded_today,
        "closed_today": closed_today,
        "escalated_today": escalated_today,
    }


def assigned_counts(db: Session, user_id: int):
    my_rows = (
        db.query(Hiccup.status, func.count(Hiccup.hiccup_id))
        .filter(Hiccup.raised_by == user_id)
        .group_by(Hiccup.status)
        .all()
    )
    assigned_rows = (
        db.query(Hiccup.status, func.count(Hiccup.hiccup_id))
        .filter(Hiccup.raised_against == str(user_id))
        .group_by(Hiccup.status)
        .all()
    )
    assigned_counter = Counter({status: count for status, count in assigned_rows})
    staff_name = (
        db.query(Staff.name).filter(Staff.id == user_id).scalar()
    )
    if staff_name:
        normalized_name = staff_name.strip()
        if normalized_name:
            nc_count = (
                db.query(func.count(Hiccup.hiccup_id))
                .join(
                    NCEscalationForm,
                    NCEscalationForm.hiccup_id == Hiccup.hiccup_id,
                )
                .filter(
                    Hiccup.status == "Escalated to NC",
                    NCEscalationForm.staff_name.isnot(None),
                    func.lower(func.trim(NCEscalationForm.staff_name))
                    == normalized_name.lower(),
                )
                .scalar()
                or 0
            )
            if nc_count:
                assigned_counter["NC escalations with your name"] = nc_count
    return {
        "my_counts": Counter({status: count for status, count in my_rows}),
        "assigned_counts": assigned_counter,
    }


def dashboard_summary(db: Session, user_id: int):
    counts = assigned_counts(db, user_id)
    response_overdue = (
        db.query(func.count(Hiccup.hiccup_id))
        .filter(Hiccup.is_response_overdue.is_(True))
        .scalar()
        or 0
    )
    closure_overdue = (
        db.query(func.count(Hiccup.hiccup_id))
        .filter(Hiccup.is_closure_overdue.is_(True))
        .scalar()
        or 0
    )
    return {
        "my_counts": counts["my_counts"],
        "assigned_counts": counts["assigned_counts"],
        "recent_stats": recent_stats(db),
        "overdue": {
            "response": response_overdue,
            "closure": closure_overdue,
        },
        "trend_alerts": trend_alerts(db),
    }

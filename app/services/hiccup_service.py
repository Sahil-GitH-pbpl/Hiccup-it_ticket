import json
import os
import logging
from datetime import datetime, date, time, timedelta
from pathlib import Path
from typing import Dict, List, Optional

from fastapi import HTTPException, UploadFile
from sqlalchemy import func
from sqlalchemy.orm import Session
from sqlalchemy import or_
from pytz import timezone

from app.models.department import Department
from app.models.hiccup import Hiccup, HiccupAuditLog
from app.models.escalation import NCEscalationForm
from app.models.staff import Staff
from app.utils.id_generator import generate_hiccup_id
from app.core.config import get_settings
from app.core.security import is_allowlisted_hiccup_admin
from app.utils.time_utils import now_local

settings = get_settings()
logger = logging.getLogger(__name__)

ROOT_CAUSE_LABELS = {
    "lack_of_training": "Lack of Training / Knowledge",
    "ignored_instructions": "Ignored instructions / coaching (empathy/listening)",
    "time_mismanagement": "Time mismanagement / carelessness",
    "misunderstanding_process": "Misunderstanding of Process / SOP",
    "communication_gaps": "Communication gaps (tone)",
    "repeated_feedback": "Repeated mistake after feedback",
    "other": "Other",
}


def _is_management_user(user) -> bool:
    user_id = getattr(user, "user_id", None)
    role = str(getattr(user, "role", "") or "").lower()
    return bool(
        is_allowlisted_hiccup_admin(user_id)
        or getattr(user, "is_admin_like", False)
        or role in {"admin", "management"}
    )


def _parse_date(value: Optional[str]) -> Optional[date]:
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _deserialize_list(value: Optional[str]) -> List[str]:
    if not value:
        return []
    try:
        decoded = json.loads(value)
    except json.JSONDecodeError:
        return []
    if isinstance(decoded, list):
        return [str(item) for item in decoded]
    return []


def _format_date(value: Optional[date]) -> Optional[str]:
    if not value:
        return None
    return value.isoformat()


def _normalize_text(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    trimmed = value.strip()
    return trimmed if trimmed else None


def _parse_int(value: Optional[str]) -> Optional[int]:
    if value is None:
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


def build_root_cause_summary(flags: Optional[List[str]], other: Optional[str]) -> Optional[str]:
    labels = []
    if flags:
        for flag in flags:
            candidate = ROOT_CAUSE_LABELS.get(flag)
            if candidate:
                labels.append(candidate)
    if other:
        normalized = other.strip()
        if normalized:
            labels.append(normalized)
    if labels:
        return ", ".join(labels)
    return None


def _upsert_escalation_form(db: Session, hiccup_id: str, form_data: Dict):
    payload = {
        "staff_name": _normalize_text(form_data.get("staff_name")),
        "issue_description": _normalize_text(form_data.get("issue_description")),
        "root_cause_flags": _serialize_list(form_data.get("root_cause_flags")),
        "root_cause_explanation": _normalize_text(form_data.get("root_cause_explanation")),
        "root_cause_other": _normalize_text(form_data.get("root_cause_other")),
        "corrective_action": _normalize_text(form_data.get("corrective_action")),
        "corrective_action_by": _normalize_text(form_data.get("corrective_action_by")),
        "corrective_action_date": _parse_date(form_data.get("corrective_action_date")),
        "person_responsible": _normalize_text(form_data.get("person_responsible")),
        "timeline_for_completion": _normalize_text(form_data.get("timeline_for_completion")),
        "preventive_actions": _serialize_list(form_data.get("preventive_actions")),
        "preventive_other": _normalize_text(form_data.get("preventive_other")),
        "preventive_details": _normalize_text(form_data.get("preventive_details")),
        "assigned_staff_id": _parse_int(form_data.get("staff_id")),
    }
    form = (
        db.query(NCEscalationForm)
        .filter(NCEscalationForm.hiccup_id == hiccup_id)
        .first()
    )
    if form:
        for key, value in payload.items():
            setattr(form, key, value)
    else:
        db.add(NCEscalationForm(hiccup_id=hiccup_id, **payload))


def _map_escalation_form(form: NCEscalationForm) -> Dict:
    return {
        "staff_name": form.staff_name,
        "staff_id": form.assigned_staff_id,
        "root_cause_flags": _deserialize_list(form.root_cause_flags),
        "root_cause_other": form.root_cause_other,
        "corrective_action": form.corrective_action,
        "corrective_action_by": form.corrective_action_by,
        "corrective_action_date": _format_date(form.corrective_action_date),
        "person_responsible": form.person_responsible,
        "timeline_for_completion": form.timeline_for_completion,
        "preventive_actions": _deserialize_list(form.preventive_actions),
        "preventive_other": form.preventive_other,
    }


def get_nc_escalation_form(db: Session, hiccup_id: str) -> Dict:
    get_hiccup(db, hiccup_id)
    form = (
        db.query(NCEscalationForm)
        .filter(NCEscalationForm.hiccup_id == hiccup_id)
        .first()
    )
    if not form:
        raise HTTPException(status_code=404, detail="NC escalation form not found")
    return _map_escalation_form(form)


def update_nc_escalation_form(
    db: Session, user, hiccup_id: str, payload: Dict
) -> Dict:
    hiccup = get_hiccup(db, hiccup_id)
    if hiccup.status != "Escalated to NC":
        raise HTTPException(
            status_code=400,
            detail="NC escalation form can only be updated while the hiccup is escalated to NC",
        )
    staff_name = _normalize_text(payload.get("staff_name"))
    payload["staff_name"] = staff_name
    corrective_action = payload.get("corrective_action")
    trimmed_action = _normalize_text(corrective_action)
    root_flags = payload.get("root_cause_flags")
    root_other = payload.get("root_cause_other")
    submitted_flags = []
    if isinstance(root_flags, list):
        for flag in root_flags:
            if flag is None:
                continue
            flag_str = str(flag).strip()
            if flag_str:
                submitted_flags.append(flag_str)
    payload["root_cause_flags"] = submitted_flags
    root_summary = build_root_cause_summary(submitted_flags, root_other)
    hiccup.root_cause = root_summary
    hiccup.corrective_action = trimmed_action
    payload["corrective_action"] = trimmed_action
    preventive_actions = payload.get("preventive_actions")
    if isinstance(preventive_actions, list):
        cleaned_preventive = []
        for item in preventive_actions:
            if not item:
                continue
            normalized = item.strip() if isinstance(item, str) else None
            if normalized:
                cleaned_preventive.append(normalized)
        payload["preventive_actions"] = cleaned_preventive
    _upsert_escalation_form(db, hiccup_id, payload)
    log_action(db, hiccup_id, "Updated NC form", user.user_id)
    db.commit()
    refreshed_form = (
        db.query(NCEscalationForm)
        .filter(NCEscalationForm.hiccup_id == hiccup_id)
        .first()
    )
    if not refreshed_form:
        raise HTTPException(status_code=404, detail="NC escalation form not found")
    return _map_escalation_form(refreshed_form)


def format_target_label(name: str | None, identifier: str | None) -> str:
    if name and identifier:
        return f"{name} ({identifier})"
    if name:
        return name
    if identifier:
        return str(identifier)
    return "Unknown"


ALLOWED_STATUSES = {"Open", "Responded", "Under Review", "Closed", "Escalated to NC"}


def _has_management_access(designation: Optional[str], role: Optional[str]) -> bool:
    keywords = ["management", "manager", "admin", "supervisor", "lead"]
    if designation:
        text = designation.lower()
        if any(key in text for key in keywords):
            return True
    if role:
        role_text = str(role).lower()
        if role_text in {"admin", "management"}:
            return True
    return False


def _sanitize_filename(filename: str) -> str:
    if not filename:
        return "attachment"
    cleaned = Path(filename).name
    return cleaned if cleaned else "attachment"


def _serialize_list(value: Optional[List[str]]) -> Optional[str]:
    if not value:
        return None
    return json.dumps(value)


def _parse_attachments(raw: Optional[str]) -> List[str]:
    if not raw:
        return []
    try:
        decoded = json.loads(raw)
        if isinstance(decoded, list):
            return [str(item) for item in decoded if str(item).strip()]
    except json.JSONDecodeError:
        pass
    if isinstance(raw, str):
        trimmed = raw.strip()
        return [trimmed] if trimmed else []
    return []


def has_uploaded_file(file: Optional[UploadFile]) -> bool:
    if not file:
        return False
    filename = getattr(file, "filename", "")
    return bool(filename and filename.strip())


def filter_uploaded_files(files: Optional[List[UploadFile]]) -> List[UploadFile]:
    if not files:
        return []
    return [file for file in files if has_uploaded_file(file)]


def save_attachment(hiccup_id: str, file: UploadFile) -> str:
    upload_dir = Path("uploads") / "hiccups" / hiccup_id
    upload_dir.mkdir(parents=True, exist_ok=True)
    filename = _sanitize_filename(file.filename)
    path = upload_dir / filename
    with path.open("wb") as f:
        f.write(file.file.read())
    return path.as_posix()


def log_action(
    db: Session,
    hiccup_id: str,
    action: str,
    performed_by: int,
    remarks: Optional[str] = None,
):
    audit = HiccupAuditLog(
        hiccup_id=hiccup_id, action=action, performed_by=performed_by, remarks=remarks
    )
    db.add(audit)


def _sanitize_department(db: Session, department_id: Optional[int]) -> Optional[int]:
    if department_id is None:
        return None
    exists = db.query(Department.id).filter(Department.id == department_id).first()
    return department_id if exists else None


def _resolve_department_candidate(
    db: Session, department_id: Optional[int], department_name: Optional[str]
) -> Optional[int]:
    sanitized = _sanitize_department(db, department_id)
    if sanitized is not None:
        return sanitized
    if not department_name:
        return None
    normalized = department_name.strip()
    if not normalized:
        return None
    dept = db.query(Department.id).filter(Department.name.ilike(normalized)).first()
    if dept:
        (dept_id,) = dept
        return dept_id
    return None


def _ensure_timezone(dt: Optional[datetime]) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is not None:
        return dt
    tz = timezone(settings.timezone)
    return tz.localize(dt)


def _fetch_department_name(db: Session, department_id: Optional[int]) -> Optional[str]:
    if department_id is None:
        return None
    department = (
        db.query(Department.name).filter(Department.id == department_id).first()
    )
    if not department:
        return None
    (name,) = department
    return name


def create_hiccup(
    db: Session,
    user,
    data,
    files: Optional[List[UploadFile]] = None,
    is_auto=False,
    source_module=None,
):
    hiccup_id = generate_hiccup_id(db)
    attachments = [
        save_attachment(hiccup_id, file) for file in filter_uploaded_files(files)
    ]
    attachment_path = _serialize_list(attachments)
    current_ts = now_local()

    target_department = None
    staff = None
    if data.hiccup_type == "Person Related" and data.raised_against:
        try:
            staff_id = int(data.raised_against)
        except ValueError:
            staff_id = None
        if staff_id:
            staff = db.query(Staff).filter(Staff.id == staff_id).first()
        target_department = (
            staff.department_id
            if staff and staff.department_id
            else data.raised_against_department
        )
    else:
        target_department = data.raised_against_department

    target_department = _resolve_department_candidate(
        db, target_department, data.raised_against_department_name
    )
    target_department_name = (
        data.raised_against_department_name
        or (staff and staff.departments)
        or _fetch_department_name(db, target_department)
    )
    raised_against_name = (
        staff.name
        if staff and staff.name
        else (data.raised_against_name or data.raised_against)
    )
    hiccup = Hiccup(
        hiccup_id=hiccup_id,
        raised_by=user.user_id,
        raised_by_name=user.name,
        raised_by_department=_sanitize_department(db, user.department_id),
        hiccup_type=data.hiccup_type,
        raised_against=data.raised_against,
        raised_against_name=raised_against_name,
        raised_against_department=target_department,
        raised_against_department_name=target_department_name,
        description=data.description,
        immediate_effect=data.immediate_effect,
        attachment_path=attachment_path,
        status="Open",
        is_auto_generated=is_auto,
        source_module=source_module,
        confidential_flag=data.confidential_flag,
        root_cause_category=data.root_cause_category,
        created_at=current_ts,
        updated_at=current_ts,
    )
    db.add(hiccup)
    log_action(db, hiccup_id, "Created", user.user_id)
    db.commit()
    db.refresh(hiccup)
    return hiccup


def get_hiccup(db: Session, hiccup_id: str) -> Hiccup:
    hiccup = db.query(Hiccup).filter(Hiccup.hiccup_id == hiccup_id).first()
    if not hiccup:
        raise HTTPException(status_code=404, detail="Hiccup not found")
    with_assigned_staff_names(db, [hiccup])
    return hiccup


def list_hiccups_for_user(db: Session, user):
    query = db.query(Hiccup).filter(
        (Hiccup.raised_by == user.user_id)
        | (
            (Hiccup.raised_against == str(user.user_id))
            & (Hiccup.confidential_flag.is_(False))
        )
    )
    rows = query.order_by(Hiccup.created_at.desc()).all()
    return with_assigned_staff_names(db, rows)


def _apply_common_hiccup_filters(
    query,
    *,
    status: Optional[str] = None,
    hiccup_type: Optional[str] = None,
    root_cause_category: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    escalated_only: bool = False,
    overdue_only: bool = False,
    search: Optional[str] = None,
):
    if status:
        query = query.filter(Hiccup.status == status)
    if hiccup_type:
        query = query.filter(Hiccup.hiccup_type == hiccup_type)
    if root_cause_category:
        query = query.filter(Hiccup.root_cause_category == root_cause_category)
    if date_from:
        query = query.filter(Hiccup.created_at >= datetime.combine(date_from, time.min))
    if date_to:
        query = query.filter(Hiccup.created_at <= datetime.combine(date_to, time.max))
    if escalated_only:
        query = query.filter(
            or_(
                Hiccup.status == "Escalated to NC",
                Hiccup.escalated_by.isnot(None),
                Hiccup.nc_assigned_staff_id.isnot(None),
            )
        )
    if overdue_only:
        query = query.filter(
            or_(
                Hiccup.is_response_overdue.is_(True),
                Hiccup.was_response_overdue.is_(True),
                Hiccup.is_closure_overdue.is_(True),
            )
        )
    if search:
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Hiccup.hiccup_id.ilike(term),
                Hiccup.hiccup_type.ilike(term),
                Hiccup.status.ilike(term),
                Hiccup.description.ilike(term),
                Hiccup.immediate_effect.ilike(term),
                Hiccup.response_text.ilike(term),
                Hiccup.raised_by_name.ilike(term),
                Hiccup.raised_against_name.ilike(term),
                Hiccup.raised_against_department_name.ilike(term),
                Hiccup.root_cause_category.ilike(term),
            )
        )
    return query


def _paginate_hiccup_query(query, db: Session, page: int, page_size: int):
    total = query.order_by(None).count()
    total_pages = max((total + page_size - 1) // page_size, 1)
    current_page = min(max(page, 1), total_pages)
    rows = (
        query.order_by(Hiccup.created_at.desc(), Hiccup.hiccup_id.desc())
        .offset((current_page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    rows = with_assigned_staff_names(db, rows)
    return {
        "items": rows,
        "page": current_page,
        "page_size": page_size,
        "total": total,
        "total_pages": total_pages,
    }


def list_hiccups_for_user_paginated(
    db: Session,
    user,
    *,
    page: int,
    page_size: int,
    status: Optional[str] = None,
    hiccup_type: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    escalated_only: bool = False,
    overdue_only: bool = False,
    search: Optional[str] = None,
):
    query = db.query(Hiccup).filter(Hiccup.raised_by == user.user_id)
    query = _apply_common_hiccup_filters(
        query,
        status=status,
        hiccup_type=hiccup_type,
        date_from=date_from,
        date_to=date_to,
        escalated_only=escalated_only,
        overdue_only=overdue_only,
        search=search,
    )
    return _paginate_hiccup_query(query, db, page, page_size)


def list_nc_escalations_for_assigned(db: Session, user):
    rows = (
        db.query(Hiccup)
        .filter(
            or_(
                Hiccup.nc_assigned_staff_id == user.user_id,
                Hiccup.raised_against == str(user.user_id),
            )
        )
        .order_by(Hiccup.created_at.desc())
        .all()
    )
    return with_assigned_staff_names(db, rows)


def list_assigned_hiccups_paginated(
    db: Session,
    user,
    *,
    page: int,
    page_size: int,
    status: Optional[str] = None,
    hiccup_type: Optional[str] = None,
    root_cause_category: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    escalated_only: bool = False,
    overdue_only: bool = False,
    search: Optional[str] = None,
):
    query = db.query(Hiccup).filter(
        or_(
            Hiccup.nc_assigned_staff_id == user.user_id,
            Hiccup.raised_against == str(user.user_id),
        )
    )
    query = _apply_common_hiccup_filters(
        query,
        status=status,
        hiccup_type=hiccup_type,
        root_cause_category=root_cause_category,
        date_from=date_from,
        date_to=date_to,
        escalated_only=escalated_only,
        overdue_only=overdue_only,
        search=search,
    )
    return _paginate_hiccup_query(query, db, page, page_size)


def with_assigned_staff_names(db: Session, hiccups: List[Hiccup]) -> List[Hiccup]:
    ids = {hiccup.nc_assigned_staff_id for hiccup in hiccups if hiccup.nc_assigned_staff_id}
    if not ids:
        return hiccups
    staff_rows = db.query(Staff.id, Staff.name).filter(Staff.id.in_(ids)).all()
    staff_map = {rid: name for rid, name in staff_rows}
    for hiccup in hiccups:
        hiccup.nc_assigned_staff_name = staff_map.get(hiccup.nc_assigned_staff_id)
    return hiccups


def list_all_hiccups(db: Session):
    rows = db.query(Hiccup).order_by(Hiccup.created_at.desc()).all()
    return with_assigned_staff_names(db, rows)


def list_all_hiccups_paginated(
    db: Session,
    *,
    page: int,
    page_size: int,
    status: Optional[str] = None,
    hiccup_type: Optional[str] = None,
    root_cause_category: Optional[str] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    escalated_only: bool = False,
    overdue_only: bool = False,
    search: Optional[str] = None,
):
    query = db.query(Hiccup)
    query = _apply_common_hiccup_filters(
        query,
        status=status,
        hiccup_type=hiccup_type,
        root_cause_category=root_cause_category,
        date_from=date_from,
        date_to=date_to,
        escalated_only=escalated_only,
        overdue_only=overdue_only,
        search=search,
    )
    return _paginate_hiccup_query(query, db, page, page_size)


def _can_view_nc_form(hiccup: Hiccup, user) -> bool:
    if _has_management_access(getattr(user, "designation", None), getattr(user, "role", None)):
        return True
    if hiccup.nc_assigned_staff_id and str(hiccup.nc_assigned_staff_id) == str(user.user_id):
        return True
    if hiccup.raised_against and str(hiccup.raised_against) == str(user.user_id):
        return True
    if hiccup.raised_by and str(hiccup.raised_by) == str(user.user_id):
        if hiccup.status in {"Escalated to NC", "Closed"}:
            return True
    return False


def _can_edit_nc_form(hiccup: Hiccup, user) -> bool:
    if _has_management_access(getattr(user, "designation", None), getattr(user, "role", None)):
        return True
    if hiccup.nc_assigned_staff_id and str(hiccup.nc_assigned_staff_id) == str(user.user_id):
        return True
    return False


def require_nc_access(db: Session, user, hiccup_id: str) -> Hiccup:
    hiccup = get_hiccup(db, hiccup_id)
    if _can_view_nc_form(hiccup, user):
        return hiccup
    raise HTTPException(status_code=403, detail="Not authorized for NC form")


def respond(db: Session, user, hiccup_id: str, response_text: str, allow_public: bool = False) -> Hiccup:
    hiccup = get_hiccup(db, hiccup_id)
    if hiccup.response_blocked:
        raise HTTPException(
            status_code=403,
            detail="Response window closed after 72 hours; management will escalate to NC.",
        )
    if not allow_public:
        if not _has_management_access(getattr(user, "designation", None), getattr(user, "role", None)):
            if not hiccup.raised_against or str(hiccup.raised_against) != str(user.user_id):
                raise HTTPException(
                    status_code=403, detail="Only assigned staff or management can respond"
                )
    hiccup.response_by = user.user_id
    hiccup.response_by_name = user.name
    hiccup.response_text = response_text
    hiccup.status = "Responded"
    hiccup.is_response_overdue = False
    hiccup.is_closure_overdue = False
    log_action(db, hiccup_id, "Responded", user.user_id)
    db.commit()
    db.refresh(hiccup)
    return hiccup


def update_status(
    db: Session,
    user,
    hiccup_id: str,
    status: str,
    closure_notes=None,
    root_cause=None,
    corrective_action=None,
    root_cause_category=None,
    response_text=None,
    escalation_form: Optional[Dict] = None,
):
    if status not in ALLOWED_STATUSES:
        raise HTTPException(status_code=400, detail="Invalid status")
    hiccup = get_hiccup(db, hiccup_id)
    hiccup.status = status
    hiccup.is_response_overdue = False
    hiccup.is_closure_overdue = False
    if status == "Responded":
        hiccup.response_by = user.user_id
        if response_text:
            hiccup.response_text = response_text
        hiccup.response_by_name = user.name
    if status == "Closed":
        is_mgmt_user = _is_management_user(user)
        if not closure_notes and not is_mgmt_user:
            raise HTTPException(status_code=400, detail="Closure notes required")
        hiccup.closure_notes = closure_notes or hiccup.closure_notes or ""
        hiccup.closed_at = now_local()
    if status == "Escalated to NC":
        if root_cause is not None:
            hiccup.root_cause = root_cause
        if corrective_action is not None:
            hiccup.corrective_action = corrective_action
        hiccup.escalated_by = user.user_id
        hiccup.closed_at = now_local()
        if escalation_form:
            _upsert_escalation_form(db, hiccup_id, escalation_form)
        hiccup.nc_assigned_staff_id = _parse_int(escalation_form.get("staff_id") if escalation_form else None)
    elif status != "Closed":
        hiccup.nc_assigned_staff_id = None
    if root_cause_category:
        hiccup.root_cause_category = root_cause_category
    log_action(db, hiccup_id, "StatusChanged", user.user_id, remarks=status)
    db.commit()
    db.refresh(hiccup)
    if status == "Escalated to NC" and hiccup.nc_assigned_staff_id:
        try:
            from app.services.notification_service import enqueue_nc_assignment_notice

            enqueue_nc_assignment_notice(hiccup.hiccup_id)
        except Exception as exc:  # pragma: no cover
            logger.exception("Failed to send NC assignment notice: %s", exc)
    return hiccup


def update_followup(
    db: Session,
    user,
    hiccup_id: str,
    followup_status: str,
    followup_comment: Optional[str],
):
    hiccup = get_hiccup(db, hiccup_id)
    if hiccup.raised_by != user.user_id:
        raise HTTPException(status_code=403, detail="Only raiser can submit follow-up")
    hiccup.followup_status = followup_status
    hiccup.followup_comment = followup_comment
    log_action(db, hiccup_id, "Updated", user.user_id, remarks="Follow-up")
    db.commit()
    db.refresh(hiccup)
    return hiccup


def get_audit_log(db: Session, hiccup_id: str):
    get_hiccup(db, hiccup_id)
    rows = (
        db.query(
            HiccupAuditLog.action,
            HiccupAuditLog.performed_by,
            HiccupAuditLog.timestamp,
            HiccupAuditLog.remarks,
            Staff.name.label("performed_by_name"),
        )
        .outerjoin(Staff, Staff.id == HiccupAuditLog.performed_by)
        .filter(HiccupAuditLog.hiccup_id == hiccup_id)
        .order_by(HiccupAuditLog.timestamp.asc())
        .all()
    )
    return [
        {
            "action": action,
            "performed_by": performed_by,
            "performed_by_name": performed_by_name,
            "timestamp": timestamp,
            "remarks": remarks,
        }
        for action, performed_by, timestamp, remarks, performed_by_name in rows
    ]


def mark_overdue_flags(db: Session):
    now_local_naive = now_local().replace(tzinfo=None)
    overdue_cutoff = now_local_naive - timedelta(
        minutes=settings.response_overdue_minutes
    )
    escalate_cutoff = now_local_naive - timedelta(
        minutes=settings.response_escalate_minutes
    )
    closure_cutoff = now_local_naive - timedelta(hours=72)

    db.query(Hiccup).filter(Hiccup.status == "Open").update(
        {Hiccup.is_closure_overdue: False}, synchronize_session=False
    )
    db.query(Hiccup).filter(
        Hiccup.status == "Open", Hiccup.created_at <= overdue_cutoff
    ).update(
        {
            Hiccup.is_response_overdue: True,
            Hiccup.was_response_overdue: True,
        },
        synchronize_session=False,
    )
    db.query(Hiccup).filter(
        Hiccup.status == "Open", Hiccup.created_at > overdue_cutoff
    ).update(
        {Hiccup.is_response_overdue: False}, synchronize_session=False
    )
    db.query(Hiccup).filter(
        Hiccup.status == "Open", Hiccup.created_at <= escalate_cutoff
    ).update(
        {Hiccup.response_blocked: True}, synchronize_session=False
    )
    db.query(Hiccup).filter(
        Hiccup.status == "Open", Hiccup.created_at > escalate_cutoff
    ).update(
        {Hiccup.response_blocked: False}, synchronize_session=False
    )

    db.query(Hiccup).filter(Hiccup.status == "Responded").update(
        {
            Hiccup.is_response_overdue: False,
            Hiccup.response_blocked: False,
        },
        synchronize_session=False,
    )
    db.query(Hiccup).filter(
        Hiccup.status == "Responded",
        Hiccup.updated_at.isnot(None),
        Hiccup.updated_at <= closure_cutoff,
    ).update(
        {Hiccup.is_closure_overdue: True}, synchronize_session=False
    )
    db.query(Hiccup).filter(
        Hiccup.status == "Responded",
        or_(Hiccup.updated_at.is_(None), Hiccup.updated_at > closure_cutoff),
    ).update(
        {Hiccup.is_closure_overdue: False}, synchronize_session=False
    )

    db.query(Hiccup).filter(Hiccup.status.notin_(["Open", "Responded"])).update(
        {
            Hiccup.is_response_overdue: False,
            Hiccup.is_closure_overdue: False,
            Hiccup.response_blocked: False,
        },
        synchronize_session=False,
    )


def trend_alerts(db: Session) -> List[dict]:
    window_start = now_local() - timedelta(days=7)
    rows = (
        db.query(
            Hiccup.raised_against,
            Hiccup.raised_against_name,
            func.count(Hiccup.hiccup_id),
        )
        .filter(Hiccup.created_at >= window_start)
        .group_by(Hiccup.raised_against, Hiccup.raised_against_name)
        .having(func.count(Hiccup.hiccup_id) >= 3)
        .order_by(func.count(Hiccup.hiccup_id).desc())
        .all()
    )
    alerts = []
    for target, name, count in rows:
        label = format_target_label(name, target)
        alerts.append(
            {
                "id": target,
                "name": name,
                "label": label,
                "count": count,
            }
        )
    return alerts


def low_reporters(db: Session) -> List[str]:
    window_start = now_local() - timedelta(days=30)
    staff_ids_with_hiccups = {
        rid
        for rid, in db.query(Hiccup.raised_by)
        .filter(Hiccup.created_at >= window_start)
        .distinct()
    }
    all_staff = db.query(Staff).all()
    return [s.name for s in all_staff if s.id not in staff_ids_with_hiccups]

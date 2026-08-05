import logging
import json
import os
import re
import uuid
from datetime import date
from types import SimpleNamespace

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Request, UploadFile, status
from fastapi.responses import HTMLResponse
from fastapi.responses import RedirectResponse
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.security import get_current_user, is_allowlisted_hiccup_admin
from app.core.templating import CompatJinja2Templates
from app.db.session import SessionLocal
from app.models.grievance import EmployeeGrievance
from app.models.staff import Staff


logger = logging.getLogger(__name__)
router = APIRouter(tags=["grievance"])
templates = CompatJinja2Templates(directory="app/templates")

GRIEVANCE_CATEGORIES = [
    "Salary Related",
    "Attendance & Leave",
    "Work Related",
    "TL, Manager, Colleagues, Supervisor",
    "Other Staff Related",
    "Harassment, Discrimination",
    "Office Conditions",
    "Policy & Compliance",
    "Other Issue",
]
STAFF_REQUIRED_CATEGORIES = {
    "TL, Manager, Colleagues, Supervisor",
    "Other Staff Related",
    "Harassment, Discrimination",
}

ALLOWED_ATTACHMENT_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf", ".doc", ".docx"}
MAX_ATTACHMENT_BYTES = 10 * 1024 * 1024
GRIEVANCE_UPLOAD_DIR = os.path.join("uploads", "grievances")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _build_current_user_context(db: Session, token_user) -> SimpleNamespace:
    staff = db.query(Staff).filter(Staff.id == token_user.user_id).first()
    return SimpleNamespace(
        id=token_user.user_id,
        user_id=token_user.user_id,
        name=(staff.name if staff and staff.name else token_user.name),
        employee_id=token_user.user_id,
        department=(staff.departments if staff and staff.departments else "-"),
        designation=(staff.designation if staff and staff.designation else token_user.designation or "-"),
        role=token_user.role,
        department_id=token_user.department_id,
        is_admin_like=getattr(token_user, "is_admin_like", False),
        is_infra_admin=getattr(token_user, "is_infra_admin", False),
    )


def _list_active_employees(db: Session, current_user_id: int) -> list[Staff]:
    return (
        db.query(Staff)
        .filter(Staff.status == "Active", Staff.id != current_user_id)
        .order_by(Staff.name.asc())
        .all()
    )


def _attachment_error(file: UploadFile | None) -> str | None:
    if not file or not file.filename:
        return None

    filename = file.filename.strip()
    extension = "." + filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    if extension not in ALLOWED_ATTACHMENT_EXTENSIONS:
        return "Attachment must be a JPG, PNG, PDF, DOC, or DOCX file."

    file.file.seek(0, 2)
    size = file.file.tell()
    file.file.seek(0)
    if size > MAX_ATTACHMENT_BYTES:
        return "Attachment size must be 10 MB or less."
    return None


def _safe_filename(filename: str) -> str:
    name = os.path.basename(filename or "").strip()
    name = re.sub(r"[^A-Za-z0-9._-]+", "_", name)
    return name or "attachment"


def _save_evidence(file: UploadFile | None) -> str | None:
    if not file or not file.filename:
        return None
    os.makedirs(GRIEVANCE_UPLOAD_DIR, exist_ok=True)
    safe_name = _safe_filename(file.filename)
    stored_name = f"{uuid.uuid4().hex}_{safe_name}"
    disk_path = os.path.join(GRIEVANCE_UPLOAD_DIR, stored_name)
    file.file.seek(0)
    with open(disk_path, "wb") as output:
        output.write(file.file.read())
    return "/" + disk_path.replace("\\", "/")


def _parse_incident_date(value: str | None) -> date | None:
    cleaned = (value or "").strip()
    if not cleaned:
        return None
    try:
        return date.fromisoformat(cleaned)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid incident date") from exc


def _validate_grievance_payload(
    category: str,
    staff_ids: list[str] | None,
    description: str,
    incident_date: str | None,
    expected_resolution: str,
    evidence: UploadFile | None,
) -> dict[str, str]:
    errors: dict[str, str] = {}
    cleaned_category = (category or "").strip()
    cleaned_description = (description or "").strip()
    cleaned_resolution = (expected_resolution or "").strip()

    if cleaned_category not in GRIEVANCE_CATEGORIES:
        errors["category"] = "Please select a valid grievance category."
    if not cleaned_description:
        errors["description"] = "Please enter grievance description."
    if not cleaned_resolution:
        errors["expected_resolution"] = "Please enter expected resolution."
    selected_staff_ids = [sid for sid in (staff_ids or []) if str(sid).strip()]
    if cleaned_category in STAFF_REQUIRED_CATEGORIES and not selected_staff_ids:
        errors["staff_ids"] = "Please select at least one staff member involved."
    if incident_date:
        try:
            date.fromisoformat(incident_date)
        except ValueError:
            errors["incident_date"] = "Please select a valid incident date."

    attachment_message = _attachment_error(evidence)
    if attachment_message:
        errors["evidence"] = attachment_message
    return errors


@router.get("/grievance", response_class=HTMLResponse)
async def grievance_form(
    request: Request,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    current_user = _build_current_user_context(db, user)
    employees = _list_active_employees(db, user.user_id)
    return templates.TemplateResponse(
        "grievance_form.html",
        {
            "request": request,
            "title": "Employee Grievance Form",
            "user": current_user,
            "current_user": current_user,
            "employees": employees,
            "categories": GRIEVANCE_CATEGORIES,
            "errors": {},
            "form": {},
            "success_message": None,
        },
    )


def _can_view_all_grievances(user) -> bool:
    return is_allowlisted_hiccup_admin(getattr(user, "user_id", None))


def _decode_json_list(value: str | None) -> list[str]:
    if not value:
        return []
    try:
        decoded = json.loads(value)
        if isinstance(decoded, list):
            return [str(item) for item in decoded if str(item).strip()]
    except (TypeError, json.JSONDecodeError):
        pass
    return [value] if str(value).strip() else []


def _serialize_grievance(row: EmployeeGrievance) -> dict:
    return {
        "grievance_id": row.grievance_id,
        "employee_id": row.employee_id,
        "employee_name": row.employee_name,
        "department": row.department or "-",
        "designation": row.designation or "-",
        "category": row.category,
        "staff_ids": _decode_json_list(row.staff_ids),
        "staff_names": _decode_json_list(row.staff_names),
        "description": row.description,
        "incident_date": row.incident_date,
        "incident_time": row.incident_time,
        "evidence_path": row.evidence_path,
        "expected_resolution": row.expected_resolution,
        "created_at": row.created_at,
        "updated_at": row.updated_at,
    }


@router.get("/grievances", response_class=HTMLResponse)
async def all_grievances_page(
    request: Request,
    category: str = Query(""),
    date_from: str = Query(""),
    date_to: str = Query(""),
    search: str = Query(""),
    page: int = Query(1),
    page_size: int = Query(50),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    if not _can_view_all_grievances(user):
        return RedirectResponse(url="/home")

    safe_page = max(page, 1)
    safe_page_size = page_size if page_size in {50, 100, 200} else 50
    query = db.query(EmployeeGrievance)

    if category:
        query = query.filter(EmployeeGrievance.category == category)
    if date_from:
        query = query.filter(EmployeeGrievance.created_at >= f"{date_from} 00:00:00")
    if date_to:
        query = query.filter(EmployeeGrievance.created_at <= f"{date_to} 23:59:59")
    if search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                EmployeeGrievance.employee_name.ilike(term),
                EmployeeGrievance.category.ilike(term),
                EmployeeGrievance.staff_names.ilike(term),
                EmployeeGrievance.description.ilike(term),
                EmployeeGrievance.expected_resolution.ilike(term),
            )
        )

    total = query.count()
    total_pages = max((total + safe_page_size - 1) // safe_page_size, 1)
    if safe_page > total_pages:
        safe_page = total_pages
    rows = (
        query.order_by(EmployeeGrievance.created_at.desc(), EmployeeGrievance.grievance_id.desc())
        .offset((safe_page - 1) * safe_page_size)
        .limit(safe_page_size)
        .all()
    )

    return templates.TemplateResponse(
        "all_grievances.html",
        {
            "request": request,
            "title": "All Grievances",
            "user": user,
            "is_admin_like": True,
            "categories": GRIEVANCE_CATEGORIES,
            "grievances": [_serialize_grievance(row) for row in rows],
            "filters": {
                "category": category,
                "date_from": date_from,
                "date_to": date_to,
                "search": search,
                "page_size": safe_page_size,
            },
            "pagination": {
                "page": safe_page,
                "page_size": safe_page_size,
                "total": total,
                "total_pages": total_pages,
                "start": ((safe_page - 1) * safe_page_size + 1) if total else 0,
                "end": min(safe_page * safe_page_size, total),
            },
        },
    )


@router.post("/grievance", response_class=HTMLResponse)
async def submit_grievance(
    request: Request,
    category: str = Form(""),
    staff_ids: list[str] = Form(default=[]),
    description: str = Form(""),
    incident_date: str | None = Form(None),
    incident_time: str | None = Form(None),
    expected_resolution: str = Form(""),
    evidence: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    current_user = _build_current_user_context(db, user)
    employees = _list_active_employees(db, user.user_id)
    form = {
        "category": category,
        "staff_ids": staff_ids,
        "description": description,
        "incident_date": incident_date,
        "incident_time": incident_time,
        "expected_resolution": expected_resolution,
    }
    errors = _validate_grievance_payload(
        category=category,
        staff_ids=staff_ids,
        description=description,
        incident_date=incident_date,
        expected_resolution=expected_resolution,
        evidence=evidence,
    )

    if errors:
        return templates.TemplateResponse(
            "grievance_form.html",
            {
                "request": request,
                "title": "Employee Grievance Form",
                "user": current_user,
                "current_user": current_user,
                "employees": employees,
                "categories": GRIEVANCE_CATEGORIES,
                "errors": errors,
                "form": form,
                "success_message": None,
            },
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    selected_staff = []
    selected_staff_ids = [sid for sid in (staff_ids or []) if str(sid).strip()]
    if selected_staff_ids:
        try:
            selected_ids = [int(sid) for sid in selected_staff_ids]
            selected_staff = db.query(Staff).filter(Staff.id.in_(selected_ids)).all()
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="Invalid staff selection") from exc

    evidence_path = _save_evidence(evidence)
    selected_staff_names = [staff.name for staff in selected_staff]
    grievance = EmployeeGrievance(
        employee_id=current_user.employee_id,
        employee_name=current_user.name,
        department=current_user.department,
        designation=current_user.designation,
        category=category.strip(),
        staff_ids=json.dumps(selected_staff_ids),
        staff_names=json.dumps(selected_staff_names),
        description=description.strip(),
        incident_date=_parse_incident_date(incident_date),
        incident_time=(incident_time or "").strip() or None,
        evidence_path=evidence_path,
        expected_resolution=expected_resolution.strip(),
    )
    db.add(grievance)
    db.commit()
    db.refresh(grievance)

    submitted_data = {
        "grievance_id": grievance.grievance_id,
        "employee_id": current_user.employee_id,
        "employee_name": current_user.name,
        "department": current_user.department,
        "designation": current_user.designation,
        "category": category.strip(),
        "staff_ids": selected_staff_ids,
        "staff_names": selected_staff_names,
        "description": description.strip(),
        "incident_date": incident_date,
        "incident_time": incident_time,
        "evidence_path": evidence_path,
        "expected_resolution": expected_resolution.strip(),
    }
    logger.info("Employee grievance submitted: %s", submitted_data)
    print("Employee grievance submitted:", submitted_data)

    return templates.TemplateResponse(
        "grievance_form.html",
        {
            "request": request,
            "title": "Employee Grievance Form",
            "user": current_user,
            "current_user": current_user,
            "employees": employees,
            "categories": GRIEVANCE_CATEGORIES,
            "errors": {},
            "form": {},
            "success_message": "Your grievance has been submitted successfully.",
        },
    )

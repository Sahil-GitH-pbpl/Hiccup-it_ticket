from datetime import date

from fastapi import APIRouter, Depends, File, Form, UploadFile, HTTPException, Query, Request
from sqlalchemy.orm import Session
from typing import List

from app.core.security import (
    get_current_user,
    require_management,
    TokenData,
    decode_public_token,
    is_allowlisted_hiccup_admin,
)
from app.db.session import SessionLocal
from app.schemas.hiccup import (
    HiccupCreate,
    HiccupListResponse,
    HiccupResponse,
    NCEscalationFormPayload,
    NCEscalationFormResponse,
    RespondRequest,
    StatusUpdateRequest,
    FollowupRequest,
    AuditLogEntry,
)
from app.services import hiccup_service
from app.services.notification_service import enqueue_creation_notification
from app.models.staff import Staff

router = APIRouter(prefix="/api/hiccups", tags=["hiccups"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("", response_model=HiccupResponse)
def create_hiccup(
    hiccup_type: str = Form(...),
    raised_against: str = Form(None),
    raised_against_name: str = Form(None),
    raised_against_department: int = Form(None),
    raised_against_department_name: str = Form(None),
    description: str = Form(...),
    immediate_effect: str = Form(None),
    confidential_flag: bool = Form(False),
    root_cause_category: str = Form(None),
    attachments: List[UploadFile] = File(None),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    data = HiccupCreate(
        hiccup_type=hiccup_type,
        raised_against=raised_against,
        raised_against_name=raised_against_name,
        raised_against_department=raised_against_department,
        raised_against_department_name=raised_against_department_name,
        description=description,
        immediate_effect=immediate_effect,
        confidential_flag=confidential_flag,
        root_cause_category=root_cause_category,
    )
    hiccup = hiccup_service.create_hiccup(db, user, data, attachments or [])
    enqueue_creation_notification(hiccup.hiccup_id)
    return hiccup


@router.get("", response_model=HiccupListResponse)
def list_hiccups(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    status: str | None = Query(None),
    hiccup_type: str | None = Query(None),
    date_from: date | None = Query(None),
    date_to: date | None = Query(None),
    escalated: bool = Query(False),
    overdue: bool = Query(False),
    search: str | None = Query(None),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return hiccup_service.list_hiccups_for_user_paginated(
        db,
        user,
        page=page,
        page_size=page_size,
        status=status,
        hiccup_type=hiccup_type,
        date_from=date_from,
        date_to=date_to,
        escalated_only=escalated,
        overdue_only=overdue,
        search=search,
    )


@router.get("/assigned", response_model=HiccupListResponse)
def list_assigned_hiccups(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    status: str | None = Query(None),
    hiccup_type: str | None = Query(None),
    root_cause_category: str | None = Query(None),
    date_from: date | None = Query(None),
    date_to: date | None = Query(None),
    escalated: bool = Query(False),
    overdue: bool = Query(False),
    search: str | None = Query(None),
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return hiccup_service.list_assigned_hiccups_paginated(
        db,
        user,
        page=page,
        page_size=page_size,
        status=status,
        hiccup_type=hiccup_type,
        root_cause_category=root_cause_category,
        date_from=date_from,
        date_to=date_to,
        escalated_only=escalated,
        overdue_only=overdue,
        search=search,
    )


@router.get("/all", response_model=HiccupListResponse)
def list_all_hiccups(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    status: str | None = Query(None),
    hiccup_type: str | None = Query(None),
    root_cause_category: str | None = Query(None),
    date_from: date | None = Query(None),
    date_to: date | None = Query(None),
    escalated: bool = Query(False),
    overdue: bool = Query(False),
    search: str | None = Query(None),
    db: Session = Depends(get_db),
    user=Depends(require_management),
):
    return hiccup_service.list_all_hiccups_paginated(
        db,
        page=page,
        page_size=page_size,
        status=status,
        hiccup_type=hiccup_type,
        root_cause_category=root_cause_category,
        date_from=date_from,
        date_to=date_to,
        escalated_only=escalated,
        overdue_only=overdue,
        search=search,
    )


@router.get("/{hiccup_id}", response_model=HiccupResponse)
def get_hiccup(
    hiccup_id: str, db: Session = Depends(get_db), user=Depends(get_current_user)
):
    hiccup = hiccup_service.get_hiccup(db, hiccup_id)
    if (
        hiccup.confidential_flag
        and user.role == "staff"
        and hiccup.raised_by != user.user_id
    ):
        raise HTTPException(status_code=403, detail="Confidential")
    return hiccup


@router.patch("/{hiccup_id}/respond", response_model=HiccupResponse)
def respond(
    hiccup_id: str,
    payload: RespondRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return hiccup_service.respond(db, user, hiccup_id, payload.response_text)


@router.patch("/public/{hiccup_id}/respond", response_model=HiccupResponse)
def public_respond(
    hiccup_id: str,
    payload: RespondRequest,
    public_token: str = Query(None),
    request: Request = None,
    db: Session = Depends(get_db),
):
    token_value = payload.public_token or public_token
    if not token_value and request:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token_value = auth_header.removeprefix("Bearer ").strip()
    if not token_value:
        raise HTTPException(status_code=422, detail="public_token required")
    token_data = decode_public_token(token_value, purpose="response_link")
    if token_data.get("hiccup_id") != hiccup_id:
        raise HTTPException(status_code=403, detail="Token mismatch")
    hiccup = hiccup_service.get_hiccup(db, hiccup_id)
    if hiccup.response_text:
        raise HTTPException(status_code=400, detail="Response already submitted")
    if not token_data.get("user_id"):
        raise HTTPException(status_code=422, detail="public token missing user")
    dept_id = token_data.get("department_id")
    resolved_name = token_data.get("name") or "External"
    if not token_data.get("name") and token_data.get("user_id"):
        staff = db.query(Staff).filter(Staff.id == token_data["user_id"]).first()
        if staff:
            resolved_name = staff.name or resolved_name
            if not dept_id:
                dept_id = staff.department_id
    user = TokenData(
        user_id=int(token_data["user_id"]),
        role=token_data.get("role", "external"),
        department_id=dept_id,
        name=resolved_name,
    )
    return hiccup_service.respond(db, user, hiccup_id, payload.response_text, allow_public=True)


@router.patch("/{hiccup_id}/status", response_model=HiccupResponse)
def update_status(
    hiccup_id: str,
    payload: StatusUpdateRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    hiccup = hiccup_service.get_hiccup(db, hiccup_id)
    is_mgmt = is_allowlisted_hiccup_admin(getattr(user, "user_id", None)) or str(
        getattr(user, "role", "")
    ).lower() in {"admin", "management"} or getattr(user, "is_admin_like", False)
    is_assigned_nc = (
        hiccup.status == "Escalated to NC"
        and hiccup.nc_assigned_staff_id
        and str(hiccup.nc_assigned_staff_id) == str(user.user_id)
    )
    if not is_mgmt:
        if not (payload.status == "Closed" and is_assigned_nc):
            raise HTTPException(status_code=403, detail="Management designation required")
    return hiccup_service.update_status(
        db,
        user,
        hiccup_id,
        payload.status,
        closure_notes=payload.closure_notes,
        root_cause=payload.root_cause,
        corrective_action=payload.corrective_action,
        root_cause_category=payload.root_cause_category,
        response_text=payload.response_text,
        escalation_form=payload.escalation_form.dict(exclude_none=True)
        if payload.escalation_form
        else None,
    )


@router.get("/{hiccup_id}/nc-form", response_model=NCEscalationFormResponse)
def get_nc_form(
    hiccup_id: str,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    hiccup_service.require_nc_access(db, user, hiccup_id)
    return hiccup_service.get_nc_escalation_form(db, hiccup_id)


@router.patch("/{hiccup_id}/nc-form", response_model=NCEscalationFormResponse)
def update_nc_form(
    hiccup_id: str,
    payload: NCEscalationFormPayload,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    hiccup = hiccup_service.require_nc_access(db, user, hiccup_id)
    if not hiccup_service._can_edit_nc_form(hiccup, user):  # type: ignore
        raise HTTPException(status_code=403, detail="Not authorized to edit NC form")
    return hiccup_service.update_nc_escalation_form(
        db, user, hiccup_id, payload.dict(exclude_none=True)
    )


@router.patch("/{hiccup_id}/followup", response_model=HiccupResponse)
def followup(
    hiccup_id: str,
    payload: FollowupRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    return hiccup_service.update_followup(
        db, user, hiccup_id, payload.followup_status, payload.followup_comment
    )


@router.get("/{hiccup_id}/audit_log", response_model=List[AuditLogEntry])
def audit_log(
    hiccup_id: str, db: Session = Depends(get_db), user=Depends(get_current_user)
):
    return hiccup_service.get_audit_log(db, hiccup_id)

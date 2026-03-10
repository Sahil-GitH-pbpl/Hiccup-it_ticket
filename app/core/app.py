import logging
import os
from fastapi import FastAPI, Request, Depends, HTTPException, Query, status, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.sessions import SessionMiddleware
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from fastapi.exception_handlers import http_exception_handler

from app.core.logging_config import configure_logging
from app.db.session import SessionLocal, engine
from app.db.base import Base
from sqlalchemy import case, func, inspect, text
from sqlalchemy.exc import NoSuchTableError
from app.api import (
    routes_auth,
    routes_dashboard,
    routes_hiccups,
    routes_infra,
    routes_internal,
    routes_staff,
)
from app.core.scheduler import start_scheduler
from app.core.security import (
    get_current_user,
    decode_jwt,
    decode_public_token,
    is_allowlisted_hiccup_admin,
)
from app.core.config import get_settings
from urllib.parse import quote_plus
import json
from app.models.hiccup import Hiccup
from app.models.infra import InfraTicket
from app.models.staff import Staff
from app.schemas.hiccup import HiccupResponse

import app.models  # ensure all models register before metadata creation

configure_logging()

# Optional: skip automatic schema bootstrap unless explicitly enabled.
_schema_bootstrap_enabled = os.getenv("ENABLE_SCHEMA_BOOTSTRAP", "0") == "1"

if _schema_bootstrap_enabled:
    Base.metadata.create_all(bind=engine)


def _ensure_name_columns(engine):
    inspector = inspect(engine)
    columns = {col["name"] for col in inspector.get_columns("hiccups")}
    statements = []
    if "raised_by_name" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN raised_by_name VARCHAR(150) NOT NULL DEFAULT ''"
        )
    if "raised_against_name" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN raised_against_name VARCHAR(150)"
        )
    if "response_by_name" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN response_by_name VARCHAR(150)"
        )
    if "raised_against_department_name" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN raised_against_department_name VARCHAR(150)"
        )
    if "response_blocked" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN response_blocked TINYINT(1) NOT NULL DEFAULT 0"
        )
    if "was_response_overdue" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN was_response_overdue TINYINT(1) NOT NULL DEFAULT 0"
        )
    if "reminder_sent" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN reminder_sent TINYINT(1) NOT NULL DEFAULT 0"
        )
    if "overdue_msg_sent" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN overdue_msg_sent TINYINT(1) NOT NULL DEFAULT 0"
        )
    if "escalate_msg_sent" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN escalate_msg_sent TINYINT(1) NOT NULL DEFAULT 0"
        )
    if "raised_against_department_name" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN raised_against_department_name VARCHAR(150)"
        )
    if "nc_assigned_staff_id" not in columns:
        statements.append(
            "ALTER TABLE hiccups ADD COLUMN nc_assigned_staff_id INTEGER"
        )
    if statements:
        with engine.begin() as conn:
            for stmt in statements:
                conn.execute(text(stmt))


def _ensure_nc_escalation_columns(engine):
    inspector = inspect(engine)
    try:
        columns = {col["name"] for col in inspector.get_columns("nc_escalation_forms")}
    except NoSuchTableError:
        return
    statements = []
    if "root_cause_other" not in columns:
        statements.append("ALTER TABLE nc_escalation_forms ADD COLUMN root_cause_other TEXT")
    if "preventive_other" not in columns:
        statements.append("ALTER TABLE nc_escalation_forms ADD COLUMN preventive_other TEXT")
    if "assigned_staff_id" not in columns:
        statements.append("ALTER TABLE nc_escalation_forms ADD COLUMN assigned_staff_id INTEGER")
    if statements:
        with engine.begin() as conn:
            for stmt in statements:
                conn.execute(text(stmt))


if _schema_bootstrap_enabled:
    _ensure_name_columns(engine)
    _ensure_nc_escalation_columns(engine)
def _ensure_user_columns(engine):
    inspector = inspect(engine)
    try:
        columns = {col["name"] for col in inspector.get_columns("users")}
    except NoSuchTableError:
        return
    statements = []
    if "department_id" not in columns:
        statements.append("ALTER TABLE users ADD COLUMN department_id INTEGER NULL")
    if statements:
        with engine.begin() as conn:
            for stmt in statements:
                conn.execute(text(stmt))

if _schema_bootstrap_enabled:
    _ensure_user_columns(engine)


def _ensure_infra_ticket_autoincrement(engine):
    inspector = inspect(engine)
    try:
        cols = inspector.get_columns("infra_tickets")
    except NoSuchTableError:
        return
    ticket_col = next((c for c in cols if c.get("name") == "ticket_id"), None)
    if not ticket_col:
        return
    is_auto = str(ticket_col.get("autoincrement", "")).lower() in {"true", "auto"}
    if is_auto:
        return
    # For MySQL/MariaDB: enforce auto increment on ticket_id
    with engine.begin() as conn:
        conn.execute(
            text(
                "ALTER TABLE infra_tickets MODIFY COLUMN ticket_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY"
            )
        )


if _schema_bootstrap_enabled:
    _ensure_infra_ticket_autoincrement(engine)


def _ensure_infra_ticket_images_autoincrement(engine):
    inspector = inspect(engine)
    try:
        cols = inspector.get_columns("infra_ticket_images")
    except NoSuchTableError:
        return
    img_col = next((c for c in cols if c.get("name") == "image_id"), None)
    if not img_col:
        return
    is_auto = str(img_col.get("autoincrement", "")).lower() in {"true", "auto"}
    if is_auto:
        return
    with engine.begin() as conn:
        conn.execute(
            text(
                "ALTER TABLE infra_ticket_images MODIFY COLUMN image_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY"
            )
        )


if _schema_bootstrap_enabled:
    _ensure_infra_ticket_images_autoincrement(engine)


def _ensure_infra_updates_autoincrement(engine):      
    inspector = inspect(engine)
    try:
        cols = inspector.get_columns("infra_updates")
    except NoSuchTableError:
        return
    upd_col = next((c for c in cols if c.get("name") == "update_id"), None)
    if not upd_col:
        return
    is_auto = str(upd_col.get("autoincrement", "")).lower() in {"true", "auto"}
    if is_auto:
        return
    with engine.begin() as conn:
        conn.execute(
            text(
                "ALTER TABLE infra_updates MODIFY COLUMN update_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY"
            )
        )


if _schema_bootstrap_enabled:
    _ensure_infra_updates_autoincrement(engine)


def _ensure_infra_indexes(engine):
    inspector = inspect(engine)
    try:
        existing = {idx["name"] for idx in inspector.get_indexes("infra_tickets")}
    except NoSuchTableError:
        return

    statements = {
        "idx_infra_tickets_status_created": "CREATE INDEX idx_infra_tickets_status_created ON infra_tickets (status, created_at)",
        "idx_infra_tickets_created_by": "CREATE INDEX idx_infra_tickets_created_by ON infra_tickets (created_by)",
        "idx_infra_tickets_assigned_to": "CREATE INDEX idx_infra_tickets_assigned_to ON infra_tickets (assigned_to)",
        "idx_infra_tickets_department": "CREATE INDEX idx_infra_tickets_department ON infra_tickets (department)",
        "idx_infra_tickets_category": "CREATE INDEX idx_infra_tickets_category ON infra_tickets (category)",
        "idx_infra_tickets_delayed": "CREATE INDEX idx_infra_tickets_delayed ON infra_tickets (is_delayed_pick)",
    }
    with engine.begin() as conn:
        for index_name, statement in statements.items():
            if index_name in existing:
                continue
            conn.execute(text(statement))


if _schema_bootstrap_enabled:
    _ensure_infra_indexes(engine)

settings = get_settings()


templates = Jinja2Templates(directory="app/templates")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _aggregate_hiccup_counts(query):
    row = (
        query.with_entities(
            func.count(Hiccup.hiccup_id).label("total"),
            func.coalesce(
                func.sum(case((Hiccup.status == "Open", 1), else_=0)), 0
            ).label("open"),
            func.coalesce(
                func.sum(case((Hiccup.status == "Responded", 1), else_=0)), 0
            ).label("responded"),
            func.coalesce(
                func.sum(case((Hiccup.status == "Closed", 1), else_=0)), 0
            ).label("closed"),
        )
        .one()
    )
    return {
        "total": row.total or 0,
        "open": row.open or 0,
        "responded": row.responded or 0,
        "closed": row.closed or 0,
    }


def _aggregate_infra_counts(query):
    row = (
        query.with_entities(
            func.count(InfraTicket.ticket_id).label("total"),
            func.coalesce(
                func.sum(
                    case(
                        (InfraTicket.status.notin_(["Resolved", "Rejected"]), 1),
                        else_=0,
                    )
                ),
                0,
            ).label("open"),
            func.coalesce(
                func.sum(case((InfraTicket.status == "Resolved", 1), else_=0)), 0
            ).label("resolved"),
            func.coalesce(
                func.sum(case((InfraTicket.status == "Rejected", 1), else_=0)), 0
            ).label("rejected"),
            func.coalesce(
                func.sum(case((InfraTicket.is_delayed_pick.is_(True), 1), else_=0)), 0
            ).label("delayed"),
            func.coalesce(
                func.sum(case((InfraTicket.is_invalid.is_(True), 1), else_=0)), 0
            ).label("invalid"),
        )
        .one()
    )
    return {
        "total": row.total or 0,
        "open": row.open or 0,
        "resolved": row.resolved or 0,
        "rejected": row.rejected or 0,
        "delayed": row.delayed or 0,
        "invalid": row.invalid or 0,
    }


def create_app() -> FastAPI:
    app = FastAPI(title="Hiccup Module")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(GZipMiddleware, minimum_size=512)
    app.add_middleware(SessionMiddleware, secret_key=settings.session_secret)

    app.include_router(routes_auth.router)
    app.include_router(routes_dashboard.router)
    app.include_router(routes_hiccups.router)
    app.include_router(routes_infra.router)
    app.include_router(routes_internal.router)
    app.include_router(routes_staff.router)

    @app.exception_handler(HTTPException)
    async def auth_exception_handler(request: Request, exc: HTTPException):
        if (
            exc.status_code == status.HTTP_401_UNAUTHORIZED
            and not request.url.path.startswith("/api")
        ):
            return RedirectResponse(url="/login")
        return await http_exception_handler(request, exc)

    app.mount("/static", StaticFiles(directory="app/static"), name="static")
    app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

    def _is_admin_like(user):
        if not user:
            return False
        # Hiccup admin only (not infra-only overrides)
        if getattr(user, "is_admin_like", False):
            return True
        return is_allowlisted_hiccup_admin(getattr(user, "user_id", None))

    def _can_view_all_hiccups(user):
        return _is_admin_like(user)

    def _parse_attachment_paths(raw_value):
        if not raw_value:
            return []
        if isinstance(raw_value, list):
            return [str(item) for item in raw_value if str(item).strip()]
        if isinstance(raw_value, str):
            text_value = raw_value.strip()
            if not text_value:
                return []
            try:
                parsed = json.loads(text_value)
                if isinstance(parsed, list):
                    return [str(item) for item in parsed if str(item).strip()]
            except Exception:
                pass
            return [text_value]
        return []

    def _load_venepunchre_record(db: Session, record_id: str):
        row = db.execute(
            text(
                """
                SELECT *
                FROM venepunchre_records
                WHERE hiccup_id = :record_id
                LIMIT 1
                """
            ),
            {"record_id": record_id},
        ).mappings().first()
        if not row:
            return None
        return dict(row)

    def _resolve_staff_name(db: Session, staff_id):
        try:
            if staff_id in (None, ""):
                return None
            sid = int(staff_id)
        except Exception:
            return None
        staff = db.query(Staff).filter(Staff.id == sid).first()
        return staff.name if staff and staff.name else None

    def _decorate_venipuncture_record(db: Session, record: dict):
        if not record:
            return record
        reported_staff_name = _resolve_staff_name(db, record.get("reported_staff_id"))
        if reported_staff_name:
            record["reported_staff_name"] = reported_staff_name
        venipuncture_staff_name = _resolve_staff_name(db, record.get("venepunchre_staff_id"))
        if venipuncture_staff_name:
            record["venipuncture_staff_name"] = venipuncture_staff_name
        raised_by_name = _resolve_staff_name(db, record.get("raised_by"))
        if raised_by_name:
            record["raised_by_name_resolved"] = raised_by_name
        raised_against_name = _resolve_staff_name(db, record.get("raised_against"))
        if raised_against_name:
            record["raised_against_name_resolved"] = raised_against_name
        return record

    def _has_column(db: Session, table_name: str, column_name: str) -> bool:
        try:
            cols = {col["name"] for col in inspect(db.get_bind()).get_columns(table_name)}
            return column_name in cols
        except Exception:
            return False

    def _get_columns(db: Session, table_name: str) -> set[str]:
        try:
            return {col["name"] for col in inspect(db.get_bind()).get_columns(table_name)}
        except Exception:
            return set()

    @app.get("/", response_class=HTMLResponse)
    async def root(request: Request):
        token = request.cookies.get("token")
        if token:
            try:
                decoded = decode_jwt(token)
                target = "/dashboard" if _is_admin_like(decoded) else "/home"
                return RedirectResponse(url=target)
            except HTTPException:
                pass
        return RedirectResponse(url="/login")

    @app.get("/login", response_class=HTMLResponse)
    async def login_page(request: Request):
        token = request.cookies.get("token")
        if token:
            try:
                decoded = decode_jwt(token)
                target = "/dashboard" if _is_admin_like(decoded) else "/home"
                return RedirectResponse(url=target)
            except HTTPException:
                pass
        return templates.TemplateResponse(
            "login.html", {"request": request, "title": "Login"}
        )

    @app.get("/home", response_class=HTMLResponse)
    async def home_page(
        request: Request, db: Session = Depends(get_db), user=Depends(get_current_user)
    ):
        if _is_admin_like(user):
            return RedirectResponse(url="/dashboard")
        hiccup_q = db.query(Hiccup).filter(Hiccup.raised_by == user.user_id)
        infra_q = (
            db.query(InfraTicket).filter(InfraTicket.created_by == user.name)
            if getattr(user, "name", None)
            else None
        )

        hiccup_stats = _aggregate_hiccup_counts(hiccup_q)
        infra_stats = (
            _aggregate_infra_counts(infra_q)
            if infra_q is not None
            else {
                "total": 0,
                "open": 0,
                "resolved": 0,
                "rejected": 0,
                "delayed": 0,
                "invalid": 0,
            }
        )

        hiccup_recent = hiccup_q.order_by(Hiccup.created_at.desc()).limit(5).all()
        infra_recent = (
            infra_q.order_by(InfraTicket.ticket_id.desc(), InfraTicket.created_at.desc()).limit(5).all()
            if infra_q is not None
            else []
        )

        return templates.TemplateResponse(
            "home.html",
            {
                "request": request,
                "user": user,
                "is_admin_like": _is_admin_like(user),
                "hiccup_stats": hiccup_stats,
                "infra_stats": infra_stats,
                "hiccup_recent": hiccup_recent,
                "infra_recent": infra_recent,
            },
        )

    @app.get("/dashboard", response_class=HTMLResponse)
    async def dashboard(
        request: Request, db: Session = Depends(get_db), user=Depends(get_current_user)
    ):
        if not _is_admin_like(user):
            return RedirectResponse(url="/home")
        hiccup_stats = _aggregate_hiccup_counts(db.query(Hiccup))
        infra_stats = _aggregate_infra_counts(db.query(InfraTicket))

        latest_infra = (
            db.query(InfraTicket)
            .order_by(InfraTicket.ticket_id.desc(), InfraTicket.created_at.desc())
            .limit(5)
            .all()
        )
        latest_hiccups = (
            db.query(Hiccup)
            .order_by(Hiccup.created_at.desc())
            .limit(5)
            .all()
        )

        return templates.TemplateResponse(
            "dashboard_combined.html",
            {
                "request": request,
                "user": user,
                "is_admin_like": _is_admin_like(user),
                "hiccup": hiccup_stats,
                "infra": {
                    "total": infra_stats["total"],
                    "open": infra_stats["open"],
                    "resolved": infra_stats["resolved"],
                    "delayed": infra_stats["delayed"],
                    "invalid": infra_stats["invalid"],
                },
                "latest_infra": latest_infra,
                "latest_hiccups": latest_hiccups,
            },
        )

    @app.get("/raise", response_class=HTMLResponse)
    async def raise_hiccup_page(request: Request, user=Depends(get_current_user)):
        return templates.TemplateResponse(
            "raise_hiccup.html", {"request": request, "user": user}
        )

    @app.get("/my-hiccups", response_class=HTMLResponse)
    async def my_hiccups_page(request: Request, user=Depends(get_current_user)):
        return templates.TemplateResponse(
            "list_hiccups.html", {"request": request, "user": user}
        )

    @app.get("/response-submit", response_class=HTMLResponse)
    async def response_submit_page(request: Request, user=Depends(get_current_user)):
        return templates.TemplateResponse(
            "response_submit.html", {"request": request, "user": user}
        )

    @app.get("/assigned", response_class=HTMLResponse)
    async def assigned_page(request: Request, user=Depends(get_current_user)):
        return templates.TemplateResponse(
            "assigned_hiccups.html", {"request": request, "user": user}
        )

    @app.get("/management", response_class=HTMLResponse)
    async def management_page(request: Request, user=Depends(get_current_user)):
        if not _can_view_all_hiccups(user):
            return RedirectResponse(url="/home")
        return templates.TemplateResponse(
            "management_hiccups.html", {"request": request, "user": user, "is_admin_like": _is_admin_like(user)}
        )

    @app.get("/hiccups/{hiccup_id}", response_class=HTMLResponse)
    async def hiccup_detail_page(
        hiccup_id: str, request: Request, user=Depends(get_current_user)
    ):
        return templates.TemplateResponse(
            "hiccup_detail.html",
            {
                "request": request,
                "hiccup_id": hiccup_id,
                "user": user,
                "public_token": "",
            },
        )

    @app.get("/public/hiccups/{hiccup_id}", response_class=HTMLResponse)
    async def public_hiccup_detail(
        hiccup_id: str,
        request: Request,
        public_token: str = Query(...),
        db: Session = Depends(get_db),
    ):
        try:
            payload = decode_public_token(public_token, purpose="response_link")
            if payload.get("hiccup_id") != hiccup_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN, detail="Token mismatch"
                )
            hiccup = db.query(Hiccup).filter(Hiccup.hiccup_id == hiccup_id).first()
            if not hiccup:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND, detail="Hiccup not found"
                )
            hiccup_data = json.loads(HiccupResponse.from_orm(hiccup).json())
            return templates.TemplateResponse(
                "hiccup_detail.html",
                {
                    "request": request,
                    "hiccup_id": hiccup_id,
                    "public_token": public_token,
                    "hiccup_data": hiccup_data,
                    "hiccup_attachments": hiccup.attachments if hiccup else [],
                },
            )
        except HTTPException:
            raise
        except Exception as err:
            logging.getLogger(__name__).exception("public hiccup detail failed")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to load hiccup details",
            ) from err

    @app.get("/venepunchere/{record_id}/{token}", response_class=HTMLResponse)
    @app.get("/Venepunchere/{record_id}/{token}", response_class=HTMLResponse)
    async def venepunchere_response_form(
        record_id: str,
        token: str,
        request: Request,
        db: Session = Depends(get_db),
    ):
        payload = decode_public_token(token, purpose="response_link")
        token_record_id = payload.get("hiccup_id")
        if token_record_id and token_record_id != record_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="Token mismatch"
            )
        record = _load_venepunchre_record(db, record_id)
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Record not found"
            )
        record = _decorate_venipuncture_record(db, record)
        attachments = _parse_attachment_paths(record.get("attachment_path"))
        return templates.TemplateResponse(
            "venepunchere_response.html",
            {
                "request": request,
                "record_id": record_id,
                "token": token,
                "record": record,
                "attachments": attachments,
                "message": None,
                "error": None,
            },
        )

    @app.post("/venepunchere/{record_id}/{token}", response_class=HTMLResponse)
    @app.post("/Venepunchere/{record_id}/{token}", response_class=HTMLResponse)
    async def venepunchere_submit_response(
        record_id: str,
        token: str,
        request: Request,
        response_text: str = Form(...),
        db: Session = Depends(get_db),
    ):
        payload = decode_public_token(token, purpose="response_link")
        token_record_id = payload.get("hiccup_id")
        if token_record_id and token_record_id != record_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="Token mismatch"
            )
        record = _load_venepunchre_record(db, record_id)
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Record not found"
            )
        record = _decorate_venipuncture_record(db, record)

        cleaned_response = (response_text or "").strip()
        if not cleaned_response:
            attachments = _parse_attachment_paths(record.get("attachment_path"))
            return templates.TemplateResponse(
                "venepunchere_response.html",
                {
                    "request": request,
                    "record_id": record_id,
                    "token": token,
                    "record": record,
                    "attachments": attachments,
                    "message": None,
                    "error": "Response is required.",
                },
                status_code=400,
            )

        if record.get("response_text"):
            attachments = _parse_attachment_paths(record.get("attachment_path"))
            return templates.TemplateResponse(
                "venepunchere_response.html",
                {
                    "request": request,
                    "record_id": record_id,
                    "token": token,
                    "record": record,
                    "attachments": attachments,
                    "message": "Response already submitted for this record.",
                    "error": None,
                },
            )

        responder_id = payload.get("user_id")
        responder_name = payload.get("name")
        if not responder_name and responder_id:
            staff = db.query(Staff).filter(Staff.id == int(responder_id)).first()
            if staff and staff.name:
                responder_name = staff.name
        if not responder_name:
            responder_name = "External"
        venipuncture_cols = _get_columns(db, "venepunchre_records")
        update_parts = []
        params = {"record_id": record_id}

        if "response_text" in venipuncture_cols:
            update_parts.append("response_text = :response_text")
            params["response_text"] = cleaned_response
        if "status" in venipuncture_cols:
            update_parts.append("status = 'Responded'")
        if "response_by" in venipuncture_cols:
            update_parts.append("response_by = :response_by")
            params["response_by"] = responder_id
        if "response_by_name" in venipuncture_cols:
            update_parts.append("response_by_name = :response_by_name")
            params["response_by_name"] = responder_name
        if "is_response_overdue" in venipuncture_cols:
            update_parts.append("is_response_overdue = 0")
        if "is_closure_overdue" in venipuncture_cols:
            update_parts.append("is_closure_overdue = 0")
        if "updated_at" in venipuncture_cols:
            update_parts.append("updated_at = NOW()")

        if not update_parts:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="No updatable response columns found in venepunchre_records",
            )

        db.execute(
            text(
                f"""
                UPDATE venepunchre_records
                SET {", ".join(update_parts)}
                WHERE hiccup_id = :record_id
                """
            ),
            params,
        )
        db.commit()

        updated_record = _load_venepunchre_record(db, record_id) or record
        updated_record = _decorate_venipuncture_record(db, updated_record)
        attachments = _parse_attachment_paths(updated_record.get("attachment_path"))
        return templates.TemplateResponse(
            "venepunchere_response.html",
            {
                "request": request,
                "record_id": record_id,
                "token": token,
                "record": updated_record,
                "attachments": attachments,
                "message": "Response submitted successfully.",
                "error": None,
            },
        )

    @app.get("/wa/redirect/{hiccup_id}")
    async def wa_response_redirect(
        request: Request,
        hiccup_id: str,
        public_token: str | None = Query(None),
        short_token: str | None = Query(None, alias="t"),
        db: Session = Depends(get_db),
    ):
        token_value = public_token or short_token
        if not token_value:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="public_token required",
            )
        payload = decode_public_token(token_value, purpose="response_link")
        if payload.get("hiccup_id") != hiccup_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="Token mismatch"
            )
        venep_record = _load_venepunchre_record(db, hiccup_id)
        # Prefer the incoming host/proto for redirect; fall back to configured external URLs.
        # Prefer explicitly configured external response base (with port) to avoid
        # proxy host stripping the custom port.
        base = (
            settings.external_whatsapp_response_base_url
            or settings.whatsapp_response_base_url
            or settings.frontend_base_url
        ).rstrip("/")
        if venep_record:
            target = f"{base}/venepunchere/{hiccup_id}/{quote_plus(token_value)}"
        else:
            target = f"{base}/public/hiccups/{hiccup_id}?public_token={quote_plus(token_value)}"
        return RedirectResponse(target)

    if os.getenv("SCHEDULER_PRIMARY", "0") == "1":
        start_scheduler()
    return app

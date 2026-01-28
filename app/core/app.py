import logging
import os
from fastapi import FastAPI, Request, Depends, HTTPException, Query, status
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
from sqlalchemy import inspect, text
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

settings = get_settings()


templates = Jinja2Templates(directory="app/templates")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


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

        hiccup_stats = {
            "total": hiccup_q.count(),
            "open": hiccup_q.filter(Hiccup.status == "Open").count(),
            "responded": hiccup_q.filter(Hiccup.status == "Responded").count(),
            "closed": hiccup_q.filter(Hiccup.status == "Closed").count(),
        }

        infra_stats = {
            "total": infra_q.count() if infra_q is not None else 0,
            "open": infra_q.filter(InfraTicket.status.notin_(["Resolved", "Rejected"])).count() if infra_q is not None else 0,
            "resolved": infra_q.filter(InfraTicket.status == "Resolved").count() if infra_q is not None else 0,
            "rejected": infra_q.filter(InfraTicket.status == "Rejected").count() if infra_q is not None else 0,
            "delayed": infra_q.filter(InfraTicket.is_delayed_pick == True).count() if infra_q is not None else 0,
            "invalid": infra_q.filter(InfraTicket.is_invalid == True).count() if infra_q is not None else 0,
        }

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
        hiccup_total = db.query(Hiccup).count()
        hiccup_open = db.query(Hiccup).filter(Hiccup.status == "Open").count()
        hiccup_responded = db.query(Hiccup).filter(Hiccup.status == "Responded").count()
        hiccup_closed = db.query(Hiccup).filter(Hiccup.status == "Closed").count()

        infra_total = db.query(InfraTicket).count()
        infra_open = (
            db.query(InfraTicket)
            .filter(InfraTicket.status.notin_(["Resolved", "Rejected"]))
            .count()
        )
        infra_resolved = (
            db.query(InfraTicket).filter(InfraTicket.status == "Resolved").count()
        )
        infra_delayed = (
            db.query(InfraTicket).filter(InfraTicket.is_delayed_pick == True).count()
        )
        infra_invalid = (
            db.query(InfraTicket).filter(InfraTicket.is_invalid == True).count()
        )

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
                "hiccup": {
                    "total": hiccup_total,
                    "open": hiccup_open,
                    "responded": hiccup_responded,
                    "closed": hiccup_closed,
                },
                "infra": {
                    "total": infra_total,
                    "open": infra_open,
                    "resolved": infra_resolved,
                    "delayed": infra_delayed,
                    "invalid": infra_invalid,
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

    @app.get("/wa/redirect/{hiccup_id}")
    async def wa_response_redirect(
        request: Request,
        hiccup_id: str,
        public_token: str | None = Query(None),
        short_token: str | None = Query(None, alias="t"),
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
        # Prefer the incoming host/proto for redirect; fall back to configured external URLs.
        # Prefer explicitly configured external response base (with port) to avoid
        # proxy host stripping the custom port.
        base = (
            settings.external_whatsapp_response_base_url
            or settings.whatsapp_response_base_url
            or settings.frontend_base_url
        ).rstrip("/")
        target = f"{base}/public/hiccups/{hiccup_id}?public_token={quote_plus(token_value)}"
        return RedirectResponse(target)

    if os.getenv("SCHEDULER_PRIMARY", "0") == "1":
        start_scheduler()
    return app

from pathlib import Path
from typing import Optional
from datetime import datetime, timedelta
import os
import time
import logging
import threading
import uuid

import requests
from fastapi import APIRouter, Depends, Form, Request, UploadFile, File, Query
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from sqlalchemy import func, or_

from app.core.config import get_settings
from app.core.security import is_allowlisted_infra_admin_by_staff
from app.db.session import MainSessionLocal
from app.core.security import TokenData, get_current_user
from app.db.session import SessionLocal
from app.models.infra import InfraTicket, InfraTicketImage, InfraUpdate
from app.models.staff import Staff
from app.utils.time_utils import now_local_naive


router = APIRouter()
templates = Jinja2Templates(directory="app/templates")
settings = get_settings()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

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


def _reminder_loop():
    """
    Background loop to send reminders even when no web requests occur.
    """
    while True:
        try:
            db = SessionLocal()
            _send_pick_reminders(db)
        except Exception as exc:
            logger.exception("InfraReminder background loop error: %s", exc)
        finally:
            try:
                db.close()
            except Exception:
                pass
        time.sleep(REMINDER_INTERVAL_SECONDS)


def _pid_alive(pid: int) -> bool:
    """
    Best-effort check if a process is alive.
    """
    try:
        # On Windows and Unix, signal 0 checks existence.
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _acquire_reminder_lock(lock_path: Path) -> bool:
    """
    Ensure only one process starts the reminder loop by using a pid file lock.
    """
    lock_path.parent.mkdir(exist_ok=True)
    pid = os.getpid()
    try:
        fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.write(fd, str(pid).encode())
        os.close(fd)
        return True
    except FileExistsError:
        try:
            existing_pid = int((lock_path.read_text() or "0").strip())
        except Exception:
            existing_pid = 0
        if existing_pid and _pid_alive(existing_pid):
            logger.info("InfraReminder loop already running (pid=%s); skipping start", existing_pid)
            return False
        # Stale lock; reclaim
        try:
            lock_path.unlink()
        except Exception:
            pass
        try:
            fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, str(pid).encode())
            os.close(fd)
            return True
        except Exception:
            logger.info("InfraReminder lock contention; skipping start")
            return False


def _start_reminder_loop_once():
    """
    Start the reminder thread only if we hold the singleton lock.
    """
    lock_path = Path("logs") / "infra_reminder.lock"
    if _acquire_reminder_lock(lock_path):
        thread = threading.Thread(target=_reminder_loop, daemon=True)
        thread.start()
        return thread
    return None


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

    _send_pick_reminders(db)


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
    db: Session = Depends(get_db),
    user: TokenData = Depends(get_current_user),
):
    username = user.name if user else None

    # update delayed flags before showing user's tickets
    _update_delayed_flags(db)

    tickets = (
        db.query(InfraTicket)
        .filter(InfraTicket.created_by == username)
        .order_by(InfraTicket.ticket_id.desc())
        .all()
    )

    return templates.TemplateResponse(
        "infra/my_tickets.html",
        {
            "request": request,
            "username": username,
            "user": user,
            "tickets": tickets,
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

    q = db.query(InfraTicket)

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

    total = db.query(InfraTicket).count()
    open_count = db.query(InfraTicket).filter(InfraTicket.status != "Resolved").count()
    resolved = db.query(InfraTicket).filter(InfraTicket.status == "Resolved").count()
    delayed = db.query(InfraTicket).filter(InfraTicket.is_delayed_pick == True).count()

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
        return RedirectResponse(url="/infra/all", status_code=303)

    # If another member already owns this ticket, block reassignment
    if ticket.assigned_to and ticket.assigned_to != username:
        return RedirectResponse(url="/infra/all", status_code=303)

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
        return RedirectResponse(url="/infra/all", status_code=303)

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
    return RedirectResponse(url="/infra/all", status_code=303)

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
        return RedirectResponse(url="/infra/all", status_code=303)

    # Only the assigned member can resolve
    username = user.name if user else None
    username_norm = username.lower() if username else ""
    if ticket.assigned_to and ticket.assigned_to.lower() != username_norm:
        return RedirectResponse(url="/infra/all", status_code=303)

    # If resolving after commitment time, mark delayed
    if ticket.commitment_time and now_local_naive() > ticket.commitment_time:
        ticket.is_delayed_pick = True

    db.query(InfraTicket).filter(InfraTicket.ticket_id == ticket_id).update(
        {
            InfraTicket.status: "Resolved",
            InfraTicket.is_delayed_pick: ticket.is_delayed_pick,
        },
        synchronize_session=False,
    )
    db.commit()

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

    return RedirectResponse(url="/infra/all", status_code=303)


# -------------------------------------------------------------
# MARK TICKET INVALID (IT ONLY) → STATUS = REJECTED
# -------------------------------------------------------------
@router.post("/infra/invalid/{ticket_id}")
def mark_invalid(
    ticket_id: int,
    request: Request,
    invalid_reason: str = Form(...),
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
        return RedirectResponse(url="/infra/all", status_code=303)

    # Only the assigned member can mark invalid
    username = user.name if user else None
    username_norm = username.lower() if username else ""
    if ticket.assigned_to and ticket.assigned_to.lower() != username_norm:
        return RedirectResponse(url="/infra/all", status_code=303)

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

    return RedirectResponse(url="/infra/all", status_code=303)


_reminder_thread = _start_reminder_loop_once()

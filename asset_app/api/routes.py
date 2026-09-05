from datetime import date, datetime
from calendar import monthrange
from pathlib import Path
import shutil, uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import StreamingResponse, HTMLResponse, FileResponse
from io import BytesIO
import qrcode
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from asset_app.db.session import get_db
from asset_app.models import *
from asset_app.schemas import *
from asset_app.core.security import create_token, current_user, require_roles
from asset_app.core.config import settings
from asset_app.core.timezone import now_ist
from asset_app.services.workflows import *

api = APIRouter(prefix="/api")


def get_asset(db, id):
    a = db.get(Asset, id)
    if not a:
        raise HTTPException(404, "Asset not found")
    return a


def _can_view_all_assets(user) -> bool:
    return getattr(user.role, "name", "") in {
        "Administrator",
        "Asset Manager",
        "Technician",
    }


def _current_employee_id(db: Session, user) -> int | None:
    employee = db.scalar(
        select(Employee).where(Employee.employee_code == f"EXT-{user.id}")
    )
    if not employee and getattr(user, "contact", None):
        employee = db.scalar(select(Employee).where(Employee.mobile == user.contact))
    if not employee and getattr(user, "name", None):
        employee = db.scalar(select(Employee).where(Employee.name == user.name))
    return employee.id if employee else None


def _visible_asset_statement(db: Session, user):
    stmt = select(Asset)
    if _can_view_all_assets(user):
        return stmt
    employee_id = _current_employee_id(db, user)
    if not employee_id:
        return stmt.where(Asset.id == -1)
    return stmt.where(
        (Asset.issued_to_employee_id == employee_id)
        | (Asset.staff_incharge_employee_id == employee_id)
    )


def require_asset_access(db: Session, asset: Asset, user) -> None:
    if _can_view_all_assets(user):
        return
    employee_id = _current_employee_id(db, user)
    if employee_id and employee_id in {
        asset.issued_to_employee_id,
        asset.staff_incharge_employee_id,
    }:
        return
    raise HTTPException(403, "You can only access assets assigned to you")


def add_calendar_months(value: date, months: int) -> date:
    """Add whole calendar months while keeping month-end dates valid."""
    month_index = value.month - 1 + months
    year = value.year + month_index // 12
    month = month_index % 12 + 1
    return date(year, month, min(value.day, monthrange(year, month)[1]))


def asset_view(db, a, public=False):
    cat = db.get(AssetCategory, a.category_id)
    typ = db.get(AssetType, a.asset_type_id)
    make = db.get(AssetMake, a.make_id) if a.make_id else None
    site = db.get(Site, a.current_site_id)
    floor = db.get(Floor, a.current_floor_id) if a.current_floor_id else None
    department = (
        db.get(Department, a.current_department_id) if a.current_department_id else None
    )
    workstation = (
        db.get(Workstation, a.current_workstation_id)
        if a.current_workstation_id
        else None
    )
    inc = db.get(Employee, a.staff_incharge_employee_id)
    issued = (
        db.get(Employee, a.issued_to_employee_id) if a.issued_to_employee_id else None
    )
    location = " / ".join(x.name for x in [site, floor, department, workstation] if x)
    d = {
        "id": a.id,
        "asset_code": a.asset_code,
        "asset_name": a.asset_name,
        "category": cat.name,
        "category_id": a.category_id,
        "type": typ.name,
        "asset_type_id": a.asset_type_id,
        "make": make.name if make else None,
        "make_id": a.make_id,
        "model": a.model_text,
        "serial_number": a.serial_number,
        "criticality": a.criticality,
        "location": location,
        "site": site.name if site else None,
        "site_id": a.current_site_id,
        "floor": floor.name if floor else None,
        "floor_id": a.current_floor_id,
        "department": department.name if department else None,
        "department_id": a.current_department_id,
        "workstation": workstation.name if workstation else None,
        "workstation_id": a.current_workstation_id,
        "staff_incharge": inc.name,
        "staff_incharge_designation": inc.designation,
        "staff_incharge_contact": inc.mobile,
        "staff_incharge_employee_id": a.staff_incharge_employee_id,
        "issued_to": issued.name if issued else None,
        "issued_to_designation": issued.designation if issued else None,
        "issued_to_contact": issued.mobile if issued else None,
        "issued_to_employee_id": a.issued_to_employee_id,
        "operational_status": a.operational_status,
        "lifecycle_state": a.lifecycle_state,
        "pm_required": a.pm_required,
        "pm_period_months": a.pm_period_months,
        "calibration_mode": a.calibration_mode,
        "calibration_period_months": a.calibration_period_months,
        "warranty_end": str(a.warranty_end_date) if a.warranty_end_date else None,
        "photo_url": (
            f"{settings.asset_base_path.rstrip('/')}/q/{a.public_token}/photo" if a.primary_photo_path else None
        ),
    }
    if not public:
        d.update(
            {
                "holding_class": a.holding_class,
                "purchase_date": str(a.purchase_date) if a.purchase_date else None,
                "purchase_value": (
                    str(a.purchase_value) if a.purchase_value is not None else None
                ),
                "invoice_reference": a.invoice_reference,
                "warranty_start_date": (
                    str(a.warranty_start_date) if a.warranty_start_date else None
                ),
                "warranty_document_path": a.warranty_document_path,
                "warranty_document_url": (
                    f"{settings.asset_base_path.rstrip('/')}/api/uploads/{a.warranty_document_path}"
                    if a.warranty_document_path
                    else None
                ),
                "useful_life_months": a.useful_life_months,
                "primary_service_contact_id": a.primary_service_contact_id,
                "primary_photo_path": a.primary_photo_path,
                "public_token": a.public_token,
                "created_at": a.created_at,
                "updated_at": a.updated_at,
            }
        )
    return d


def display_employee(db, value):
    raw = str(value or "").strip()
    if not raw:
        return None
    employee = db.get(Employee, int(raw)) if raw.isdigit() else None
    if not employee:
        employee = db.scalar(select(Employee).where(Employee.name == raw))
    if not employee:
        return raw
    parts = [employee.name]
    if employee.designation:
        parts.append(employee.designation)
    if employee.mobile:
        parts.append(employee.mobile)
    return " · ".join(parts)


@api.post("/auth/login", response_model=TokenOut)
def login(data: LoginInput, db: Session = Depends(get_db)):
    users = db.scalars(
        select(User).where(User.name == data.username.strip(), User.status == "Active")
    ).all()
    user = next(
        (
            item
            for item in users
            if _dob_password(item.dob) == (data.password or "").strip()
        ),
        None,
    )
    if not user:
        raise HTTPException(401, "Incorrect username or DOB password")
    return TokenOut(
        access_token=create_token(user), username=user.username, role=user.role.name
    )


def _dob_password(value: str | None) -> str | None:
    raw = (value or "").strip()
    for date_format in ("%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d", "%Y/%m/%d"):
        try:
            return datetime.strptime(raw, date_format).strftime("%d%m%Y")
        except ValueError:
            continue
    return None


@api.get("/auth/user-suggestions")
def login_user_suggestions(q: str = "", db: Session = Depends(get_db)):
    term = q.strip()
    if len(term) < 2:
        return []
    users = db.scalars(
        select(User)
        .where(User.status == "Active", User.name.contains(term))
        .order_by(User.name)
        .limit(8)
    ).all()
    return [
        {"id": user.id, "name": user.name, "designation": user.designation}
        for user in users
    ]


@api.get("/auth/me")
def me(user=Depends(current_user)):
    return {
        "username": user.username,
        "role": user.role.name,
        "must_change_password": user.must_change_password,
    }


@api.get("/roles")
def available_roles(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    allowed_ids = (1, 2, 3, 7)
    roles = db.scalars(select(Role).where(Role.id.in_(allowed_ids)).order_by(Role.id)).all()
    return [
        {"id": role.id, "name": role.name, "description": role.description}
        for role in roles
    ]


@api.get("/users")
def users_for_administration(
    q: str = "",
    limit: int = 7,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    stmt = select(User).where(User.status == "Active")
    term = q.strip()
    if term:
        search = f"%{term}%"
        stmt = stmt.where(
            User.name.like(search)
            | User.contact.like(search)
            | User.designation.like(search)
        )
    users = db.scalars(stmt.order_by(User.name).limit(max(1, min(limit, 7)))).all()
    return [
        {
            "id": item.id,
            "name": item.name,
            "contact": item.contact,
            "designation": item.designation,
            "status": item.status,
            "role_id": item.role_id,
            "role": item.role.name,
        }
        for item in users
    ]


@api.put("/users/{user_id}/role")
def update_user_role(
    user_id: int,
    data: UserRoleUpdate,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    role = db.get(Role, data.role_id)
    if not role or role.id not in {1, 2, 3, 7}:
        raise HTTPException(422, "Invalid role")
    target = db.get(User, user_id)
    if not target:
        raise HTTPException(404, "User not found")
    if target.id == user.id and role.name != "Administrator":
        raise HTTPException(400, "You cannot remove your own Administrator role")
    role_codes = {
        1: "administrator",
        2: "technician",
        3: "asset_manager",
        7: "employee",
    }
    target.role_id = role.id
    target.role_name = role_codes[role.id]
    db.add(
        AuditLog(
            entity_type="user",
            entity_id=str(target.id),
            action="ROLE_CHANGED",
            metadata_text=f"{target.name} assigned {role.name} by {user.username}",
        )
    )
    db.commit()
    return {"id": target.id, "name": target.name, "role_id": role.id, "role": role.name}


@api.get("/masters/{master}")
def masters(master: str, db: Session = Depends(get_db), user=Depends(current_user)):
    if not _can_view_all_assets(user):
        raise HTTPException(403, "Insufficient permission")
    mapping = {
        "categories": AssetCategory,
        "makes": AssetMake,
        "sites": Site,
        "floors": Floor,
        "departments": Department,
        "workstations": Workstation,
        "employees": Employee,
        "vendors": Vendor,
        "contacts": ServiceContact,
        "types": AssetType,
    }
    model = mapping.get(master)
    if not model:
        raise HTTPException(404, "Unknown master")
    order = (
        model.id
        if master in {"categories", "types"}
        else (Vendor.company_name if master == "vendors" else model.name)
    )
    rows = db.scalars(select(model).order_by(order)).all()
    return [
        (
            {
                "id": x.id,
                "name": getattr(x, "name", getattr(x, "company_name", None)),
                "category_id": x.category_id,
            }
            if master == "types"
            else (
                {
                    "id": x.id,
                    "name": getattr(x, "name", getattr(x, "company_name", None)),
                    "site_id": x.site_id,
                    "department_id": getattr(x, "department_id", None),
                }
                if master == "workstations"
                else (
                    {
                        "id": x.id,
                        "name": getattr(x, "name", getattr(x, "company_name", None)),
                        "site_id": x.site_id,
                    }
                    if master == "floors"
                    else (
                        {
                            "id": x.id,
                            "name": x.company_name,
                            "phone": x.phone,
                            "email": x.email,
                            "address": x.address,
                        }
                        if master == "vendors"
                        else (
                        {
                            "id": x.id,
                            "name": x.name,
                            "vendor_id": x.vendor_id,
                            "vendor_name": db.get(Vendor, x.vendor_id).company_name
                            if x.vendor_id and db.get(Vendor, x.vendor_id)
                            else None,
                            "vendor_phone": db.get(Vendor, x.vendor_id).phone
                            if x.vendor_id and db.get(Vendor, x.vendor_id)
                            else None,
                            "vendor_whatsapp": db.get(Vendor, x.vendor_id).whatsapp
                            if x.vendor_id and db.get(Vendor, x.vendor_id)
                            else None,
                            "mobile": x.mobile,
                            "email": x.email,
                            "designation": x.designation,
                            }
                            if master == "contacts"
                            else {
                                "id": x.id,
                                "name": getattr(x, "name", None),
                            }
                        )
                    )
                )
            )
        )
        for x in rows
    ]


@api.get("/active-users")
def active_users(
    q: str = "",
    limit: int = 20,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    term = q.strip()
    stmt = select(User).where(User.status == "Active")
    if term:
        search = f"%{term}%"
        stmt = stmt.where(
            User.name.like(search)
            | User.contact.like(search)
            | User.designation.like(search)
            | User.departments.like(search)
        )
    local_users = db.scalars(
        stmt.order_by(User.name).limit(max(1, min(limit, 50)))
    ).all()
    results = []
    for local_user in local_users:
        employee_code = f"EXT-{local_user.id}"
        employee = db.scalar(
            select(Employee).where(Employee.employee_code == employee_code)
        )
        if not employee:
            employee = Employee(employee_code=employee_code, name=local_user.name)
            db.add(employee)
        employee.name = local_user.name
        employee.mobile = local_user.contact
        employee.designation = local_user.designation
        employee.is_active = True
        db.flush()
        results.append(
            {
                "id": employee.id,
                "external_id": local_user.id,
                "name": employee.name,
                "contact": employee.mobile,
                "designation": employee.designation,
                "department": local_user.departments,
            }
        )
    db.commit()
    return results


@api.post("/masters/{master}")
def create_master(
    master: str,
    data: MasterInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    if master == "types":
        if not data.category_id or not db.get(AssetCategory, data.category_id):
            raise HTTPException(422, "A valid asset category is required")
        o = AssetType(name=data.name, category_id=data.category_id)
    else:
        mapping = {
            "categories": AssetCategory,
            "makes": AssetMake,
            "sites": Site,
            "departments": Department,
        }
        model = mapping.get(master)
        if not model:
            raise HTTPException(404, "Use dedicated endpoint for this master")
        o = model(name=data.name)
    db.add(o)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "A master with this name already exists")
    db.refresh(o)
    return {
        "id": o.id,
        "name": o.name,
        "category_id": o.category_id if master == "types" else None,
    }


@api.put("/masters/{master}/{item_id}")
def update_master(
    master: str,
    item_id: int,
    data: MasterUpdateInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    mapping = {
        "categories": AssetCategory,
        "types": AssetType,
        "makes": AssetMake,
        "sites": Site,
        "departments": Department,
        "vendors": Vendor,
        "contacts": ServiceContact,
        "workstations": Workstation,
    }
    model = mapping.get(master)
    if not model:
        raise HTTPException(404, "Unknown master")
    item = db.get(model, item_id)
    if not item:
        raise HTTPException(404, "Master record not found")
    if master == "types":
        if not data.category_id or not db.get(AssetCategory, data.category_id):
            raise HTTPException(422, "A valid asset category is required")
        item.name, item.category_id = data.name, data.category_id
    elif master == "vendors":
        item.company_name = data.name
        item.phone, item.email, item.address = data.phone, data.email, data.address
    elif master == "contacts":
        if data.vendor_id and not db.get(Vendor, data.vendor_id):
            raise HTTPException(422, "Vendor not found")
        item.name, item.vendor_id = data.name, data.vendor_id
        item.mobile, item.email = data.mobile, data.email
    elif master == "workstations":
        if not data.site_id or not db.get(Site, data.site_id):
            raise HTTPException(422, "A valid site is required")
        if data.department_id and not db.get(Department, data.department_id):
            raise HTTPException(422, "Department not found")
        item.name, item.site_id = data.name, data.site_id
        item.department_id = data.department_id
    else:
        item.name = data.name
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Another master record already uses these values")
    return {"id": item.id, "name": getattr(item, "name", getattr(item, "company_name", None))}


@api.delete("/masters/{master}/{item_id}", status_code=204)
def delete_master(
    master: str,
    item_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    mapping = {
        "categories": AssetCategory,
        "types": AssetType,
        "makes": AssetMake,
        "sites": Site,
        "departments": Department,
        "vendors": Vendor,
        "contacts": ServiceContact,
        "workstations": Workstation,
    }
    model = mapping.get(master)
    if not model:
        raise HTTPException(404, "Unknown master")
    item = db.get(model, item_id)
    if not item:
        raise HTTPException(404, "Master record not found")
    db.delete(item)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "This master is in use and cannot be deleted")


@api.post("/vendors")
def create_vendor(
    data: VendorInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    vendor = Vendor(**data.model_dump())
    db.add(vendor)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Vendor name already exists")
    return {"id": vendor.id, "name": vendor.company_name}


@api.post("/contacts")
def create_contact(
    data: ServiceContactInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    if data.vendor_id and not db.get(Vendor, data.vendor_id):
        raise HTTPException(422, "Vendor not found")
    contact = ServiceContact(**data.model_dump())
    db.add(contact)
    db.commit()
    return {"id": contact.id, "name": contact.name}


@api.post("/masters/workstations")
def create_workstation(
    data: WorkstationInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    if not db.get(Site, data.site_id):
        raise HTTPException(422, "Site not found")
    if data.department_id and not db.get(Department, data.department_id):
        raise HTTPException(422, "Department not found")
    item = Workstation(**data.model_dump())
    db.add(item)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Workstation already exists")
    return {
        "id": item.id,
        "name": item.name,
        "site_id": item.site_id,
        "department_id": item.department_id,
    }


@api.post("/workstations")
def create_workstation_alias(
    data: WorkstationInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    return create_workstation(data, db, user)


@api.get("/assets")
def assets(
    q: str | None = None,
    category_id: int | None = None,
    site_id: int | None = None,
    status: str | None = None,
    page: int = 1,
    size: int = 30,
    db: Session = Depends(get_db),
    user=Depends(current_user),
):
    stmt = _visible_asset_statement(db, user)
    if q:
        stmt = stmt.where(
            (Asset.asset_code.contains(q))
            | (Asset.asset_name.contains(q))
            | (Asset.serial_number.contains(q))
        )
    if category_id:
        stmt = stmt.where(Asset.category_id == category_id)
    if site_id:
        stmt = stmt.where(Asset.current_site_id == site_id)
    if status:
        stmt = stmt.where(Asset.operational_status == status)
    total = db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = db.scalars(
        stmt.order_by(Asset.id.desc()).offset((page - 1) * size).limit(min(size, 100))
    ).all()
    return {"items": [asset_view(db, x) for x in rows], "total": total, "page": page}


@api.post("/assets")
def create_asset(
    data: AssetInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    _validate_asset_input(db, data)
    values = data.model_dump(exclude={"service_contact_ids"})
    a = Asset(
        asset_code=next_asset_code(db, data.category_id),
        public_token=__import__("secrets").token_urlsafe(24),
        **values,
    )
    db.add(a)
    db.flush()
    transfer(
        db,
        a,
        a.current_site_id,
        a.current_floor_id,
        a.current_department_id,
        a.current_workstation_id,
    )
    change_incharge(db, a, a.staff_incharge_employee_id)
    event(db, a.id, "ASSET_CREATED", "Asset created")
    contact_ids = set(data.service_contact_ids) | {data.primary_service_contact_id}
    db.add_all(
        [
            AssetServiceContact(
                asset_id=a.id,
                contact_id=i,
                is_primary=i == data.primary_service_contact_id,
            )
            for i in contact_ids
        ]
    )
    db.commit()
    db.refresh(a)
    return asset_view(db, a)


def _validate_asset_input(db, data):
    asset_type = db.get(AssetType, data.asset_type_id)
    if not asset_type or asset_type.category_id != data.category_id:
        raise HTTPException(422, "Asset type must belong to the selected category")
    if not db.get(Site, data.current_site_id) or not db.get(
        Employee, data.staff_incharge_employee_id
    ):
        raise HTTPException(422, "A valid site and staff in-charge are required")
    if not db.get(ServiceContact, data.primary_service_contact_id):
        raise HTTPException(422, "Primary service contact not found")
    if data.current_floor_id:
        floor = db.get(Floor, data.current_floor_id)
        if not floor or floor.site_id != data.current_site_id:
            raise HTTPException(422, "Floor must belong to the selected site")
    if data.current_workstation_id:
        ws = db.get(Workstation, data.current_workstation_id)
        if not ws or ws.site_id != data.current_site_id:
            raise HTTPException(422, "Workstation must belong to the selected site")
    if data.calibration_mode not in {"REQUIRED", "NOT_REQUIRED"}:
        raise HTTPException(422, "Invalid calibration mode")
    if data.pm_required and data.pm_period_months not in {1, 3, 6, 12}:
        raise HTTPException(422, "Select a valid PM period")
    if not data.pm_required and data.pm_period_months is not None:
        raise HTTPException(422, "PM period is only allowed when PM is required")
    if data.calibration_mode == "REQUIRED" and data.calibration_period_months not in {
        1,
        3,
        6,
        12,
    }:
        raise HTTPException(422, "Select a valid calibration period")
    if (
        data.calibration_mode == "NOT_REQUIRED"
        and data.calibration_period_months is not None
    ):
        raise HTTPException(422, "Calibration period is only allowed when required")


@api.get("/assets/{asset_id}")
def asset_detail(
    asset_id: int, db: Session = Depends(get_db), user=Depends(current_user)
):
    a = get_asset(db, asset_id)
    require_asset_access(db, a, user)
    out = asset_view(db, a)
    out["timeline"] = [
        {"type": e.event_type, "message": e.message, "at": e.occurred_at}
        for e in db.scalars(
            select(AssetEvent)
            .where(AssetEvent.asset_id == a.id)
            .order_by(AssetEvent.occurred_at.desc())
        ).all()
    ]
    def contact_view(contact, is_primary):
        vendor = db.get(Vendor, contact.vendor_id) if contact.vendor_id else None
        return {
            "id": contact.id,
            "name": contact.name,
            "designation": contact.designation,
            "mobile": contact.mobile,
            "alternate_mobile": contact.alternate_mobile,
            "whatsapp": contact.whatsapp,
            "email": contact.email,
            "notes": contact.notes,
            "is_primary": is_primary,
            "vendor": (
                {
                    "id": vendor.id,
                    "company_name": vendor.company_name,
                    "phone": vendor.phone,
                    "whatsapp": vendor.whatsapp,
                    "email": vendor.email,
                    "address": vendor.address,
                    "gstin": vendor.gstin,
                }
                if vendor
                else None
            ),
        }

    contacts = []
    for link in db.scalars(
        select(AssetServiceContact).where(AssetServiceContact.asset_id == a.id)
    ).all():
        contact = db.get(ServiceContact, link.contact_id)
        if not contact:
            continue
        contacts.append(contact_view(contact, link.is_primary))
    if a.primary_service_contact_id and not any(
        contact["id"] == a.primary_service_contact_id for contact in contacts
    ):
        primary = db.get(ServiceContact, a.primary_service_contact_id)
        if primary:
            contacts.append(contact_view(primary, True))
    out["service_contacts"] = sorted(
        contacts, key=lambda contact: not contact["is_primary"]
    )
    out["documents"] = [
        {
            "id": d.id,
            "document_type": d.document_type,
            "title": d.title,
            "path": d.file_path,
            "url": f"{settings.asset_base_path.rstrip('/')}/api/uploads/{d.file_path}",
        }
        for d in db.scalars(
            select(AssetDocument)
            .where(AssetDocument.asset_id == a.id)
            .order_by(AssetDocument.id.desc())
        ).all()
    ]
    pm_schedule = db.scalar(select(PMSchedule).where(PMSchedule.asset_id == a.id))
    out["pm_records"] = (
        [
            {
                "id": record.id,
                "completed_at": record.completed_at,
                "performed_by": display_employee(db, record.performed_by),
                "remarks": record.remarks,
                "service_report_path": record.service_report_path,
                "cost": str(record.cost) if record.cost is not None else None,
                "calibration_performed": record.calibration_performed,
                "calibration_result": record.calibration_result,
                "calibration_certificate_path": record.calibration_certificate_path,
            }
            for record in db.scalars(
                select(PMRecord)
                .where(PMRecord.schedule_id == pm_schedule.id)
                .order_by(PMRecord.completed_at.desc())
            ).all()
        ]
        if pm_schedule
        else []
    )
    calibration_schedule = db.scalar(
        select(CalibrationSchedule).where(CalibrationSchedule.asset_id == a.id)
    )
    out["calibration_records"] = (
        [
            {
                "id": record.id,
                "completed_at": record.completed_at,
                "performed_by": display_employee(db, record.performed_by),
                "result": record.result,
                "certificate_path": record.certificate_path,
                "remarks": record.remarks,
            }
            for record in db.scalars(
                select(CalibrationRecord)
                .where(CalibrationRecord.schedule_id == calibration_schedule.id)
                .order_by(CalibrationRecord.completed_at.desc())
            ).all()
        ]
        if calibration_schedule
        else []
    )
    return out


@api.put("/assets/{asset_id}")
def update_asset(
    asset_id: int,
    data: AssetUpdateInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    a = get_asset(db, asset_id)
    _validate_asset_input(db, data)
    old_location = (
        a.current_site_id,
        a.current_floor_id,
        a.current_department_id,
        a.current_workstation_id,
    )
    old_incharge = a.staff_incharge_employee_id
    values = data.model_dump(exclude={"service_contact_ids"})
    for key, value in values.items():
        setattr(a, key, value)
    if old_location != (
        data.current_site_id,
        data.current_floor_id,
        data.current_department_id,
        data.current_workstation_id,
    ):
        transfer(
            db,
            a,
            data.current_site_id,
            data.current_floor_id,
            data.current_department_id,
            data.current_workstation_id,
        )
    if old_incharge != data.staff_incharge_employee_id:
        change_incharge(db, a, data.staff_incharge_employee_id)
    db.execute(
        AssetServiceContact.__table__.delete().where(
            AssetServiceContact.asset_id == a.id
        )
    )
    ids = set(data.service_contact_ids) | {data.primary_service_contact_id}
    db.add_all(
        [
            AssetServiceContact(
                asset_id=a.id,
                contact_id=i,
                is_primary=i == data.primary_service_contact_id,
            )
            for i in ids
        ]
    )
    event(db, a.id, "ASSET_UPDATED", "Asset registration updated")
    db.commit()
    return asset_view(db, a)


@api.post("/assets/{asset_id}/documents")
def asset_document(
    asset_id: int,
    data: AssetDocumentInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    a = get_asset(db, asset_id)
    doc = AssetDocument(asset_id=a.id, **data.model_dump())
    db.add(doc)
    event(db, a.id, "DOCUMENT_ADDED", data.document_type)
    db.commit()
    return {"id": doc.id}


@api.get("/assets/{asset_id}/qr.png")
def asset_qr(asset_id: int, db: Session = Depends(get_db), user=Depends(current_user)):
    a = get_asset(db, asset_id)
    require_asset_access(db, a, user)
    public_url = f"{settings.public_base_url.rstrip('/')}/q/{a.public_token}/page"
    image = qrcode.make(public_url)
    buf = BytesIO()
    image.save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(
        buf,
        media_type="image/png",
        headers={"Content-Disposition": f'inline; filename="{a.asset_code}.png"'},
    )


@api.post("/assets/{asset_id}/transfer")
def asset_transfer(
    asset_id: int,
    data: TransferInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    transfer(
        db,
        get_asset(db, asset_id),
        data.site_id,
        data.floor_id,
        data.department_id,
        data.workstation_id,
    )
    db.commit()
    return {"ok": True}


@api.post("/assets/{asset_id}/incharge")
def asset_incharge(
    asset_id: int,
    data: InchargeInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    if not db.get(Employee, data.employee_id):
        raise HTTPException(422, "Employee not found")
    change_incharge(db, get_asset(db, asset_id), data.employee_id)
    db.commit()
    return {"ok": True}


@api.post("/assets/{asset_id}/issue")
def issue(
    asset_id: int,
    data: IssueInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    a = get_asset(db, asset_id)
    if a.issued_to_employee_id:
        raise HTTPException(409, "Asset is already issued")
    db.add(
        AssetIssueHistory(
            asset_id=a.id,
            employee_id=data.employee_id,
            issued_by=user.username,
            issue_condition=data.condition,
            details=data.details,
        )
    )
    a.issued_to_employee_id = data.employee_id
    event(db, a.id, "ASSET_ISSUED", "Asset issued to employee")
    db.commit()
    return {"ok": True}


@api.post("/assets/{asset_id}/return")
def return_asset(
    asset_id: int,
    data: ReturnInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    a = get_asset(db, asset_id)
    h = db.scalar(
        select(AssetIssueHistory)
        .where(
            AssetIssueHistory.asset_id == a.id,
            AssetIssueHistory.returned_at.is_(None),
        )
        .with_for_update()
    )
    if not h:
        raise HTTPException(409, "No open issue exists")
    h.returned_at = now_ist()
    h.received_by = user.username
    h.return_condition = data.condition
    h.remarks = data.remarks
    a.issued_to_employee_id = None
    event(db, a.id, "ASSET_RETURNED", "Asset returned")
    db.commit()
    return {"ok": True}


@api.post("/assets/{asset_id}/lifecycle/{action}")
def lifecycle_request(
    asset_id: int,
    action: str,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    if action not in {"RETIRE", "CONDEMN", "LOST", "STOLEN", "DISPOSE"}:
        raise HTTPException(400, "Unsupported lifecycle action")
    a = get_asset(db, asset_id)
    approval = ApprovalRequest(
        approval_number=next_number(
            db, "approval-" + str(date.today().year), f"APR-{date.today().year}-"
        ),
        action_type="LIFECYCLE_" + action,
        asset_id=a.id,
        status="PENDING",
        details=f"{action} request for {a.asset_code}",
        requested_by=user.username,
    )
    db.add(approval)
    db.commit()
    return {"approval_number": approval.approval_number, "status": "PENDING"}


@api.get("/tickets")
def tickets(
    open_only: bool = False, db: Session = Depends(get_db), user=Depends(current_user)
):
    s = select(ServiceTicket).order_by(ServiceTicket.reported_at.desc())
    if not _can_view_all_assets(user):
        employee_id = _current_employee_id(db, user)
        if not employee_id:
            s = s.where(ServiceTicket.id == -1)
        else:
            visible_asset_ids = (
                select(Asset.id)
                .where(
                    (Asset.issued_to_employee_id == employee_id)
                    | (Asset.staff_incharge_employee_id == employee_id)
                )
                .subquery()
            )
            s = s.where(ServiceTicket.asset_id.in_(select(visible_asset_ids.c.id)))
    if open_only:
        s = s.where(ServiceTicket.status.not_in(["CLOSED", "CANCELLED"]))
    return [
        {
            "id": t.id,
            "ticket_number": t.ticket_number,
            "asset": get_asset(db, t.asset_id).asset_code,
            "complaint": t.complaint,
            "priority": t.priority,
            "status": t.status,
            "downtime_minutes": t.downtime_minutes,
        }
        for t in db.scalars(s).all()
    ]


@api.post("/tickets")
def create_ticket(
    data: TicketInput, db: Session = Depends(get_db), user=Depends(current_user)
):
    a = get_asset(db, data.asset_id)
    require_asset_access(db, a, user)
    priority = data.priority or {"C1": "Critical", "C2": "High"}.get(
        a.criticality, "Normal"
    )
    t = ServiceTicket(
        ticket_number=next_number(
            db, "ticket-" + str(date.today().year), f"SRV-{date.today().year}-"
        ),
        asset_id=a.id,
        complaint=data.complaint,
        priority=priority,
        reported_by=data.reported_by or user.username,
    )
    db.add(t)
    db.flush()
    ticket_event(db, t, "REPORTED", data.complaint)
    a.operational_status = "UNDER_REPAIR"
    event(db, a.id, "BREAKDOWN_REPORTED", f"{t.ticket_number}: {data.complaint}")
    db.commit()
    db.refresh(t)
    return {"id": t.id, "ticket_number": t.ticket_number}


@api.get("/tickets/{ticket_id}")
def ticket_detail(
    ticket_id: int, db: Session = Depends(get_db), user=Depends(current_user)
):
    t = db.get(ServiceTicket, ticket_id)
    if not t:
        raise HTTPException(404, "Ticket not found")
    asset = get_asset(db, t.asset_id)
    require_asset_access(db, asset, user)
    vendor = db.get(Vendor, t.vendor_id) if t.vendor_id else None
    return {
        "id": t.id,
        "ticket_number": t.ticket_number,
        "status": t.status,
        "complaint": t.complaint,
        "priority": t.priority,
        "downtime_minutes": t.downtime_minutes,
        "reported_by": display_employee(db, t.reported_by),
        "reported_at": t.reported_at,
        "assigned_to": display_employee(db, t.assigned_to),
        "vendor": vendor.company_name if vendor else None,
        "vendor_reference": t.vendor_reference,
        "restored_at": t.restored_at,
        "closed_at": t.closed_at,
        "asset": asset_view(db, asset),
        "events": [
            {
                "type": e.event_type,
                "notes": display_employee(db, e.notes)
                if e.event_type == "ASSIGN"
                else e.notes,
                "performed_by": display_employee(db, e.performed_by),
                "at": e.occurred_at,
            }
            for e in db.scalars(
                select(ServiceTicketEvent)
                .where(ServiceTicketEvent.ticket_id == t.id)
                .order_by(ServiceTicketEvent.occurred_at)
            ).all()
        ],
        "parts": [
            {
                "id": p.id,
                "description": p.description,
                "quantity": str(p.quantity),
                "unit_cost": str(p.unit_cost) if p.unit_cost is not None else None,
                "remarks": p.remarks,
            }
            for p in db.scalars(
                select(ServiceTicketPart).where(ServiceTicketPart.ticket_id == t.id)
            ).all()
        ],
    }


@api.post("/tickets/{ticket_id}/parts")
def ticket_part(
    ticket_id: int,
    data: PartInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    if not db.get(ServiceTicket, ticket_id):
        raise HTTPException(404, "Ticket not found")
    p = ServiceTicketPart(ticket_id=ticket_id, **data.model_dump())
    db.add(p)
    db.commit()
    return {"id": p.id}


@api.post("/tickets/{ticket_id}/{action}")
def ticket_action(
    ticket_id: int,
    action: str,
    data: TicketAction,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    ticket_transition(
        db,
        db.get(ServiceTicket, ticket_id)
        or (_ for _ in ()).throw(HTTPException(404, "Ticket not found")),
        action,
        data.notes,
        assigned_to=data.assigned_to,
        vendor_id=data.vendor_id,
        vendor_reference=data.vendor_reference,
    )
    db.commit()
    return {"ok": True}


@api.get("/pm/schedules")
def pm_schedules(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    result = []
    for schedule in db.scalars(select(PMSchedule)).all():
        asset = get_asset(db, schedule.asset_id)
        result.append(
            {
                "id": schedule.id,
                "asset": asset.asset_code,
                "asset_name": asset.asset_name,
                "next_due": schedule.next_due,
                "overdue": schedule.next_due < date.today(),
                "frequency_days": schedule.frequency_days,
                "pm_period_months": asset.pm_period_months,
                "active": schedule.active,
            }
        )
    return result


@api.get("/calibration/schedules")
def calibration_schedules(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    return [
        {
            "id": s.id,
            "asset": get_asset(db, s.asset_id).asset_code,
            "next_due": s.next_due,
            "frequency_days": s.frequency_days,
            "active": s.active,
        }
        for s in db.scalars(select(CalibrationSchedule)).all()
    ]


@api.post("/calibration/schedules")
def calibration_create(
    data: CalibrationInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    get_asset(db, data.asset_id)
    if db.scalar(
        select(CalibrationSchedule).where(CalibrationSchedule.asset_id == data.asset_id)
    ):
        raise HTTPException(409, "This asset already has a calibration schedule")
    s = CalibrationSchedule(**data.model_dump())
    db.add(s)
    db.commit()
    return {"id": s.id}


@api.post("/calibration/schedules/{schedule_id}/complete")
def calibration_complete(
    schedule_id: int,
    data: CalibrationCompleteInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Technician")),
):
    s = db.get(CalibrationSchedule, schedule_id)
    if not s:
        raise HTTPException(404, "Calibration schedule not found")
    db.add(CalibrationRecord(schedule_id=s.id, **data.model_dump()))
    s.next_due = data.completed_at.date() + __import__("datetime").timedelta(
        days=s.frequency_days
    )
    event(db, s.asset_id, "CALIBRATION_COMPLETED", f"Calibration {data.result}")
    db.commit()
    return {"ok": True, "next_due": s.next_due}


@api.post("/pm/schedules")
def pm_create(
    data: PMInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    asset = get_asset(db, data.asset_id)
    if not asset.pm_required or asset.pm_period_months not in {1, 3, 6, 12}:
        raise HTTPException(422, "Configure the asset's PM requirement and period first")
    if db.scalar(select(PMSchedule).where(PMSchedule.asset_id == asset.id)):
        raise HTTPException(409, "This asset already has a PM schedule")
    schedule_data = data.model_dump()
    schedule_data["frequency_days"] = {1: 30, 3: 90, 6: 180, 12: 365}[
        asset.pm_period_months
    ]
    s = PMSchedule(**schedule_data)
    db.add(s)
    db.commit()
    return {"id": s.id}


@api.post("/pm/schedules/{schedule_id}/complete")
def pm_complete(
    schedule_id: int,
    data: PMCompleteInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Technician")),
):
    if not data.service_report_path:
        raise HTTPException(422, "PM completion requires a service report attachment")
    s = db.get(PMSchedule, schedule_id)
    if not s:
        raise HTTPException(404, "PM schedule not found")
    asset = get_asset(db, s.asset_id)
    if not asset.pm_required or asset.pm_period_months not in {1, 3, 6, 12}:
        raise HTTPException(422, "Configure the asset's PM requirement and period first")
    expected_next_due = add_calendar_months(
        data.completed_at.date(), asset.pm_period_months
    )
    if data.next_due is not None and data.next_due != expected_next_due:
        raise HTTPException(422, "Next PM date does not match the asset's PM period")
    record_data = data.model_dump(exclude={"next_due"})
    db.add(PMRecord(schedule_id=s.id, **record_data))
    s.next_due = expected_next_due
    event(db, s.asset_id, "PM_COMPLETED", "Preventive maintenance completed")
    db.commit()
    return {"ok": True, "next_due": s.next_due}


@api.post("/contracts")
def contract(
    data: ContractInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    if not db.get(Vendor, data.vendor_id):
        raise HTTPException(422, "Vendor not found")
    missing = [asset_id for asset_id in data.asset_ids if not db.get(Asset, asset_id)]
    if missing:
        raise HTTPException(422, "One or more contract assets were not found")
    c = ServiceContract(
        contract_number=next_number(
            db, "contract-" + str(date.today().year), f"AMC-{date.today().year}-"
        ),
        contract_type=data.contract_type,
        vendor_id=data.vendor_id,
        start_date=data.start_date,
        end_date=data.end_date,
        value=data.value,
        reference_number=data.reference_number,
        notes=data.notes,
    )
    db.add(c)
    db.flush()
    db.add_all(
        [ServiceContractAsset(contract_id=c.id, asset_id=i) for i in data.asset_ids]
    )
    db.commit()
    return {"id": c.id, "contract_number": c.contract_number}


@api.get("/contracts")
def contracts(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    result = []
    for c in db.scalars(
        select(ServiceContract).order_by(ServiceContract.end_date)
    ).all():
        links = db.scalars(
            select(ServiceContractAsset).where(ServiceContractAsset.contract_id == c.id)
        ).all()
        renewals = db.scalars(
            select(ContractRenewal)
            .where(ContractRenewal.contract_id == c.id)
            .order_by(ContractRenewal.created_at.desc())
        ).all()
        result.append({
            "id": c.id,
            "contract_number": c.contract_number,
            "type": c.contract_type,
            "vendor": db.get(Vendor, c.vendor_id).company_name,
            "start_date": c.start_date,
            "end_date": c.end_date,
            "value": c.value,
            "reference_number": c.reference_number,
            "status": c.status,
            "assets": [get_asset(db, link.asset_id).asset_code for link in links],
            "renewals": [
                {
                    "id": renewal.id,
                    "approval_id": renewal.approval_id,
                    "status": renewal.status,
                    "old_end_date": renewal.old_end_date,
                    "new_end_date": renewal.new_end_date,
                    "renewed_at": renewal.renewed_at,
                }
                for renewal in renewals
            ],
        })
    return result


@api.post("/contracts/{contract_id}/renew")
def renew(
    contract_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    c = db.get(ServiceContract, contract_id)
    if not c:
        raise HTTPException(404, "Contract not found")
    legacy_approval = db.scalar(
        select(ApprovalRequest)
        .where(
            ApprovalRequest.action_type == "CONTRACT_RENEWAL",
            ApprovalRequest.details == f"Renew {c.contract_number}",
            ApprovalRequest.status.in_(["PENDING", "APPROVED"]),
        )
        .order_by(ApprovalRequest.created_at.desc())
    )
    if legacy_approval and not db.scalar(
        select(ContractRenewal).where(
            ContractRenewal.approval_id == legacy_approval.id
        )
    ):
        renewal_status = (
            "APPROVED" if legacy_approval.status == "APPROVED" else "REQUESTED"
        )
        db.add(
            ContractRenewal(
                contract_id=c.id,
                approval_id=legacy_approval.id,
                status=renewal_status,
            )
        )
        c.status = (
            "RENEWAL_APPROVED"
            if renewal_status == "APPROVED"
            else "RENEWAL_PENDING"
        )
        db.commit()
        return {"approval_number": legacy_approval.approval_number, "existing": True}
    open_renewal = db.scalar(
        select(ContractRenewal).where(
            ContractRenewal.contract_id == contract_id,
            ContractRenewal.status.in_(["REQUESTED", "APPROVED"]),
        )
    )
    if open_renewal:
        raise HTTPException(409, "A renewal request is already open for this contract")
    a = ApprovalRequest(
        approval_number=next_number(
            db, "approval-" + str(date.today().year), f"APR-{date.today().year}-"
        ),
        action_type="CONTRACT_RENEWAL",
        status="PENDING",
        details=f"Renew {c.contract_number}",
        requested_by=user.username,
    )
    db.add(a)
    db.flush()
    db.add(
        ContractRenewal(
            contract_id=c.id,
            approval_id=a.id,
            status="REQUESTED",
        )
    )
    c.status = "RENEWAL_PENDING"
    db.commit()
    return {"approval_number": a.approval_number}


@api.post("/contracts/{contract_id}/complete-renewal")
def complete_contract_renewal(
    contract_id: int,
    data: ContractRenewalInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    contract = db.get(ServiceContract, contract_id)
    if not contract:
        raise HTTPException(404, "Contract not found")
    renewal = db.scalar(
        select(ContractRenewal)
        .where(
            ContractRenewal.contract_id == contract_id,
            ContractRenewal.status == "APPROVED",
        )
        .order_by(ContractRenewal.created_at.desc())
    )
    if not renewal:
        raise HTTPException(409, "An approved renewal request is required")
    if data.end_date <= data.start_date:
        raise HTTPException(422, "Renewal end date must be after start date")
    renewal.old_start_date = contract.start_date
    renewal.old_end_date = contract.end_date
    renewal.old_value = contract.value
    renewal.new_start_date = data.start_date
    renewal.new_end_date = data.end_date
    renewal.new_value = data.value
    renewal.reference_number = data.reference_number
    renewal.document_path = data.document_path
    renewal.notes = data.notes
    renewal.renewed_by = user.username
    renewal.renewed_at = now_ist()
    renewal.status = "COMPLETED"
    contract.start_date = data.start_date
    contract.end_date = data.end_date
    contract.value = data.value
    contract.reference_number = data.reference_number
    contract.notes = data.notes
    contract.status = "ACTIVE"
    db.add(
        AuditLog(
            actor=user.username,
            entity_type="contract",
            entity_id=str(contract.id),
            action="CONTRACT_RENEWED",
            metadata_text=f"{contract.contract_number} renewed through {data.end_date}",
        )
    )
    db.commit()
    return {"ok": True, "contract_number": contract.contract_number}


@api.post("/movements")
def movement(
    data: MovementInput,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    a = get_asset(db, data.asset_id)
    m = ExternalMovement(
        gate_pass_number=next_number(
            db, "gate-" + str(date.today().year), f"GP-{date.today().year}-"
        ),
        **data.model_dump(),
    )
    db.add(m)
    a.operational_status = "OUTSIDE"
    event(db, a.id, "EXTERNAL_MOVEMENT", f"Gate pass {m.gate_pass_number}")
    db.commit()
    db.refresh(m)
    return {"id": m.id, "gate_pass_number": m.gate_pass_number}


@api.get("/movements")
def movements(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    return [
        {
            "id": m.id,
            "gate_pass_number": m.gate_pass_number,
            "asset": get_asset(db, m.asset_id).asset_code,
            "destination": m.destination,
            "status": m.status,
            "expected_return": m.expected_return,
        }
        for m in db.scalars(
            select(ExternalMovement).order_by(ExternalMovement.sent_at.desc())
        ).all()
    ]


@api.post("/movements/{movement_id}/return")
def movement_return(
    movement_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager")),
):
    m = db.get(ExternalMovement, movement_id)
    if not m:
        raise HTTPException(404, "Movement not found")
    m.returned_at = now_ist()
    m.status = "RETURNED"
    a = get_asset(db, m.asset_id)
    a.operational_status = "OPERATIONAL"
    event(db, a.id, "EXTERNAL_RETURN", f"Returned from gate pass {m.gate_pass_number}")
    db.commit()
    return {"ok": True}


@api.get("/dashboard")
def dashboard(db: Session = Depends(get_db), user=Depends(current_user)):
    total = db.scalar(select(func.count()).select_from(Asset))
    open_t = db.scalar(
        select(func.count())
        .select_from(ServiceTicket)
        .where(ServiceTicket.status.not_in(["CLOSED", "CANCELLED"]))
    )
    pm = db.scalar(
        select(func.count())
        .select_from(PMSchedule)
        .where(PMSchedule.next_due <= date.today())
    )
    repeat = db.scalar(
        select(func.count()).select_from(
            select(ServiceTicket.asset_id)
            .group_by(ServiceTicket.asset_id)
            .having(func.count(ServiceTicket.id) >= 2)
            .subquery()
        )
    )
    return {
        "total_assets": total,
        "open_tickets": open_t,
        "pm_due_or_overdue": pm,
        "assets_under_repair": db.scalar(
            select(func.count())
            .select_from(Asset)
            .where(Asset.operational_status == "UNDER_REPAIR")
        ),
        "repeat_breakdown_alerts": repeat,
        "open_alerts": db.scalar(
            select(func.count())
            .select_from(AssetAlert)
            .where(AssetAlert.status == "OPEN")
        ),
    }


@api.get("/alerts")
def alerts(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    return [
        {
            "id": a.id,
            "asset": get_asset(db, a.asset_id).asset_code if a.asset_id else None,
            "type": a.alert_type,
            "message": a.message,
            "due_on": a.due_on,
            "status": a.status,
        }
        for a in db.scalars(
            select(AssetAlert)
            .where(AssetAlert.status == "OPEN")
            .order_by(AssetAlert.due_on)
        ).all()
    ]


@api.get("/reports/summary")
def report_summary(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    repeat = db.execute(
        select(
            ServiceTicket.asset_id,
            func.count(ServiceTicket.id).label("ticket_count"),
            func.coalesce(func.sum(ServiceTicket.downtime_minutes), 0).label(
                "downtime_minutes"
            ),
        )
        .group_by(ServiceTicket.asset_id)
        .having(func.count(ServiceTicket.id) >= 2)
        .order_by(func.count(ServiceTicket.id).desc())
    ).all()
    downtime = db.execute(
        select(
            ServiceTicket.asset_id,
            func.count(ServiceTicket.id).label("ticket_count"),
            func.coalesce(func.sum(ServiceTicket.downtime_minutes), 0).label(
                "downtime_minutes"
            ),
        )
        .group_by(ServiceTicket.asset_id)
        .order_by(func.coalesce(func.sum(ServiceTicket.downtime_minutes), 0).desc())
        .limit(10)
    ).all()
    view = lambda rows: [
        {
            "asset": get_asset(db, row.asset_id).asset_code,
            "ticket_count": row.ticket_count,
            "downtime_minutes": int(row.downtime_minutes or 0),
        }
        for row in rows
    ]
    return {
        "repeat_breakdowns": view(repeat),
        "downtime_by_asset": view(downtime),
        "pm_overdue": [
            {"asset": get_asset(db, s.asset_id).asset_code, "next_due": s.next_due}
            for s in db.scalars(
                select(PMSchedule)
                .where(PMSchedule.next_due < date.today())
                .order_by(PMSchedule.next_due)
            ).all()
        ],
        "calibration_due": [
            {"asset": get_asset(db, s.asset_id).asset_code, "next_due": s.next_due}
            for s in db.scalars(
                select(CalibrationSchedule)
                .where(
                    CalibrationSchedule.next_due <= date.today(),
                    CalibrationSchedule.active.is_(True),
                )
                .order_by(CalibrationSchedule.next_due)
            ).all()
        ],
    }


@api.get("/approvals")
def approvals(
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    return [
        {
            "id": a.id,
            "approval_number": a.approval_number,
            "action_type": a.action_type,
            "status": a.status,
            "details": a.details,
        }
        for a in db.scalars(
            select(ApprovalRequest).order_by(ApprovalRequest.created_at.desc())
        ).all()
    ]


@api.post("/approvals/{approval_id}/approve")
def approve(
    approval_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    a = db.get(ApprovalRequest, approval_id)
    if not a:
        raise HTTPException(404, "Approval not found")
    if a.status != "PENDING":
        raise HTTPException(409, "Approval already decided")
    a.status = "APPROVED"
    a.decided_by = user.username
    a.decided_at = now_ist()
    if a.action_type.startswith("LIFECYCLE_") and a.asset_id:
        asset = get_asset(db, a.asset_id)
        action = a.action_type.removeprefix("LIFECYCLE_")
        asset.lifecycle_state = action
        asset.is_active = False
        asset.operational_status = action
        event(db, asset.id, "LIFECYCLE_" + action, f"Approved {action.lower()}")
    if a.action_type == "CONTRACT_RENEWAL":
        renewal = db.scalar(
            select(ContractRenewal).where(ContractRenewal.approval_id == a.id)
        )
        if not renewal:
            contract_number = (a.details or "").removeprefix("Renew ").strip()
            contract = db.scalar(
                select(ServiceContract).where(
                    ServiceContract.contract_number == contract_number
                )
            )
            if not contract:
                raise HTTPException(409, "Contract renewal record not found")
            renewal = ContractRenewal(
                contract_id=contract.id,
                approval_id=a.id,
                status="APPROVED",
            )
            db.add(renewal)
            db.flush()
        renewal.status = "APPROVED"
        db.get(ServiceContract, renewal.contract_id).status = "RENEWAL_APPROVED"
    db.commit()
    return {"ok": True}


@api.post("/approvals/{approval_id}/reject")
def reject(
    approval_id: int,
    db: Session = Depends(get_db),
    user=Depends(require_roles("Administrator")),
):
    a = db.get(ApprovalRequest, approval_id)
    if not a:
        raise HTTPException(404, "Approval not found")
    if a.status != "PENDING":
        raise HTTPException(409, "Approval already decided")
    a.status = "REJECTED"
    a.decided_by = user.username
    a.decided_at = now_ist()
    if a.action_type == "CONTRACT_RENEWAL":
        renewal = db.scalar(
            select(ContractRenewal).where(ContractRenewal.approval_id == a.id)
        )
        if renewal:
            renewal.status = "REJECTED"
            contract = db.get(ServiceContract, renewal.contract_id)
            contract.status = (
                "ACTIVE" if contract.end_date >= date.today() else "EXPIRED"
            )
    db.commit()
    return {"ok": True}


@api.post("/uploads")
def upload(
    file: UploadFile = File(...),
    folder: str = Form(default="documents"),
    user=Depends(require_roles("Administrator", "Asset Manager", "Technician")),
):
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in {".pdf", ".png", ".jpg", ".jpeg", ".webp", ".mp4"}:
        raise HTTPException(415, "Unsupported file type")
    allowed_folders = {
        "photos",
        "warranty",
        "documents",
        "pm-reports",
        "calibration-certificates",
        "contract-renewals",
    }
    folder_name = folder if folder in allowed_folders else "documents"
    name = f"{uuid.uuid4().hex}{suffix}"
    target_dir = Path(settings.upload_dir) / folder_name
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / name
    with target.open("wb") as out:
        shutil.copyfileobj(file.file, out)
    return {"path": f"{folder_name}/{name}"}


@api.get("/uploads/{filename:path}")
def download_upload(filename: str, user=Depends(current_user)):
    requested = Path(filename)
    if requested.is_absolute() or ".." in requested.parts:
        raise HTTPException(404, "File not found")
    target = Path(settings.upload_dir) / requested
    if not target.is_file():
        raise HTTPException(404, "File not found")
    return FileResponse(target, filename=requested.name)


public = APIRouter()


@public.get("/q/{token}/page", response_class=HTMLResponse)
def qr_page(token: str):
    return HTMLResponse(
        f"""<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><title>Asset details</title><style>body{{font-family:Arial;margin:20px;color:#16343a;background:#f5f9f8}}h1{{color:#054e5d;margin-bottom:3px}}button{{background:#057083;color:white;border:0;padding:14px;border-radius:7px;width:100%;font-size:16px;font-weight:bold}}.card{{background:white;padding:16px;border:1px solid #d8e5e3;border-radius:10px;margin:12px 0}}.row{{padding:8px 0;border-bottom:1px solid #edf2f1}}.row:last-child{{border:0}}.label{{color:#658187;font-size:12px;display:block}}</style><main id="app">Loading asset...</main><script>const app=document.querySelector('#app'),base=window.location.pathname.replace(/\\/page\\/?$/,''),add=(parent,label,value)=>{{const row=document.createElement('div');row.className='row';const l=document.createElement('span');l.className='label';l.textContent=label;const v=document.createElement('b');v.textContent=value||'Not recorded';row.append(l,v);parent.append(row)}};fetch(base).then(r=>{{if(!r.ok)throw Error();return r.json()}}).then(a=>{{app.replaceChildren();const h=document.createElement('h1');h.textContent=a.asset_code;const subtitle=document.createElement('p');subtitle.textContent=a.asset_name;const card=document.createElement('section');card.className='card';[['Category / type',`${{a.category}} / ${{a.type}}`],['Make / model',`${{a.make||''}} ${{a.model||''}}`],['Serial number',a.serial_number],['Criticality',a.criticality],['Current location',a.location],['Staff in-charge',a.staff_incharge],['Issued to',a.issued_to],['Operational status',a.operational_status],['Warranty ends',a.warranty_end],['PM required',a.pm_required?'Yes':'No'],['Calibration',a.calibration_mode]].forEach(x=>add(card,x[0],x[1]));const contacts=document.createElement('section');contacts.className='card';const ct=document.createElement('b');ct.textContent='Service contacts';contacts.append(ct);(a.service_contacts||[]).forEach(c=>add(contacts,c.name,c.mobile));const history=document.createElement('section');history.className='card';const ht=document.createElement('b');ht.textContent='Recent service history';history.append(ht);(a.service_history||[]).forEach(s=>add(history,`${{s.ticket_number}} · ${{s.status}}`,s.complaint));const report=document.createElement('button');report.textContent='REPORT PROBLEM';report.onclick=()=>{{const complaint=prompt('Describe the problem');if(complaint)fetch(base+'/report-problem',{{method:'POST',headers:{{'Content-Type':'application/json'}},body:JSON.stringify({{asset_id:a.id,complaint}})}}).then(r=>{{if(!r.ok)throw Error();alert('Problem reported')}}).catch(()=>alert('Could not report problem'))}};app.append(h,subtitle,card,contacts,history,report)}}).catch(()=>app.textContent='Asset not found')</script>"""
    )


@public.get("/q/{token}/photo")
def qr_photo(token: str, db: Session = Depends(get_db)):
    a = db.scalar(select(Asset).where(Asset.public_token == token))
    if not a or not a.primary_photo_path:
        raise HTTPException(404, "Photo not found")
    target = Path(settings.upload_dir) / a.primary_photo_path
    if not target.is_file():
        raise HTTPException(404, "Photo not found")
    return FileResponse(target)


@public.get("/q/{token}")
def qr_asset(token: str, db: Session = Depends(get_db)):
    a = db.scalar(select(Asset).where(Asset.public_token == token))
    if not a:
        raise HTTPException(404, "Asset not found")
    result = asset_view(db, a, public=True)
    result["photo_url"] = f"{settings.asset_base_path.rstrip('/')}/q/{token}/photo" if a.primary_photo_path else None
    result["service_contacts"] = [
        {
            "name": db.get(ServiceContact, x.contact_id).name,
            "mobile": db.get(ServiceContact, x.contact_id).mobile,
        }
        for x in db.scalars(
            select(AssetServiceContact).where(AssetServiceContact.asset_id == a.id)
        ).all()
    ]
    result["service_history"] = [
        {
            "ticket_number": t.ticket_number,
            "status": t.status,
            "complaint": t.complaint,
            "reported_at": t.reported_at,
        }
        for t in db.scalars(
            select(ServiceTicket)
            .where(ServiceTicket.asset_id == a.id)
            .order_by(ServiceTicket.reported_at.desc())
            .limit(10)
        ).all()
    ]
    return result


@public.post("/q/{token}/report-problem")
def qr_report(token: str, data: TicketInput, db: Session = Depends(get_db)):
    a = db.scalar(select(Asset).where(Asset.public_token == token))
    if not a or data.asset_id != a.id:
        raise HTTPException(404, "Asset not found")
    t = ServiceTicket(
        ticket_number=next_number(
            db, "ticket-" + str(date.today().year), f"SRV-{date.today().year}-"
        ),
        asset_id=a.id,
        complaint=data.complaint,
        priority=data.priority or "Normal",
        reported_by=data.reported_by or "QR visitor",
    )
    db.add(t)
    db.flush()
    ticket_event(db, t, "REPORTED", data.complaint)
    a.operational_status = "UNDER_REPAIR"
    event(db, a.id, "BREAKDOWN_REPORTED", f"{t.ticket_number}: {data.complaint}")
    db.commit()
    return {"ticket_number": t.ticket_number}

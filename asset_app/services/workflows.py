from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import HTTPException
from asset_app.core.timezone import now_ist
from asset_app.models import *


def next_number(db: Session, key: str, prefix: str, padding: int = 6) -> str:
    # SELECT FOR UPDATE makes this safe on MySQL; SQLite serializes writers in local mode.
    seq = db.execute(
        select(NumberSequence).where(NumberSequence.key == key).with_for_update()
    ).scalar_one_or_none()
    if not seq:
        seq = NumberSequence(key=key, value=0)
        db.add(seq)
        db.flush()
    seq.value += 1
    number = str(seq.value).zfill(padding) if padding else str(seq.value)
    return f"{prefix}{number}"


def next_asset_code(db: Session, category_id: int) -> str:
    return next_number(
        db,
        key=f"asset-category-{category_id}",
        prefix=f"DBL-{category_id}-",
        padding=0,
    )


def event(db, asset_id, event_type, message):
    db.add(AssetEvent(asset_id=asset_id, event_type=event_type, message=message))
    db.add(
        AuditLog(
            entity_type="asset",
            entity_id=str(asset_id),
            action=event_type,
            metadata_text=message,
        )
    )


def transfer(
    db: Session,
    asset: Asset,
    site_id: int,
    floor_id: int | None,
    department_id: int | None,
    workstation_id: int | None,
):
    now = now_ist()
    old = db.execute(
        select(AssetLocationHistory)
        .where(
            AssetLocationHistory.asset_id == asset.id,
            AssetLocationHistory.ended_at.is_(None),
        )
        .with_for_update()
    ).scalar_one_or_none()
    if old:
        old.ended_at = now
    db.add(
        AssetLocationHistory(
            asset_id=asset.id,
            site_id=site_id,
            floor_id=floor_id,
            department_id=department_id,
            workstation_id=workstation_id,
            started_at=now,
        )
    )
    (
        asset.current_site_id,
        asset.current_floor_id,
        asset.current_department_id,
        asset.current_workstation_id,
    ) = (site_id, floor_id, department_id, workstation_id)
    event(db, asset.id, "LOCATION_TRANSFER", "Location changed")


def change_incharge(db: Session, asset: Asset, employee_id: int):
    now = now_ist()
    old = db.execute(
        select(AssetInchargeHistory)
        .where(
            AssetInchargeHistory.asset_id == asset.id,
            AssetInchargeHistory.ended_at.is_(None),
        )
        .with_for_update()
    ).scalar_one_or_none()
    if old:
        old.ended_at = now
    db.add(
        AssetInchargeHistory(asset_id=asset.id, employee_id=employee_id, started_at=now)
    )
    asset.staff_incharge_employee_id = employee_id
    event(db, asset.id, "INCHARGE_CHANGE", "Staff in-charge changed")


def ticket_event(db, ticket, event_type, notes=None):
    db.add(ServiceTicketEvent(ticket_id=ticket.id, event_type=event_type, notes=notes))


def ticket_transition(
    db: Session, ticket: ServiceTicket, action: str, notes: str | None = None, **kwargs
):
    mapping = {
        "assign": "ASSIGNED",
        "start-inspection": "INSPECTION",
        "escalate": "AWAITING_VENDOR",
        "start-repair": "UNDER_REPAIR",
        "restore": "RESTORED",
        "close": "CLOSED",
        "cancel": "CANCELLED",
    }
    if action not in mapping:
        raise HTTPException(400, "Unknown action")
    if ticket.status in ("CLOSED", "CANCELLED"):
        raise HTTPException(409, "Ticket already finalised")
    if action == "close" and not ticket.restored_at:
        raise HTTPException(400, "Restore asset before closing")
    ticket.status = mapping[action]
    for k, v in kwargs.items():
        if v is not None:
            setattr(ticket, k, v)
    if action == "escalate":
        ticket.resolution_path = "EXTERNAL"
    if action == "restore":
        ticket.restored_at = now_ist()
        ticket.downtime_minutes = max(
            0, int((ticket.restored_at - ticket.reported_at).total_seconds() // 60)
        )
        asset = db.get(Asset, ticket.asset_id)
        asset.operational_status = "OPERATIONAL"
        event(db, asset.id, "ASSET_RESTORED", f"{ticket.ticket_number} restored")
    if action == "close":
        ticket.closed_at = now_ist()
    ticket_event(db, ticket, action.upper(), notes)

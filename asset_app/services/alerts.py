from datetime import date, timedelta
from sqlalchemy import select
from sqlalchemy.orm import Session
from asset_app.models import (
    Asset,
    AssetAlert,
    CalibrationSchedule,
    ExternalMovement,
    PMSchedule,
    ServiceContract,
)


def _open(
    db: Session,
    asset_id: int | None,
    alert_type: str,
    message: str,
    due_on: date | None,
):
    existing = db.scalar(
        select(AssetAlert).where(
            AssetAlert.asset_id == asset_id,
            AssetAlert.alert_type == alert_type,
            AssetAlert.status == "OPEN",
        )
    )
    if existing:
        existing.message = message
        existing.due_on = due_on
    else:
        db.add(
            AssetAlert(
                asset_id=asset_id, alert_type=alert_type, message=message, due_on=due_on
            )
        )


def scan_due_alerts(db: Session):
    today = date.today()
    for schedule in db.scalars(
        select(PMSchedule).where(
            PMSchedule.active.is_(True), PMSchedule.next_due <= today
        )
    ).all():
        asset = db.get(Asset, schedule.asset_id)
        _open(
            db,
            asset.id,
            "PM_OVERDUE" if schedule.next_due < today else "PM_DUE",
            f"{asset.asset_code} PM due {schedule.next_due}",
            schedule.next_due,
        )
    for schedule in db.scalars(
        select(CalibrationSchedule).where(
            CalibrationSchedule.active.is_(True), CalibrationSchedule.next_due <= today
        )
    ).all():
        asset = db.get(Asset, schedule.asset_id)
        _open(
            db,
            asset.id,
            "CALIBRATION_OVERDUE" if schedule.next_due < today else "CALIBRATION_DUE",
            f"{asset.asset_code} calibration due {schedule.next_due}",
            schedule.next_due,
        )
    for movement in db.scalars(
        select(ExternalMovement).where(
            ExternalMovement.status == "OUTSIDE",
            ExternalMovement.expected_return.is_not(None),
            ExternalMovement.expected_return < today,
        )
    ).all():
        asset = db.get(Asset, movement.asset_id)
        _open(
            db,
            asset.id,
            "GATE_PASS_OVERDUE",
            f"{asset.asset_code} gate pass {movement.gate_pass_number} overdue",
            movement.expected_return,
        )
    for contract in db.scalars(
        select(ServiceContract).where(
            ServiceContract.status == "ACTIVE",
            ServiceContract.end_date <= today + timedelta(days=30),
        )
    ).all():
        _open(
            db,
            None,
            "CONTRACT_EXPIRY",
            f"{contract.contract_number} expires {contract.end_date}",
            contract.end_date,
        )
    db.commit()

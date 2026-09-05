from __future__ import annotations
from datetime import datetime, date
from decimal import Decimal
from sqlalchemy import (
    String,
    Text,
    Boolean,
    DateTime,
    Date,
    Integer,
    BigInteger,
    ForeignKey,
    Numeric,
    UniqueConstraint,
    Index,
    Enum,
    text,
)
from sqlalchemy.dialects.mysql import TIMESTAMP
from sqlalchemy.orm import Mapped, mapped_column, relationship

IdType = BigInteger().with_variant(Integer, "sqlite")
from .base import Base, Timestamped
from asset_app.core.timezone import now_ist


class Role(Base, Timestamped):
    __tablename__ = "roles"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    name: Mapped[str] = mapped_column(String(50), unique=True)
    description: Mapped[str | None] = mapped_column(String(255))


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    contact: Mapped[str] = mapped_column(String(20), nullable=False, unique=True)
    departments: Mapped[str | None] = mapped_column(String(50))
    role_name: Mapped[str] = mapped_column(
        "role", String(50), nullable=False, server_default="employee"
    )
    role_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("roles.id"), nullable=False, server_default="7"
    )
    status: Mapped[str] = mapped_column(
        Enum("Active", "Inactive", name="user_status"),
        nullable=False,
        server_default="Active",
    )
    last_updated: Mapped[datetime] = mapped_column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
    )
    dob: Mapped[str | None] = mapped_column(String(10))
    designation: Mapped[str | None] = mapped_column(String(100))
    department_id: Mapped[int | None] = mapped_column(Integer)
    role: Mapped[Role] = relationship(foreign_keys=[role_id])

    @property
    def username(self) -> str:
        return self.name

    @property
    def is_active(self) -> bool:
        return self.status == "Active"

    @property
    def must_change_password(self) -> bool:
        return False

class MasterBase(Base, Timestamped):
    __abstract__ = True
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    name: Mapped[str] = mapped_column(String(150), unique=True, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class AssetCategory(MasterBase):
    __tablename__ = "asset_categories"


class AssetMake(MasterBase):
    __tablename__ = "asset_makes"


class VendorRole(MasterBase):
    __tablename__ = "vendor_roles"


class Site(MasterBase):
    __tablename__ = "sites"


class AssetType(Base, Timestamped):
    __tablename__ = "asset_types"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    name: Mapped[str] = mapped_column(String(150))
    category_id: Mapped[int] = mapped_column(ForeignKey("asset_categories.id"))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    __table_args__ = (UniqueConstraint("category_id", "name"),)


class Floor(Base, Timestamped):
    __tablename__ = "floors"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    site_id: Mapped[int] = mapped_column(ForeignKey("sites.id"))
    __table_args__ = (UniqueConstraint("site_id", "name"),)


class Department(MasterBase):
    __tablename__ = "departments"
    floor_id: Mapped[int | None] = mapped_column(ForeignKey("floors.id"), nullable=True)


class Workstation(Base, Timestamped):
    __tablename__ = "workstations"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    name: Mapped[str] = mapped_column(String(150))
    department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id"))
    site_id: Mapped[int] = mapped_column(ForeignKey("sites.id"))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class Employee(Base, Timestamped):
    __tablename__ = "employees"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    employee_code: Mapped[str] = mapped_column(String(50), unique=True)
    name: Mapped[str] = mapped_column(String(150))
    department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id"))
    designation: Mapped[str | None] = mapped_column(String(100))
    mobile: Mapped[str | None] = mapped_column(String(30))
    email: Mapped[str | None] = mapped_column(String(150))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class Vendor(Base, Timestamped):
    __tablename__ = "vendors"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    company_name: Mapped[str] = mapped_column(String(200), unique=True)
    address: Mapped[str | None] = mapped_column(Text)
    gstin: Mapped[str | None] = mapped_column(String(30))
    phone: Mapped[str | None] = mapped_column(String(30))
    whatsapp: Mapped[str | None] = mapped_column(String(30))
    email: Mapped[str | None] = mapped_column(String(150))
    notes: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class VendorRoleLink(Base):
    __tablename__ = "vendor_role_links"
    vendor_id: Mapped[int] = mapped_column(ForeignKey("vendors.id"), primary_key=True)
    role_id: Mapped[int] = mapped_column(
        ForeignKey("vendor_roles.id"), primary_key=True
    )


class ServiceContact(Base, Timestamped):
    __tablename__ = "service_contacts"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    vendor_id: Mapped[int | None] = mapped_column(ForeignKey("vendors.id"))
    name: Mapped[str] = mapped_column(String(150))
    designation: Mapped[str | None] = mapped_column(String(100))
    mobile: Mapped[str | None] = mapped_column(String(30))
    alternate_mobile: Mapped[str | None] = mapped_column(String(30))
    whatsapp: Mapped[str | None] = mapped_column(String(30))
    email: Mapped[str | None] = mapped_column(String(150))
    notes: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class NumberSequence(Base):
    __tablename__ = "number_sequences"
    key: Mapped[str] = mapped_column(String(80), primary_key=True)
    value: Mapped[int] = mapped_column(Integer, default=0)


class Asset(Base, Timestamped):
    __tablename__ = "assets"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_code: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    public_token: Mapped[str] = mapped_column(String(96), unique=True, index=True)
    asset_name: Mapped[str] = mapped_column(String(200))
    category_id: Mapped[int] = mapped_column(ForeignKey("asset_categories.id"))
    asset_type_id: Mapped[int] = mapped_column(ForeignKey("asset_types.id"))
    make_id: Mapped[int | None] = mapped_column(ForeignKey("asset_makes.id"))
    model_text: Mapped[str | None] = mapped_column(String(200))
    serial_number: Mapped[str | None] = mapped_column(String(150), index=True)
    criticality: Mapped[str] = mapped_column(String(2), default="C3")
    current_site_id: Mapped[int] = mapped_column(ForeignKey("sites.id"))
    current_floor_id: Mapped[int | None] = mapped_column(ForeignKey("floors.id"))
    current_department_id: Mapped[int | None] = mapped_column(
        ForeignKey("departments.id")
    )
    current_workstation_id: Mapped[int | None] = mapped_column(
        ForeignKey("workstations.id")
    )
    staff_incharge_employee_id: Mapped[int] = mapped_column(ForeignKey("employees.id"))
    issued_to_employee_id: Mapped[int | None] = mapped_column(
        ForeignKey("employees.id")
    )
    primary_service_contact_id: Mapped[int | None] = mapped_column(
        ForeignKey("service_contacts.id")
    )
    holding_class: Mapped[str | None] = mapped_column(String(40))
    operational_status: Mapped[str] = mapped_column(String(40), default="OPERATIONAL")
    lifecycle_state: Mapped[str] = mapped_column(String(40), default="ACTIVE")
    purchase_date: Mapped[date | None] = mapped_column(Date)
    purchase_value: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    invoice_reference: Mapped[str | None] = mapped_column(String(150))
    warranty_start_date: Mapped[date | None] = mapped_column(Date)
    warranty_end_date: Mapped[date | None] = mapped_column(Date)
    warranty_document_path: Mapped[str | None] = mapped_column(String(500))
    useful_life_months: Mapped[int | None] = mapped_column(Integer)
    pm_required: Mapped[bool] = mapped_column(Boolean, default=False)
    pm_period_months: Mapped[int | None] = mapped_column(Integer)
    calibration_mode: Mapped[str] = mapped_column(
        String(30), default="NOT_REQUIRED"
    )
    calibration_period_months: Mapped[int | None] = mapped_column(Integer)
    primary_photo_path: Mapped[str | None] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    __table_args__ = (
        Index(
            "ix_assets_filters", "current_site_id", "operational_status", "criticality"
        ),
    )


class AssetServiceContact(Base):
    __tablename__ = "asset_service_contacts"
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), primary_key=True)
    contact_id: Mapped[int] = mapped_column(
        ForeignKey("service_contacts.id"), primary_key=True
    )
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)


class AssetDocument(Base, Timestamped):
    __tablename__ = "asset_documents"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    document_type: Mapped[str] = mapped_column(String(50))
    file_path: Mapped[str] = mapped_column(String(500))
    title: Mapped[str | None] = mapped_column(String(200))


class AssetLocationHistory(Base, Timestamped):
    __tablename__ = "asset_location_history"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    site_id: Mapped[int] = mapped_column(ForeignKey("sites.id"))
    floor_id: Mapped[int | None] = mapped_column(ForeignKey("floors.id"))
    department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id"))
    workstation_id: Mapped[int | None] = mapped_column(ForeignKey("workstations.id"))
    started_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime)


class AssetInchargeHistory(Base, Timestamped):
    __tablename__ = "asset_incharge_history"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    employee_id: Mapped[int] = mapped_column(ForeignKey("employees.id"))
    started_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime)


class AssetIssueHistory(Base, Timestamped):
    __tablename__ = "asset_issue_history"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    employee_id: Mapped[int] = mapped_column(ForeignKey("employees.id"))
    issued_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)
    issued_by: Mapped[str | None] = mapped_column(String(80))
    issue_condition: Mapped[str | None] = mapped_column(Text)
    details: Mapped[str | None] = mapped_column(Text)
    returned_at: Mapped[datetime | None] = mapped_column(DateTime)
    received_by: Mapped[str | None] = mapped_column(String(80))
    return_condition: Mapped[str | None] = mapped_column(Text)
    remarks: Mapped[str | None] = mapped_column(Text)


class AssetEvent(Base, Timestamped):
    __tablename__ = "asset_events"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    event_type: Mapped[str] = mapped_column(String(60))
    message: Mapped[str] = mapped_column(Text)
    occurred_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)


class ServiceTicket(Base, Timestamped):
    __tablename__ = "service_tickets"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    ticket_number: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    complaint: Mapped[str] = mapped_column(Text)
    priority: Mapped[str] = mapped_column(String(20), default="Normal")
    status: Mapped[str] = mapped_column(String(30), default="REPORTED")
    resolution_path: Mapped[str | None] = mapped_column(String(30))
    reported_by: Mapped[str | None] = mapped_column(String(150))
    reported_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)
    assigned_to: Mapped[str | None] = mapped_column(String(150))
    vendor_id: Mapped[int | None] = mapped_column(ForeignKey("vendors.id"))
    vendor_reference: Mapped[str | None] = mapped_column(String(100))
    restored_at: Mapped[datetime | None] = mapped_column(DateTime)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime)
    downtime_minutes: Mapped[int | None] = mapped_column(Integer)


class ServiceTicketEvent(Base, Timestamped):
    __tablename__ = "service_ticket_events"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    ticket_id: Mapped[int] = mapped_column(ForeignKey("service_tickets.id"), index=True)
    event_type: Mapped[str] = mapped_column(String(60))
    notes: Mapped[str | None] = mapped_column(Text)
    performed_by: Mapped[str | None] = mapped_column(String(150))
    occurred_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)


class ServiceTicketPart(Base, Timestamped):
    __tablename__ = "service_ticket_parts"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    ticket_id: Mapped[int] = mapped_column(ForeignKey("service_tickets.id"))
    description: Mapped[str] = mapped_column(String(250))
    quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    unit_cost: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    remarks: Mapped[str | None] = mapped_column(Text)


class PMSchedule(Base, Timestamped):
    __tablename__ = "pm_schedules"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), unique=True)
    frequency_days: Mapped[int] = mapped_column(Integer)
    next_due: Mapped[date] = mapped_column(Date)
    provider_vendor_id: Mapped[int | None] = mapped_column(ForeignKey("vendors.id"))
    reminder_days: Mapped[int] = mapped_column(Integer, default=7)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class PMRecord(Base, Timestamped):
    __tablename__ = "pm_records"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    schedule_id: Mapped[int] = mapped_column(ForeignKey("pm_schedules.id"))
    completed_at: Mapped[datetime] = mapped_column(DateTime)
    performed_by: Mapped[str] = mapped_column(String(150))
    remarks: Mapped[str] = mapped_column(Text)
    service_report_path: Mapped[str] = mapped_column(String(500))
    cost: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    calibration_performed: Mapped[bool] = mapped_column(Boolean, default=False)
    calibration_result: Mapped[str | None] = mapped_column(String(80))
    calibration_certificate_path: Mapped[str | None] = mapped_column(String(500))


class CalibrationSchedule(Base, Timestamped):
    __tablename__ = "calibration_schedules"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), unique=True)
    frequency_days: Mapped[int] = mapped_column(Integer)
    next_due: Mapped[date] = mapped_column(Date)
    vendor_id: Mapped[int | None] = mapped_column(ForeignKey("vendors.id"))
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class CalibrationRecord(Base, Timestamped):
    __tablename__ = "calibration_records"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    schedule_id: Mapped[int] = mapped_column(
        ForeignKey("calibration_schedules.id"), index=True
    )
    completed_at: Mapped[datetime] = mapped_column(DateTime)
    performed_by: Mapped[str] = mapped_column(String(150))
    result: Mapped[str] = mapped_column(String(80))
    certificate_path: Mapped[str | None] = mapped_column(String(500))
    remarks: Mapped[str | None] = mapped_column(Text)


class ServiceContract(Base, Timestamped):
    __tablename__ = "service_contracts"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    contract_number: Mapped[str] = mapped_column(String(40), unique=True)
    contract_type: Mapped[str] = mapped_column(String(20))
    vendor_id: Mapped[int] = mapped_column(ForeignKey("vendors.id"))
    start_date: Mapped[date] = mapped_column(Date)
    end_date: Mapped[date] = mapped_column(Date)
    value: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    status: Mapped[str] = mapped_column(String(30), default="ACTIVE")
    reference_number: Mapped[str | None] = mapped_column(String(100))
    notes: Mapped[str | None] = mapped_column(Text)


class ServiceContractAsset(Base):
    __tablename__ = "service_contract_assets"
    contract_id: Mapped[int] = mapped_column(
        ForeignKey("service_contracts.id"), primary_key=True
    )
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), primary_key=True)


class ContractRenewal(Base, Timestamped):
    __tablename__ = "contract_renewals"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    contract_id: Mapped[int] = mapped_column(
        ForeignKey("service_contracts.id"), index=True
    )
    approval_id: Mapped[int] = mapped_column(
        ForeignKey("approval_requests.id"), unique=True, index=True
    )
    status: Mapped[str] = mapped_column(String(30), default="REQUESTED")
    old_start_date: Mapped[date | None] = mapped_column(Date)
    old_end_date: Mapped[date | None] = mapped_column(Date)
    new_start_date: Mapped[date | None] = mapped_column(Date)
    new_end_date: Mapped[date | None] = mapped_column(Date)
    old_value: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    new_value: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    reference_number: Mapped[str | None] = mapped_column(String(100))
    document_path: Mapped[str | None] = mapped_column(String(500))
    notes: Mapped[str | None] = mapped_column(Text)
    renewed_by: Mapped[str | None] = mapped_column(String(80))
    renewed_at: Mapped[datetime | None] = mapped_column(DateTime)


class ExternalMovement(Base, Timestamped):
    __tablename__ = "external_movements"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    gate_pass_number: Mapped[str] = mapped_column(String(40), unique=True)
    asset_id: Mapped[int] = mapped_column(ForeignKey("assets.id"), index=True)
    movement_type: Mapped[str] = mapped_column(String(30))
    destination: Mapped[str] = mapped_column(String(200))
    vendor_id: Mapped[int | None] = mapped_column(ForeignKey("vendors.id"))
    sent_at: Mapped[datetime] = mapped_column(DateTime, default=now_ist)
    expected_return: Mapped[date | None] = mapped_column(Date)
    returned_at: Mapped[datetime | None] = mapped_column(DateTime)
    status: Mapped[str] = mapped_column(String(30), default="OUTSIDE")
    remarks: Mapped[str | None] = mapped_column(Text)


class ApprovalRequest(Base, Timestamped):
    __tablename__ = "approval_requests"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    approval_number: Mapped[str] = mapped_column(String(40), unique=True)
    action_type: Mapped[str] = mapped_column(String(50))
    asset_id: Mapped[int | None] = mapped_column(ForeignKey("assets.id"))
    status: Mapped[str] = mapped_column(String(20), default="PENDING")
    details: Mapped[str | None] = mapped_column(Text)
    requested_by: Mapped[str | None] = mapped_column(String(80))
    decided_by: Mapped[str | None] = mapped_column(String(80))
    decided_at: Mapped[datetime | None] = mapped_column(DateTime)


class AuditLog(Base, Timestamped):
    __tablename__ = "audit_logs"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    actor: Mapped[str | None] = mapped_column(String(80))
    entity_type: Mapped[str] = mapped_column(String(50))
    entity_id: Mapped[str] = mapped_column(String(80))
    action: Mapped[str] = mapped_column(String(80))
    metadata_text: Mapped[str | None] = mapped_column(Text)


class AssetAlert(Base, Timestamped):
    __tablename__ = "asset_alerts"
    id: Mapped[int] = mapped_column(IdType, primary_key=True)
    asset_id: Mapped[int | None] = mapped_column(ForeignKey("assets.id"), index=True)
    alert_type: Mapped[str] = mapped_column(String(60), index=True)
    message: Mapped[str] = mapped_column(Text)
    due_on: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(20), default="OPEN", index=True)

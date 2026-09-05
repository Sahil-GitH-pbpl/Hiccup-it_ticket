from datetime import date, datetime
from decimal import Decimal
from pydantic import BaseModel, Field


class LoginInput(BaseModel):
    username: str
    contact: str | None = None
    password: str | None = None


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    username: str
    role: str


class UserRoleUpdate(BaseModel):
    role_id: int


class MasterInput(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    category_id: int | None = None


class MasterUpdateInput(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    category_id: int | None = None
    site_id: int | None = None
    department_id: int | None = None
    vendor_id: int | None = None
    phone: str | None = None
    mobile: str | None = None
    email: str | None = None
    address: str | None = None


class VendorInput(BaseModel):
    company_name: str = Field(min_length=1, max_length=200)
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    notes: str | None = None


class ServiceContactInput(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    vendor_id: int | None = None
    mobile: str | None = None
    email: str | None = None
    designation: str | None = None
    notes: str | None = None


class AssetInput(BaseModel):
    asset_name: str
    category_id: int
    asset_type_id: int
    current_site_id: int
    staff_incharge_employee_id: int
    make_id: int | None = None
    model_text: str | None = None
    serial_number: str | None = None
    criticality: str = "C3"
    current_floor_id: int | None = None
    current_department_id: int | None = None
    current_workstation_id: int | None = None
    issued_to_employee_id: int | None = None
    primary_service_contact_id: int
    service_contact_ids: list[int] = []
    holding_class: str | None = None
    purchase_date: date | None = None
    purchase_value: Decimal | None = None
    invoice_reference: str | None = None
    warranty_start_date: date | None = None
    warranty_end_date: date | None = None
    warranty_document_path: str | None = None
    useful_life_months: int | None = None
    pm_required: bool = False
    pm_period_months: int | None = None
    calibration_mode: str = "NOT_REQUIRED"
    calibration_period_months: int | None = None
    primary_photo_path: str | None = None


class AssetUpdateInput(AssetInput):
    pass


class AssetDocumentInput(BaseModel):
    document_type: str = Field(min_length=1, max_length=50)
    file_path: str = Field(min_length=1, max_length=500)
    title: str | None = None


class WorkstationInput(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    site_id: int
    department_id: int | None = None


class TransferInput(BaseModel):
    site_id: int
    floor_id: int | None = None
    department_id: int | None = None
    workstation_id: int | None = None


class InchargeInput(BaseModel):
    employee_id: int


class IssueInput(BaseModel):
    employee_id: int
    condition: str | None = None
    details: str | None = None


class ReturnInput(BaseModel):
    condition: str | None = None
    remarks: str | None = None


class TicketInput(BaseModel):
    asset_id: int
    complaint: str = Field(min_length=2)
    priority: str | None = None
    reported_by: str | None = None


class TicketAction(BaseModel):
    notes: str | None = None
    assigned_to: str | None = None
    vendor_id: int | None = None
    vendor_reference: str | None = None


class PartInput(BaseModel):
    description: str
    quantity: Decimal = 1
    unit_cost: Decimal | None = None
    remarks: str | None = None


class PMInput(BaseModel):
    asset_id: int
    frequency_days: int = Field(gt=0)
    next_due: date
    provider_vendor_id: int | None = None
    reminder_days: int = 7


class PMCompleteInput(BaseModel):
    completed_at: datetime
    performed_by: str
    next_due: date | None = None
    remarks: str
    service_report_path: str | None = None
    cost: Decimal | None = None
    calibration_performed: bool = False
    calibration_result: str | None = None
    calibration_certificate_path: str | None = None


class CalibrationInput(BaseModel):
    asset_id: int
    frequency_days: int = Field(gt=0)
    next_due: date
    vendor_id: int | None = None


class CalibrationCompleteInput(BaseModel):
    completed_at: datetime
    performed_by: str
    result: str
    certificate_path: str | None = None
    remarks: str | None = None


class ContractInput(BaseModel):
    contract_type: str
    vendor_id: int
    start_date: date
    end_date: date
    value: Decimal | None = None
    reference_number: str | None = None
    notes: str | None = None
    asset_ids: list[int] = []


class ContractRenewalInput(BaseModel):
    start_date: date
    end_date: date
    value: Decimal | None = None
    reference_number: str | None = None
    document_path: str | None = None
    notes: str | None = None


class MovementInput(BaseModel):
    asset_id: int
    movement_type: str = "REPAIR"
    destination: str
    vendor_id: int | None = None
    expected_return: date | None = None
    remarks: str | None = None

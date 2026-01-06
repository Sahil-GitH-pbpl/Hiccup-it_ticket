from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class HiccupCreate(BaseModel):
    hiccup_type: str
    raised_against: Optional[str]
    raised_against_name: Optional[str] = None
    raised_against_department: Optional[int] = None
    raised_against_department_name: Optional[str] = None
    description: str
    immediate_effect: Optional[str] = None
    confidential_flag: bool = False
    root_cause_category: Optional[str] = None


class HiccupResponse(BaseModel):
    hiccup_id: str
    raised_by: int
    raised_by_name: str
    raised_by_department: Optional[int]
    hiccup_type: str
    raised_against: Optional[str]
    raised_against_name: Optional[str]
    raised_against_department: Optional[int]
    description: str
    immediate_effect: Optional[str]
    attachment_path: Optional[str]
    attachments: List[str] = Field(default_factory=list)
    response_by: Optional[int]
    response_text: Optional[str]
    response_by_name: Optional[str]
    status: str
    escalated_by: Optional[int]
    root_cause: Optional[str]
    corrective_action: Optional[str]
    closure_notes: Optional[str]
    closed_at: Optional[datetime]
    is_auto_generated: bool
    source_module: Optional[str]
    confidential_flag: bool
    created_at: datetime
    updated_at: datetime
    followup_status: Optional[str]
    followup_comment: Optional[str]
    root_cause_category: Optional[str]
    is_response_overdue: bool
    is_closure_overdue: bool
    nc_assigned_staff_id: Optional[int] = None
    nc_assigned_staff_name: Optional[str] = None

    class Config:
        orm_mode = True
        from_attributes = True


class RespondRequest(BaseModel):
    response_text: str
    public_token: Optional[str] = None


class NCEscalationFormPayload(BaseModel):
    staff_name: str
    staff_id: Optional[int] = None
    root_cause_flags: Optional[List[str]] = None
    root_cause_other: Optional[str] = None
    corrective_action: Optional[str] = None
    corrective_action_by: Optional[str] = None
    corrective_action_date: Optional[str] = None
    person_responsible: Optional[str] = None
    timeline_for_completion: Optional[str] = None
    preventive_actions: Optional[List[str]] = None
    preventive_other: Optional[str] = None

    class Config:
        extra = "forbid"


class StatusUpdateRequest(BaseModel):
    status: str
    closure_notes: Optional[str] = None
    root_cause: Optional[str] = None
    corrective_action: Optional[str] = None
    root_cause_category: Optional[str] = None
    response_text: Optional[str] = None

    escalation_form: Optional[NCEscalationFormPayload] = None


class NCEscalationFormResponse(BaseModel):
    staff_name: str
    staff_id: Optional[int] = None
    root_cause_flags: List[str] = Field(default_factory=list)
    root_cause_other: Optional[str] = None
    corrective_action: Optional[str] = None
    corrective_action_by: Optional[str] = None
    corrective_action_date: Optional[str] = None
    person_responsible: Optional[str] = None
    timeline_for_completion: Optional[str] = None
    preventive_actions: List[str] = Field(default_factory=list)
    preventive_other: Optional[str] = None


class FollowupRequest(BaseModel):
    followup_status: str
    followup_comment: Optional[str] = None


class AutoGenerateRequest(BaseModel):
    source_module: str
    hiccup_type: str
    raised_against: str
    description: str
    immediate_effect: Optional[str] = None


class AuditLogEntry(BaseModel):
    action: str
    performed_by: int
    performed_by_name: Optional[str] = None
    timestamp: datetime
    remarks: Optional[str]

    class Config:
        orm_mode = True

import json
from datetime import datetime
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    Index,
    text,
)
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.utils.time_utils import now_local


class Hiccup(Base):
    __tablename__ = "hiccups"

    hiccup_id = Column(String(20), primary_key=True)
    raised_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    raised_by_name = Column(String(150), nullable=False)
    raised_by_department = Column(
        Integer, ForeignKey("department_master.id"), nullable=True
    )
    hiccup_type = Column(
        Enum("Person Related", "System Related", name="hiccup_type_enum"),
        nullable=False,
    )
    raised_against = Column(String(255), nullable=True)
    raised_against_name = Column(String(150), nullable=True)
    raised_against_department = Column(
        Integer, ForeignKey("department_master.id"), nullable=True
    )
    raised_against_department_name = Column(String(150), nullable=True)
    description = Column(Text, nullable=False)
    immediate_effect = Column(Text, nullable=True)
    attachment_path = Column(String(255), nullable=True)
    response_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    response_by_name = Column(String(150), nullable=True)
    response_text = Column(Text, nullable=True)
    status = Column(
        Enum(
            "Open",
            "Responded",
            "Under Review",
            "Closed",
            "Escalated to NC",
            name="status_enum",
        ),
        nullable=False,
        default="Open",
    )
    escalated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    nc_assigned_staff_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    root_cause = Column(Text, nullable=True)
    corrective_action = Column(Text, nullable=True)
    closure_notes = Column(Text, nullable=True)
    closed_at = Column(DateTime(timezone=True), nullable=True)
    is_auto_generated = Column(Boolean, nullable=False, default=False)
    source_module = Column(String(255), nullable=True)
    confidential_flag = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=now_local)
    updated_at = Column(
        DateTime(timezone=True), nullable=False, default=now_local, onupdate=now_local
    )
    followup_status = Column(
        Enum("Pending", "Resolved", "Unresolved", name="followup_enum"),
        default="Pending",
    )
    followup_comment = Column(Text, nullable=True)
    root_cause_category = Column(
        Enum(
            "Training Need",
            "Process Gap",
            "Negligence",
            "System Error",
            "External Factor",
            "Resource Shortage",
            name="root_cause_enum",
        ),
        nullable=True,
    )
    is_response_overdue = Column(Boolean, default=False)
    response_blocked = Column(
        Boolean, nullable=False, server_default=text("0"), default=False
    )
    reminder_sent = Column(
        Boolean, nullable=False, server_default=text("0"), default=False
    )
    overdue_msg_sent = Column(
        Boolean, nullable=False, server_default=text("0"), default=False
    )
    escalate_msg_sent = Column(
        Boolean, nullable=False, server_default=text("0"), default=False
    )
    is_closure_overdue = Column(Boolean, default=False)

    audit_logs = relationship(
        "HiccupAuditLog", back_populates="hiccup", cascade="all, delete-orphan"
    )

    nc_escalation_form = relationship(
        "NCEscalationForm", back_populates="hiccup", uselist=False
    )

    @property
    def attachments(self):
        raw = self.attachment_path
        if not raw:
            return []
        try:
            decoded = json.loads(raw)
            if isinstance(decoded, list):
                return [str(item) for item in decoded if str(item).strip()]
        except json.JSONDecodeError:
            pass
        if isinstance(raw, str):
            trimmed = raw.strip()
            return [trimmed] if trimmed else []
        return []


Index("idx_hiccups_status_created", Hiccup.status, Hiccup.created_at)
Index("idx_hiccups_raised_by", Hiccup.raised_by)
Index("idx_hiccups_raised_against", Hiccup.raised_against)
Index("idx_hiccups_source", Hiccup.source_module)
Index("idx_hiccups_nc_assigned", Hiccup.nc_assigned_staff_id)


class HiccupAuditLog(Base):
    __tablename__ = "hiccup_audit_log"

    log_id = Column(Integer, primary_key=True, autoincrement=True)
    hiccup_id = Column(String(20), ForeignKey("hiccups.hiccup_id"), nullable=False)
    action = Column(String(50), nullable=False)
    performed_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    timestamp = Column(DateTime(timezone=True), nullable=False, default=now_local)
    remarks = Column(Text, nullable=True)

    hiccup = relationship("Hiccup", back_populates="audit_logs")

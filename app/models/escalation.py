from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.utils.time_utils import now_local


class NCEscalationForm(Base):
    __tablename__ = "nc_escalation_forms"

    id = Column(Integer, primary_key=True, autoincrement=True)
    hiccup_id = Column(String(20), ForeignKey("hiccups.hiccup_id"), nullable=False, unique=True)
    staff_name = Column(String(200), nullable=True)
    assigned_staff_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    nc_note = Column(Text, nullable=True)
    issue_description = Column(Text, nullable=True)
    root_cause_flags = Column(Text, nullable=True)
    root_cause_explanation = Column(Text, nullable=True)
    root_cause_other = Column(Text, nullable=True)
    corrective_action = Column(Text, nullable=True)
    corrective_action_by = Column(String(200), nullable=True)
    corrective_action_date = Column(Date, nullable=True)
    person_responsible = Column(String(200), nullable=True)
    timeline_for_completion = Column(String(200), nullable=True)
    preventive_actions = Column(Text, nullable=True)
    preventive_other = Column(Text, nullable=True)
    preventive_details = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=now_local)
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=now_local,
        onupdate=now_local,
    )

    hiccup = relationship("Hiccup", back_populates="nc_escalation_form", uselist=False)

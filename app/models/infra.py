from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.utils.time_utils import now_local_naive


class InfraTicket(Base):
    __tablename__ = "infra_tickets"

    ticket_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    created_by = Column(String(150), nullable=False)          # user name
    department = Column(String(100), nullable=False)          # department/location
    category = Column(String(50), nullable=False)             # Hardware/Software/Office Infra/Other
    subcategory = Column(String(100), nullable=False)         # based on category
    description = Column(Text, nullable=False)                # issue description
    workstation = Column(String(50))                          # optional desk/workstation
    status = Column(String(20), nullable=False, default="New")
    assigned_to = Column(String(150))                         # IT staff (future)
    commitment_time = Column(DateTime)                        # promise time
    is_delayed_pick = Column(Boolean, nullable=False, default=False)
    is_invalid = Column(Boolean, nullable=False, default=False)
    invalid_reason = Column(Text)
    image_path = Column(String(255))                          # uploaded photo path
    contact = Column(String(20))                              # requester phone for WA updates
    created_at = Column(DateTime, default=now_local_naive, nullable=False)
    updated_at = Column(DateTime, default=now_local_naive, onupdate=now_local_naive, nullable=False)
    reminder_sent = Column(Boolean, nullable=False, default=False)
    pick_sla_deadline_at = Column(DateTime)
    auto_hiccup_generated = Column(Boolean, nullable=False, default=False)
    auto_hiccup_id = Column(String(255))
    auto_hiccup_generated_at = Column(DateTime)
    resolve_sla_hiccup_generated = Column(Boolean, nullable=False, default=False)
    resolve_sla_hiccup_id = Column(String(255))
    resolve_sla_hiccup_generated_at = Column(DateTime)

    images = relationship(
        "InfraTicketImage",
        back_populates="ticket",
        cascade="all, delete-orphan",
    )
    updates = relationship(
        "InfraUpdate",
        back_populates="ticket",
        cascade="all, delete-orphan",
    )


class InfraTicketImage(Base):
    __tablename__ = "infra_ticket_images"

    image_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ticket_id = Column(
        Integer, ForeignKey("infra_tickets.ticket_id"), nullable=False, index=True
    )
    image_path = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=now_local_naive, nullable=False)

    ticket = relationship("InfraTicket", back_populates="images")


class InfraUpdate(Base):
    __tablename__ = "infra_updates"

    update_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ticket_id = Column(
        Integer, ForeignKey("infra_tickets.ticket_id"), nullable=False, index=True
    )
    note = Column(Text, nullable=False)
    created_by = Column(String(150), nullable=False)
    created_at = Column(DateTime, default=now_local_naive, nullable=False)

    ticket = relationship("InfraTicket", back_populates="updates")


Index("idx_infra_tickets_status_created", InfraTicket.status, InfraTicket.created_at)
Index("idx_infra_tickets_created_by", InfraTicket.created_by)
Index("idx_infra_tickets_assigned_to", InfraTicket.assigned_to)
Index("idx_infra_tickets_department", InfraTicket.department)
Index("idx_infra_tickets_category", InfraTicket.category)
Index("idx_infra_tickets_delayed", InfraTicket.is_delayed_pick)
Index("idx_infra_tickets_auto_hiccup", InfraTicket.auto_hiccup_generated, InfraTicket.pick_sla_deadline_at)
Index("idx_infra_tickets_resolve_sla_hiccup", InfraTicket.resolve_sla_hiccup_generated, InfraTicket.commitment_time)

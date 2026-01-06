from sqlalchemy import (
    Column,
    Integer,
    String,
    TIMESTAMP,
    Text,
    DateTime,
    Boolean,
    func,
    ForeignKey,
)
from sqlalchemy.orm import relationship

from .database import Base
from app.utils.timezone import now_ist_naive


class User(Base):
    __tablename__ = "users"  # existing table

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False, index=True)
    password = Column(String(255), nullable=False)
    contact = Column(String(20), unique=True, nullable=False)
    departments = Column(String(50))
    role = Column(String(50), nullable=False, default="staff_user")
    status = Column(String(8), nullable=False, default="Active")
    last_updated = Column(TIMESTAMP, nullable=False)
    dob = Column(String(10))  # stored like "14/04/2000"
    designation = Column(String(100))


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
    commitment_time = Column(DateTime)                        # future
    is_delayed_pick = Column(Boolean, nullable=False, default=False)
    is_invalid = Column(Boolean, nullable=False, default=False)
    invalid_reason = Column(Text)
    image_path = Column(String(255))                          # uploaded photo path
    contact = Column(String(20))                              # requester phone for WA updates
    created_at = Column(DateTime, default=now_ist_naive, nullable=False)
    updated_at = Column(DateTime, default=now_ist_naive, onupdate=now_ist_naive, nullable=False)
    reminder_sent = Column(Boolean, nullable=False, default=False)
    images = relationship(
        "InfraTicketImage",
        back_populates="ticket",
        cascade="all, delete-orphan",
    )


class InfraTicketImage(Base):
    __tablename__ = "infra_ticket_images"

    image_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ticket_id = Column(Integer, ForeignKey("infra_tickets.ticket_id"), nullable=False, index=True)
    image_path = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=now_ist_naive, nullable=False)

    ticket = relationship("InfraTicket", back_populates="images")


class InfraUpdate(Base):
    __tablename__ = "infra_updates"

    update_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ticket_id = Column(Integer, ForeignKey("infra_tickets.ticket_id"), nullable=False, index=True)
    note = Column(Text, nullable=False)
    created_by = Column(String(150), nullable=False)
    created_at = Column(DateTime, default=now_ist_naive, nullable=False)

    ticket = relationship("InfraTicket", backref="updates")

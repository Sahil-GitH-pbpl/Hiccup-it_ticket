from sqlalchemy import Column, DateTime, Index, Integer, String, Text

from app.db.base import Base
from app.utils.time_utils import now_local_naive


class WhatsAppOutbox(Base):
    __tablename__ = "whatsapp_outbox"

    id = Column(Integer, primary_key=True, autoincrement=True)
    target = Column(String(80), nullable=False)
    message = Column(Text, nullable=False)
    context = Column(String(120))
    status = Column(String(20), nullable=False, default="PENDING")
    attempts = Column(Integer, nullable=False, default=0)
    last_error = Column(Text)
    next_attempt_at = Column(DateTime, nullable=False, default=now_local_naive)
    created_at = Column(DateTime, nullable=False, default=now_local_naive)
    sent_at = Column(DateTime)


Index("idx_whatsapp_outbox_status_next", WhatsAppOutbox.status, WhatsAppOutbox.next_attempt_at)

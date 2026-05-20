from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Index, Integer, String

from app.db.base import Base
from app.utils.time_utils import now_local_naive


class FollowupEntry(Base):
    __tablename__ = "followup_entries"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(150), nullable=False)
    mobile_number = Column(String(10), nullable=False)
    confirmed = Column(Boolean, nullable=False)
    transport = Column(Boolean, nullable=False)
    pincode = Column(String(6), nullable=True)
    vs_to_call = Column(Boolean, nullable=False)
    my_followup = Column(Boolean, nullable=False)
    followup_date = Column(Date, nullable=True)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_by_name = Column(String(150), nullable=True)
    created_at = Column(DateTime, default=now_local_naive, nullable=False)
    updated_at = Column(
        DateTime, default=now_local_naive, onupdate=now_local_naive, nullable=False
    )


Index("idx_followup_entries_created_at", FollowupEntry.created_at)
Index("idx_followup_entries_followup_date", FollowupEntry.followup_date)
Index("idx_followup_entries_created_by", FollowupEntry.created_by_id)
Index("idx_followup_entries_mobile_number", FollowupEntry.mobile_number)

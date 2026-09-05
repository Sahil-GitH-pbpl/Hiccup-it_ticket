from datetime import datetime
from sqlalchemy import DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from asset_app.core.timezone import now_ist


class Base(DeclarativeBase):
    pass


class Timestamped:
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=now_ist, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=now_ist, onupdate=now_ist, nullable=False
    )

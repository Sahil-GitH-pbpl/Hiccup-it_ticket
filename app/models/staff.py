from sqlalchemy import Column, Integer, String, TIMESTAMP, text

from app.db.base import Base


class Staff(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(150), nullable=False)
    password = Column(String(255), nullable=False)
    contact = Column(String(20), nullable=False, unique=True)
    departments = Column(String(50))
    role = Column(String(50), nullable=False, default="staff")
    status = Column(String(10), nullable=False, server_default=text("'Active'"))
    last_updated = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("current_timestamp()"),
        server_onupdate=text("current_timestamp()"),
    )
    dob = Column(String(10))
    designation = Column(String(100))
    department_id = Column(Integer, nullable=True)

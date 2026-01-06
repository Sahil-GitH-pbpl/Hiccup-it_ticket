from sqlalchemy import Column, Integer, String

from app.db.base import Base


class Department(Base):
    __tablename__ = "department_master"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)

from sqlalchemy import Column, Date, DateTime, Index, Integer, String, Text

from app.db.base import Base
from app.utils.time_utils import now_local_naive


class EmployeeGrievance(Base):
    __tablename__ = "employee_grievances"

    grievance_id = Column(Integer, primary_key=True, autoincrement=True)
    employee_id = Column(Integer, nullable=False, index=True)
    employee_name = Column(String(150), nullable=False)
    department = Column(String(100), nullable=True)
    designation = Column(String(100), nullable=True)
    category = Column(String(100), nullable=False)
    staff_ids = Column(Text, nullable=True)
    staff_names = Column(Text, nullable=True)
    description = Column(Text, nullable=False)
    incident_date = Column(Date, nullable=True)
    incident_time = Column(String(10), nullable=True)
    evidence_path = Column(String(255), nullable=True)
    expected_resolution = Column(Text, nullable=False)
    created_at = Column(DateTime, default=now_local_naive, nullable=False)
    updated_at = Column(
        DateTime, default=now_local_naive, onupdate=now_local_naive, nullable=False
    )


Index("idx_employee_grievances_created", EmployeeGrievance.created_at)
Index("idx_employee_grievances_category", EmployeeGrievance.category)

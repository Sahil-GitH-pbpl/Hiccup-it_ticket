from typing import List

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.staff import Staff
from app.models.department import Department


router = APIRouter(prefix="/api/staff", tags=["staff"])


class StaffSuggestion(BaseModel):
    id: int
    name: str
    department_id: int | None = None
    department_name: str | None = None
    designation: str | None = None


class DepartmentSummary(BaseModel):
    id: int
    name: str


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/suggest", response_model=List[StaffSuggestion])
def suggest_staff(q: str | None = None, limit: int = 10, db: Session = Depends(get_db)):
    department_rows = db.query(Department.id, Department.name).all()
    department_map = {dept_id: dept_name for dept_id, dept_name in department_rows}
    query = db.query(Staff.id, Staff.name, Staff.department_id, Staff.departments, Staff.designation)
    if q:
        query = query.filter(Staff.name.ilike(f"%{q}%"))
    results = query.order_by(Staff.name).limit(limit).all()

    def iter_department_ids(primary_id: int | None, extra: str | None):
        if primary_id:
            yield primary_id
        if not extra:
            return
        for part in extra.split(","):
            part = part.strip()
            if not part:
                continue
            try:
                yield int(part)
            except ValueError:
                continue

    suggestions = []
    for staff_id, name, dept_id, dept_list, designation in results:
        resolved_department = None
        for candidate in iter_department_ids(dept_id, dept_list):
            if candidate in department_map:
                resolved_department = candidate
                break
        suggestions.append(
            {
                "id": staff_id,
                "name": name,
                "department_id": resolved_department,
                "department_name": department_map.get(resolved_department),
                "designation": designation,
            }
        )
    return suggestions


@router.get("/departments", response_model=List[DepartmentSummary])
def list_departments(db: Session = Depends(get_db)):
    rows = db.query(Department.id, Department.name).order_by(Department.name).all()
    return [{"id": dept_id, "name": dept_name} for dept_id, dept_name in rows]

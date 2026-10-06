from typing import List

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import func, or_

from app.db.session import MainSessionLocal
from app.models.staff import Staff
from app.models.department import Department
from app.core.cache import cache_get_json, cache_set_json


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
    db = MainSessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/suggest", response_model=List[StaffSuggestion])
def suggest_staff(q: str | None = None, limit: int = 10, db: Session = Depends(get_db)):
    department_rows = db.query(Department.id, Department.name).all()
    department_map = {dept_id: dept_name for dept_id, dept_name in department_rows}
    query = db.query(
        Staff.id, Staff.name, Staff.department_id, Staff.departments, Staff.designation
    ).filter(func.lower(Staff.status) == "active")
    if q:
        ilike = f"%{q}%"
        query = query.filter(
            or_(
                Staff.name.ilike(ilike),
                Staff.designation.ilike(ilike),
                Staff.departments.ilike(ilike),
            )
        )
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
    cache_key = "hiccup:staff:departments:v1"
    cached = cache_get_json(cache_key)
    if cached is not None:
        return cached
    rows = db.query(Department.id, Department.name).order_by(Department.name).all()
    payload = [{"id": dept_id, "name": dept_name} for dept_id, dept_name in rows]
    cache_set_json(cache_key, payload, ttl_seconds=600)
    return payload

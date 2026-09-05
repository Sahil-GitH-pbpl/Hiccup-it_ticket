from sqlalchemy import select
from sqlalchemy.orm import Session

from asset_app.models import (
    AssetCategory,
    AssetMake,
    AssetType,
    Department,
    Floor,
    Role,
    Site,
)


def _named(db: Session, model, name: str, **values):
    record = db.scalar(select(model).where(model.name == name))
    if record is None:
        record = model(name=name, **values)
        db.add(record)
        db.flush()
    elif hasattr(record, "is_active"):
        record.is_active = True
    return record


def seed(db: Session):
    """Ensure required roles and master values without creating demo operations."""
    required_roles = {
        1: ("Administrator", "Complete system access"),
        2: ("Technician", "Service, repair, PM and calibration"),
        3: ("Asset Manager", "Asset lifecycle, contracts and reports"),
        7: ("Employee", "Assigned assets and issue reporting"),
    }
    for role_id, (name, description) in required_roles.items():
        role = db.get(Role, role_id)
        if role is None:
            db.add(Role(id=role_id, name=name, description=description))
        else:
            role.name = name
            role.description = description

    categories = {
        name: _named(db, AssetCategory, name)
        for name in ["IT", "Lab Equipment", "Office Equipment", "Furniture"]
    }
    for name in ["Roche", "Siemens", "Mindray", "Dell", "HP", "Samsung", "Daikin"]:
        _named(db, AssetMake, name)

    sites = {name: _named(db, Site, name) for name in ["GK-1", "Gurgaon"]}
    for name in [
        "Biochemistry",
        "Hematology",
        "Microbiology",
        "Customer Care",
        "IT",
        "Administration",
    ]:
        _named(db, Department, name)

    floor_names = [
        "Basement",
        "Ground Floor",
        "First Floor",
        "Second Floor",
        "Third Floor",
    ]
    for site in sites.values():
        existing = {
            floor.name.casefold()
            for floor in db.scalars(select(Floor).where(Floor.site_id == site.id)).all()
        }
        for name in floor_names:
            if name.casefold() not in existing:
                db.add(Floor(name=name, site_id=site.id))

    type_names = {
        "IT": ["Desktop", "Monitor", "Laptop", "Printer", "UPS"],
        "Lab Equipment": ["Chemistry Analyzer", "Centrifuge", "Microscope"],
        "Office Equipment": ["Air Conditioner", "Microwave"],
        "Furniture": ["Chair", "Workstation", "Cabinet"],
    }
    for category_name, names in type_names.items():
        category = categories[category_name]
        existing = {
            asset_type.name.casefold()
            for asset_type in db.scalars(
                select(AssetType).where(AssetType.category_id == category.id)
            ).all()
        }
        for name in names:
            if name.casefold() not in existing:
                db.add(AssetType(name=name, category_id=category.id))

    db.commit()
"""Run before shared-user deployment; --archive-asset-users after switching backend."""
import argparse
from sqlalchemy import inspect, text

from app.core.config import get_settings
from asset_app.db.session import engine

ROLE_CODES = {1: "administrator", 2: "technician", 3: "asset_manager", 7: "employee"}


def main(archive_asset_users=False):
    schema = get_settings().db_name
    quote = engine.dialect.identifier_preparer.quote_identifier
    users = f"{quote(schema)}.users"
    backup = f"{quote(schema)}.users_roles_before_shared_assets"
    if archive_asset_users:
        with engine.begin() as conn:
            inspector = inspect(conn)
            if "users" in inspector.get_view_names():
                print("Asset users compatibility view already exists")
                return
            if "users" in inspector.get_table_names():
                conn.execute(text("RENAME TABLE users TO users_before_shared_assets"))
            conn.execute(text(
                "CREATE SQL SECURITY INVOKER VIEW users AS SELECT "
                "id,name,password,contact,departments,role,role_id,status,last_updated,"
                f"dob,designation,department_id FROM {users}"
            ))
            print("Archived old asset users; asset users now references the common table via a view")
        return
    with engine.begin() as conn:
        local_users = conn.execute(text("SELECT id, contact, role_id FROM users")).mappings().all()
        for local in local_users:
            shared = conn.execute(
                text(f"SELECT contact FROM {users} WHERE id=:id"), {"id": local["id"]}
            ).scalar_one_or_none()
            if shared != local["contact"] or local["role_id"] not in ROLE_CODES:
                raise RuntimeError(f"Resolve asset user identity/role before migration: {local['id']}")
        columns = {c["name"] for c in inspect(conn).get_columns("users", schema=schema)}
        conn.execute(text(
            f"CREATE TABLE IF NOT EXISTS {backup} "
            "(id INT PRIMARY KEY, role VARCHAR(50) NOT NULL, role_id BIGINT NULL)"
        ))
        old_role_id = "role_id" if "role_id" in columns else "NULL"
        conn.execute(text(
            f"INSERT IGNORE INTO {backup} SELECT id, role, {old_role_id} FROM {users}"
        ))
        if "role_id" not in columns:
            conn.execute(text(f"ALTER TABLE {users} ADD COLUMN role_id BIGINT NOT NULL DEFAULT 7"))
        conn.execute(text(f"ALTER TABLE {users} ALTER COLUMN role SET DEFAULT 'employee'"))

    # DDL above commits in MySQL. Role migration below is one transaction.
    with engine.begin() as conn:
        pending = conn.execute(text(
            f"SELECT id FROM {users} WHERE role NOT IN "
            "('administrator','technician','asset_manager','employee') FOR UPDATE"
        )).scalars().all()
        local_roles = {u["id"]: u["role_id"] for u in local_users}
        initial_roles = {124: 1, 125: 1, 95: 3}
        for user_id in pending:
            role_id = local_roles.get(user_id, initial_roles.get(user_id, 7))
            conn.execute(
                text(f"UPDATE {users} SET role=:role, role_id=:role_id WHERE id=:id"),
                {"id": user_id, "role": ROLE_CODES[role_id], "role_id": role_id},
            )
        print(f"Migrated {len(pending)} users; previous roles preserved in {backup}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive-asset-users", action="store_true")
    main(parser.parse_args().archive_asset_users)

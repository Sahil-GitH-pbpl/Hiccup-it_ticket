import unittest

from fastapi import HTTPException, Response
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from starlette.requests import Request

from app.api.routes_auth import login as hiccup_login
from app.core.security import create_jwt
from app.schemas.auth import LoginRequest
from asset_app.api.routes import update_user_role
from asset_app.core.security import current_user, create_token, require_roles
from asset_app.models import AuditLog, Role, User
from asset_app.schemas.schemas import UserRoleUpdate


class SharedUsersTest(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://")
        schema = User.__table__.schema
        with self.engine.begin() as conn:
            conn.execute(text(f"ATTACH DATABASE ':memory:' AS {schema}"))
            conn.execute(text(f"CREATE TABLE {schema}.users ("
                "id INTEGER PRIMARY KEY, name TEXT, password TEXT, contact TEXT, departments TEXT,"
                "role TEXT, role_id BIGINT, status TEXT, last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                "dob TEXT, designation TEXT, department_id INTEGER)"))
        Role.__table__.create(self.engine)
        AuditLog.__table__.create(self.engine)
        self.db = Session(self.engine)
        self.db.add_all([
            Role(id=1, name="Administrator"), Role(id=2, name="Technician"),
            Role(id=3, name="Asset Manager"), Role(id=7, name="Employee"),
            User(id=11, name="Admin", password="secret", contact="111", role_name="administrator",
                 role_id=1, status="Active", designation="Technical"),
            User(id=12, name="Staff", password="secret", contact="222", role_name="employee",
                 role_id=7, status="Active", designation="Technical"),
        ])
        self.db.commit()

    def tearDown(self):
        self.db.close()
        self.engine.dispose()

    def cookie_request(self, user_id):
        token = create_jwt({"user_id": user_id, "role": "admin", "is_admin_like": True})
        return Request({"type": "http", "headers": [(b"cookie", f"token={token}".encode())]})

    def test_cookie_reads_saved_role_not_admin_token_claim(self):
        user = current_user(self.cookie_request(12), token=None, db=self.db)
        self.assertEqual(user.role.name, "Employee")
        with self.assertRaises(HTTPException) as exc:
            require_roles("Administrator")(user)
        self.assertEqual(exc.exception.status_code, 403)

    def test_role_update_writes_common_table_and_old_token_reads_new_role(self):
        token = create_token(self.db.get(User, 12))
        update_user_role(12, UserRoleUpdate(role_id=2), self.db, self.db.get(User, 11))
        self.db.expire_all()
        user = current_user(self.cookie_request(12), token=token, db=self.db)
        self.assertEqual((user.role_name, user.role_id, user.role.name), ("technician", 2, "Technician"))
        require_roles("Technician")(user)
        self.assertEqual(self.db.execute(text(
            f"SELECT role FROM {User.__table__.schema}.users WHERE id=12"
        )).scalar_one(), "technician")

    def test_inactive_and_missing_users_rejected_without_reactivation(self):
        token = create_token(self.db.get(User, 12))
        self.db.get(User, 12).status = "Inactive"
        self.db.commit()
        for user_id, bearer in [(12, None), (12, token), (999, None)]:
            with self.assertRaises(HTTPException) as exc:
                current_user(self.cookie_request(user_id), token=bearer, db=self.db)
            self.assertEqual(exc.exception.status_code, 401)
        self.assertEqual(self.db.get(User, 12).status, "Inactive")

    def test_asset_administrator_does_not_grant_hiccup_admin(self):
        # The Hiccup login uses the same row but keeps its own allowlist privileges.
        result = hiccup_login(LoginRequest(username="Admin", password="secret"), Response(), self.db)
        self.assertFalse(result.is_admin_like)
        self.assertEqual(result.role, "staff_user")


if __name__ == "__main__":
    unittest.main()

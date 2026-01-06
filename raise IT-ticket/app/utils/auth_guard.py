from fastapi import Request
from fastapi.responses import RedirectResponse


def require_login(request: Request):
    """
    Ensure user is logged in. If not, redirect to /login.
    """
    username = request.session.get("username")
    if not username:
        return RedirectResponse(url="/login", status_code=302)
    return None


def require_admin_designation(request: Request):
    """
    Ensure user designation is Admin/IT. Others are redirected to /my-tickets.
    """
    designation = (request.session.get("designation") or "").lower()
    if designation not in ("admin", "it"):
        return RedirectResponse(url="/my-tickets", status_code=302)
    return None

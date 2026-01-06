from fastapi import FastAPI, Request
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware

from app.database import engine, Base
from app.routers import auth, infra

# -------------------------------
# Create tables
# -------------------------------
Base.metadata.create_all(bind=engine)

# -------------------------------
# FastAPI app
# -------------------------------
app = FastAPI(title="Infra HelpDesk API")

# Session support
app.add_middleware(SessionMiddleware, secret_key="super-secret-change-this")

# Static files (CSS, JS, logo, icons)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# Serve uploaded images
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Routers
app.include_router(auth.router)
app.include_router(infra.router)


# ✅ ROOT: First-time visitors → Login page
@app.get("/")
def root(request: Request):
    username = request.session.get("username")

    # If NOT logged in → always go to login
    if not username:
        return RedirectResponse(url="/login", status_code=302)

    # If logged in ? send them based on designation
    designation = (request.session.get("designation") or "").lower()

    if designation in ("admin", "it"):
        return RedirectResponse(url="/infra/dashboard", status_code=302)

    # Normal staff → create ticket form
    return RedirectResponse(url="/infra/create-form", status_code=302)


@app.get("/health")
def health():
    return {"status": "ok"}


# -------------------------------
# Local dev entrypoint
# -------------------------------
if __name__ == "__main__":
    import uvicorn
    print("Starting FastAPI server...")
    uvicorn.run(
        "main:app",
        host="0.0.0.0",   # 👈 IMPORTANT for Docker
        port=3002,        # 👈 matches docker-compose mapping
        reload=False      # reload=False inside Docker
    )

# app/database.py

import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# -------------------------------
# ENVIRONMENT VARIABLES SUPPORT
# -------------------------------
# Works BOTH on your local PC + Docker.
# If env not found, it falls back to your local settings.

MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_HOST = os.getenv("MYSQL_HOST", "127.0.0.1")
MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
MYSQL_DB = os.getenv("MYSQL_DB", "it_tickets")

MAIN_DB = {
    "host": os.getenv("DB_HOST", "localhost"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "port": os.getenv("DB_PORT", "3306"),
    "database": os.getenv("DB_NAME", "lead_management"),
}

# -------------------------------
# SQLAlchemy connection URL
# Using mysqlconnector (correct driver for your setup)
# -------------------------------
DATABASE_URL = (
    f"mysql+mysqlconnector://{MYSQL_USER}:{MYSQL_PASSWORD}"
    f"@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
)

MAIN_DATABASE_URL = (
    f"mysql+mysqlconnector://{MAIN_DB['user']}:{MAIN_DB['password']}"
    f"@{MAIN_DB['host']}:{MAIN_DB['port']}/{MAIN_DB['database']}"
)

# -------------------------------
# ENGINE + SESSION
# -------------------------------
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,   # auto-check connection
    echo=True             # show SQL logs (turn off in production)
)

main_engine = create_engine(
    MAIN_DATABASE_URL,
    pool_pre_ping=True,
    echo=True
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

MainSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=main_engine
)

Base = declarative_base()

# -------------------------------
# Database Dependency (FastAPI)
# -------------------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_main_db():
    db = MainSessionLocal()
    try:
        yield db
    finally:
        db.close()

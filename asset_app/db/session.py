import re
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker
from asset_app.core.config import settings

database_url = settings.resolved_database_url
connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
engine = create_engine(database_url, pool_pre_ping=True, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

def ensure_database_exists():
    """Create the configured MySQL/MariaDB database before creating its tables."""
    url = make_url(database_url)
    if not url.drivername.startswith(('mysql', 'mariadb')):
        return
    database = url.database
    if not database or not re.fullmatch(r'[A-Za-z0-9_$-]+', database):
        raise RuntimeError('DATABASE_URL must contain a valid database name')
    server_engine = create_engine(
        url.set(database=''),
        pool_pre_ping=True,
        isolation_level='AUTOCOMMIT',
    )
    try:
        with server_engine.connect() as connection:
            connection.execute(
                text(f'CREATE DATABASE IF NOT EXISTS `{database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci')
            )
    finally:
        server_engine.dispose()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

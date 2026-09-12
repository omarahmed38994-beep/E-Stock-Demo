"""
Database connection layer.

DESIGN NOTE (see docs/architecture.md for the full explanation):
This module is the ONLY place that knows how to open a database connection.
Every service/API module imports `get_db` / `SessionLocal` from here.

For the demo, DATABASE_URL points at a local SQLite file. To move to a real
e-Stock / SQL Server deployment later, you only need to change DATABASE_URL
in .env (e.g. to an mssql+pyodbc:// connection string) and, if column types
differ, adjust database/models.py. No analytics/service/API code depends on
SQLite-specific behavior.
"""
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import settings, BASE_DIR

# Resolve sqlite relative paths against the backend/ directory so the demo
# works regardless of the current working directory it's launched from.
db_url = settings.database_url
if db_url.startswith("sqlite:///../"):
    data_path = (BASE_DIR / ".." / db_url.replace("sqlite:///../", "")).resolve()
    data_path.parent.mkdir(parents=True, exist_ok=True)
    db_url = f"sqlite:///{data_path}"

connect_args = {"check_same_thread": False} if db_url.startswith("sqlite") else {}

engine = create_engine(db_url, connect_args=connect_args, future=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)

Base = declarative_base()


def get_db():
    """FastAPI dependency that yields a scoped DB session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

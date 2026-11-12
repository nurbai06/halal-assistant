"""SQLite connection and session handling."""

import os
from collections.abc import Iterator
from pathlib import Path

from fastapi import Request
from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

DEFAULT_DB_PATH = Path(__file__).resolve().parent.parent / "halal_assistant.db"


class Base(DeclarativeBase):
    pass


def default_database_url() -> str:
    """SQLite file next to the backend, or the path in HALAL_DB_PATH."""
    return f"sqlite:///{os.environ.get('HALAL_DB_PATH', DEFAULT_DB_PATH)}"


class Database:
    def __init__(self, url: str) -> None:
        # FastAPI runs sync endpoints in a thread pool, so the connection
        # must be usable from more than one thread.
        self.engine = create_engine(url, connect_args={"check_same_thread": False})

        @event.listens_for(self.engine, "connect")
        def _enable_foreign_keys(connection, _record) -> None:
            connection.execute("PRAGMA foreign_keys=ON")

        self._session_factory = sessionmaker(bind=self.engine, expire_on_commit=False)

    def create_tables(self) -> None:
        Base.metadata.create_all(self.engine)

    def session(self) -> Session:
        return self._session_factory()

    def dispose(self) -> None:
        self.engine.dispose()


def get_db(request: Request) -> Iterator[Session]:
    """FastAPI dependency: one session per request."""
    session = request.app.state.db.session()
    try:
        yield session
    finally:
        session.close()

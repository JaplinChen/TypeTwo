from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import StaticPool

from .config import get_settings


class Base(DeclarativeBase):
    pass


def _connect_args(url: str) -> dict[str, object]:
    if url.startswith("sqlite"):
        return {"check_same_thread": False}
    return {}


_database_url = get_settings().database_url
_engine_kwargs: dict[str, object] = {
    "connect_args": _connect_args(_database_url),
    "pool_pre_ping": True,
}
if _database_url == "sqlite:///:memory:":
    _engine_kwargs["poolclass"] = StaticPool

engine = create_engine(_database_url, **_engine_kwargs)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

from contextlib import asynccontextmanager
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from .config import get_settings, validate_production_settings
from .database import Base, SessionLocal, engine
from .models import User
from .routers import auth, glossary, users
from .security import hash_password


def seed_admin(db: Session) -> None:
    settings = get_settings()
    if not settings.admin_email or not settings.admin_password:
        return
    existing = db.scalar(select(User).where(User.email == settings.admin_email))
    if existing is not None:
        return
    db.add(
        User(
            email=settings.admin_email,
            password_hash=hash_password(settings.admin_password),
            role="admin",
        )
    )
    db.commit()


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    validate_production_settings(settings)
    if settings.auto_create_tables:
        Base.metadata.create_all(bind=engine)
        with SessionLocal() as db:
            seed_admin(db)
    yield


settings = get_settings()

app = FastAPI(title="TypeTwo Glossary API", version="0.1.0", lifespan=lifespan)


@app.middleware("http")
async def add_request_id(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID") or str(uuid4())
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
app.include_router(auth.router)
app.include_router(glossary.router)
app.include_router(users.router)


@app.get("/health")
def health() -> dict[str, object]:
    try:
        with SessionLocal() as db:
            db.execute(text("select 1"))
            migration_revision = current_migration_revision(db)
    except Exception as exc:
        return {"ok": False, "app": "TypeTwo Glossary API", "db": str(exc)}
    return {
        "ok": True,
        "app": "TypeTwo Glossary API",
        "version": app.version,
        "environment": settings.environment,
        "db": "ok",
        "migrationRevision": migration_revision,
    }


def current_migration_revision(db: Session) -> str | None:
    try:
        return db.scalar(text("select version_num from alembic_version limit 1"))
    except Exception:
        return None

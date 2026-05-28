from contextlib import asynccontextmanager

from fastapi import FastAPI
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
    except Exception as exc:
        return {"ok": False, "app": "TypeTwo Glossary API", "db": str(exc)}
    return {
        "ok": True,
        "app": "TypeTwo Glossary API",
        "version": app.version,
        "environment": settings.environment,
        "db": "ok",
    }

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(Text)
    role: Mapped[str] = mapped_column(String(32), default="user")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class GlossaryTerm(Base):
    __tablename__ = "glossary_terms"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    source_text: Mapped[str] = mapped_column(Text)
    target_text: Mapped[str] = mapped_column(Text)
    source_lang: Mapped[str | None] = mapped_column(String(64), nullable=True)
    target_lang: Mapped[str | None] = mapped_column(String(64), nullable=True)
    context_key: Mapped[str] = mapped_column(String(128), default="global", index=True)
    status: Mapped[str] = mapped_column(String(32), default="approved", index=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    created_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )

    creator: Mapped[User | None] = relationship(
        "User", foreign_keys=[created_by], lazy="joined"
    )
    updater: Mapped[User | None] = relationship(
        "User", foreign_keys=[updated_by], lazy="joined"
    )


Index(
    "glossary_terms_unique_active",
    GlossaryTerm.context_key,
    GlossaryTerm.source_text,
    GlossaryTerm.source_lang,
    GlossaryTerm.target_lang,
    unique=True,
    sqlite_where=GlossaryTerm.deleted_at.is_(None),
    postgresql_where=GlossaryTerm.deleted_at.is_(None),
)


class GlossaryTermHistory(Base):
    __tablename__ = "glossary_term_history"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    term_id: Mapped[str] = mapped_column(String(36), index=True)
    source_text: Mapped[str] = mapped_column(Text)
    target_text: Mapped[str] = mapped_column(Text)
    source_lang: Mapped[str | None] = mapped_column(String(64), nullable=True)
    target_lang: Mapped[str | None] = mapped_column(String(64), nullable=True)
    context_key: Mapped[str] = mapped_column(String(128), index=True)
    status: Mapped[str] = mapped_column(String(32), index=True)
    version: Mapped[int] = mapped_column(Integer)
    operation: Mapped[str] = mapped_column(String(32))
    changed_by: Mapped[str | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, index=True
    )

    user: Mapped[User | None] = relationship("User", lazy="joined")

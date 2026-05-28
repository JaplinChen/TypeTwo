import os
import sys
from pathlib import Path

import pytest
from fastapi import HTTPException

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["JWT_SECRET"] = "test-secret-that-is-long-enough-for-hs256"
os.environ["AUTO_CREATE_TABLES"] = "true"

from app.database import Base, SessionLocal, engine
from app.models import GlossaryTerm, GlossaryTermHistory, User
from app.schemas import GlossaryImportRequest, GlossaryTermCreate, GlossaryTermUpdate
from app.security import hash_password
from app.services.glossary_service import (
    create_term_record,
    import_glossary_records,
    soft_delete_term,
    update_term_record,
)


@pytest.fixture(autouse=True)
def reset_db() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def create_user(role: str = "admin") -> User:
    with SessionLocal() as db:
        user = User(
            email=f"{role}@example.com",
            password_hash=hash_password("secret"),
            role=role,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user


def test_create_term_record_sets_pending_for_regular_user() -> None:
    user = create_user("user")
    payload = GlossaryTermCreate(
        sourceText="使用者建議詞",
        targetText="User suggestion",
        status="approved",
    )

    with SessionLocal() as db:
        term = create_term_record(db, payload, user.id, user.role)
        history = db.query(GlossaryTermHistory).filter_by(term_id=term.id).all()

        assert term.status == "pending"
        assert term.version == 1
        assert [item.operation for item in history] == ["create"]


def test_create_term_record_rejects_duplicate_active_term() -> None:
    user = create_user("admin")
    payload = GlossaryTermCreate(sourceText="簽核", targetText="Ký duyệt")

    with SessionLocal() as db:
        create_term_record(db, payload, user.id, user.role)
        with pytest.raises(HTTPException) as exc:
            create_term_record(db, payload, user.id, user.role)

        assert exc.value.status_code == 409


def test_update_term_record_updates_fields_and_history() -> None:
    user = create_user("admin")
    create_payload = GlossaryTermCreate(sourceText="表單", targetText="Biểu mẫu")
    update_payload = GlossaryTermUpdate(targetText="Biểu đơn")

    with SessionLocal() as db:
        term = create_term_record(db, create_payload, user.id, user.role)
        updated = update_term_record(db, term.id, update_payload, user.id)
        history = db.query(GlossaryTermHistory).filter_by(term_id=term.id).all()

        assert updated.target_text == "Biểu đơn"
        assert updated.version == 2
        assert [item.operation for item in history] == ["create", "update"]


def test_import_glossary_records_imports_then_updates_existing_terms() -> None:
    user = create_user("admin")

    with SessionLocal() as db:
        first = import_glossary_records(
            db,
            GlossaryImportRequest(glossary={"申請": "Nộp đơn"}),
            user.id,
        )
        second = import_glossary_records(
            db,
            GlossaryImportRequest(glossary={"申請": "Đăng ký"}),
            user.id,
        )
        term = db.query(GlossaryTerm).filter_by(source_text="申請").one()
        history = db.query(GlossaryTermHistory).filter_by(term_id=term.id).all()

        assert first.imported == 1
        assert first.updated == 0
        assert second.imported == 0
        assert second.updated == 1
        assert term.target_text == "Đăng ký"
        assert [item.operation for item in history] == ["import", "import"]


def test_soft_delete_term_marks_deleted_and_hides_from_active_lookup() -> None:
    user = create_user("admin")
    payload = GlossaryTermCreate(sourceText="待刪除", targetText="Delete me")

    with SessionLocal() as db:
        term = create_term_record(db, payload, user.id, user.role)
        soft_delete_term(db, term.id, user.id)
        deleted = db.get(GlossaryTerm, term.id)
        history = db.query(GlossaryTermHistory).filter_by(term_id=term.id).all()

        assert deleted is not None
        assert deleted.deleted_at is not None
        assert [item.operation for item in history] == ["create", "delete"]

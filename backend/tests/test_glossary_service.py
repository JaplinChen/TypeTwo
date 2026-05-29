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
    preview_import_glossary_records,
    restore_term_from_history,
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


def test_restore_term_from_history_reverts_term_and_records_history() -> None:
    user = create_user("admin")
    create_payload = GlossaryTermCreate(sourceText="表單", targetText="Biểu mẫu")
    update_payload = GlossaryTermUpdate(targetText="Biểu đơn")

    with SessionLocal() as db:
        term = create_term_record(db, create_payload, user.id, user.role)
        original_history = (
            db.query(GlossaryTermHistory)
            .filter_by(term_id=term.id, operation="create")
            .one()
        )
        update_term_record(db, term.id, update_payload, user.id)
        restored = restore_term_from_history(db, term.id, original_history.id, user.id)
        history = db.query(GlossaryTermHistory).filter_by(term_id=term.id).all()

        assert restored.target_text == "Biểu mẫu"
        assert restored.version == 3
        assert [item.operation for item in history] == [
            "create",
            "update",
            "restore",
        ]
        assert history[-1].reason == f"history:{original_history.id}"


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


def test_preview_import_glossary_records_reports_actions_without_writes() -> None:
    user = create_user("admin")

    with SessionLocal() as db:
        import_glossary_records(
            db,
            GlossaryImportRequest(glossary={"申請": "Nộp đơn"}),
            user.id,
        )
        preview = preview_import_glossary_records(
            db,
            GlossaryImportRequest(
                glossary={
                    "申請": "Đăng ký",
                    "新增詞": "New term",
                    "": "Blank source",
                },
                langGlossary={"繁體中文-越南文": {"簽核": "Ký duyệt"}},
            ),
        )
        term = db.query(GlossaryTerm).filter_by(source_text="申請").one()
        imported_terms = db.query(GlossaryTerm).filter_by(source_text="新增詞").all()

        assert preview.imported == 2
        assert preview.updated == 1
        assert preview.unchanged == 0
        assert preview.skipped == 1
        assert [item.action for item in preview.items] == [
            "updated",
            "imported",
            "skipped",
            "imported",
        ]
        assert preview.items[0].currentTargetText == "Nộp đơn"
        assert preview.items[2].message == "原文不可為空"
        assert term.target_text == "Nộp đơn"
        assert imported_terms == []


def test_import_keep_existing_skips_existing_conflicts() -> None:
    user = create_user("admin")

    with SessionLocal() as db:
        import_glossary_records(
            db,
            GlossaryImportRequest(glossary={"申請": "Nộp đơn"}),
            user.id,
        )
        preview = preview_import_glossary_records(
            db,
            GlossaryImportRequest(
                glossary={"申請": "Đăng ký", "新增詞": "New term"},
                conflictStrategy="keepExisting",
            ),
        )
        imported = import_glossary_records(
            db,
            GlossaryImportRequest(
                glossary={"申請": "Đăng ký", "新增詞": "New term"},
                conflictStrategy="keepExisting",
            ),
            user.id,
        )
        existing = db.query(GlossaryTerm).filter_by(source_text="申請").one()
        new_term = db.query(GlossaryTerm).filter_by(source_text="新增詞").one()

        assert preview.imported == 1
        assert preview.updated == 0
        assert preview.skipped == 1
        assert [item.action for item in preview.items] == ["skipped", "imported"]
        assert preview.items[0].message == "已保留既有詞彙"
        assert imported.imported == 1
        assert imported.updated == 0
        assert existing.target_text == "Nộp đơn"
        assert new_term.target_text == "New term"


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

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from ..models import GlossaryTerm, GlossaryTermHistory, utc_now
from ..schemas import (
    ALLOWED_TERM_STATUSES,
    GlossaryBundle,
    GlossaryImportRequest,
    GlossaryImportResponse,
    GlossaryTermCreate,
    GlossaryTermHistoryOut,
    GlossaryTermOut,
    GlossaryTermUpdate,
)


def validate_status_filter(value: str) -> str:
    status_filter = value.strip().lower()
    if status_filter not in ALLOWED_TERM_STATUSES:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "詞彙狀態不合法")
    return status_filter


def active_terms_query() -> Select[tuple[GlossaryTerm]]:
    return select(GlossaryTerm).where(GlossaryTerm.deleted_at.is_(None))


def bundle_from_terms(terms: list[GlossaryTerm]) -> GlossaryBundle:
    global_terms: dict[str, str] = {}
    lang_terms: dict[str, dict[str, str]] = {}
    for term in terms:
        if term.context_key == "global":
            global_terms[term.source_text] = term.target_text
            continue
        lang_terms.setdefault(term.context_key, {})[
            term.source_text
        ] = term.target_text
    return GlossaryBundle(
        glossary=global_terms,
        langGlossary=lang_terms,
        syncedAt=datetime.now(timezone.utc),
    )


def term_out(term: GlossaryTerm) -> GlossaryTermOut:
    return GlossaryTermOut(
        id=term.id,
        sourceText=term.source_text,
        targetText=term.target_text,
        sourceLang=term.source_lang,
        targetLang=term.target_lang,
        contextKey=term.context_key,
        status=term.status,
        version=term.version,
        updatedAt=term.updated_at,
        deletedAt=term.deleted_at,
    )


def history_out(item: GlossaryTermHistory) -> GlossaryTermHistoryOut:
    return GlossaryTermHistoryOut(
        id=item.id,
        termId=item.term_id,
        sourceText=item.source_text,
        targetText=item.target_text,
        sourceLang=item.source_lang,
        targetLang=item.target_lang,
        contextKey=item.context_key,
        status=item.status,
        version=item.version,
        operation=item.operation,
        changedAt=item.changed_at,
    )


def record_history(
    db: Session,
    term: GlossaryTerm,
    operation: str,
    user_id: str | None,
) -> None:
    db.add(
        GlossaryTermHistory(
            term_id=term.id,
            source_text=term.source_text,
            target_text=term.target_text,
            source_lang=term.source_lang,
            target_lang=term.target_lang,
            context_key=term.context_key,
            status=term.status,
            version=term.version,
            operation=operation,
            changed_by=user_id,
            changed_at=term.updated_at,
        )
    )


def find_existing(
    db: Session,
    context_key: str,
    source_text: str,
    source_lang: str | None,
    target_lang: str | None,
) -> GlossaryTerm | None:
    return db.scalar(
        active_terms_query().where(
            GlossaryTerm.context_key == context_key,
            GlossaryTerm.source_text == source_text,
            GlossaryTerm.source_lang == source_lang,
            GlossaryTerm.target_lang == target_lang,
        )
    )


def get_active_term_or_404(db: Session, term_id: str) -> GlossaryTerm:
    term = db.get(GlossaryTerm, term_id)
    if term is None or term.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "找不到詞彙")
    return term


def create_term_record(
    db: Session,
    payload: GlossaryTermCreate,
    user_id: str,
    user_role: str,
) -> GlossaryTerm:
    existing = find_existing(
        db,
        payload.contextKey,
        payload.sourceText,
        payload.sourceLang,
        payload.targetLang,
    )
    if existing is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "詞彙已存在")
    term = GlossaryTerm(
        source_text=payload.sourceText,
        target_text=payload.targetText,
        source_lang=payload.sourceLang,
        target_lang=payload.targetLang,
        context_key=payload.contextKey,
        status=payload.status if user_role in {"admin", "editor"} else "pending",
        created_by=user_id,
        updated_by=user_id,
    )
    db.add(term)
    db.flush()
    record_history(db, term, "create", user_id)
    db.commit()
    db.refresh(term)
    return term


def set_term_status(
    db: Session,
    term_id: str,
    status_value: str,
    operation: str,
    user_id: str,
) -> GlossaryTerm:
    term = get_active_term_or_404(db, term_id)
    term.status = status_value
    term.version += 1
    term.updated_by = user_id
    term.updated_at = utc_now()
    record_history(db, term, operation, user_id)
    db.commit()
    db.refresh(term)
    return term


def soft_delete_term(db: Session, term_id: str, user_id: str) -> None:
    term = get_active_term_or_404(db, term_id)
    term.deleted_at = utc_now()
    term.updated_at = term.deleted_at
    term.updated_by = user_id
    term.version += 1
    record_history(db, term, "delete", user_id)
    db.commit()


def update_term_record(
    db: Session,
    term_id: str,
    payload: GlossaryTermUpdate,
    user_id: str,
) -> GlossaryTerm:
    term = get_active_term_or_404(db, term_id)
    field_map = {
        "sourceText": "source_text",
        "targetText": "target_text",
        "sourceLang": "source_lang",
        "targetLang": "target_lang",
        "contextKey": "context_key",
        "status": "status",
    }
    data = payload.model_dump(exclude_unset=True)
    for payload_key, value in data.items():
        key = field_map[payload_key]
        if value is None:
            setattr(term, key, None)
        elif isinstance(value, str):
            setattr(term, key, value)
        else:
            setattr(term, key, value)
    duplicate = find_existing(
        db,
        term.context_key,
        term.source_text,
        term.source_lang,
        term.target_lang,
    )
    if duplicate is not None and duplicate.id != term.id:
        raise HTTPException(status.HTTP_409_CONFLICT, "詞彙已存在")
    term.version += 1
    term.updated_by = user_id
    term.updated_at = utc_now()
    record_history(db, term, "update", user_id)
    db.commit()
    db.refresh(term)
    return term


def import_glossary_records(
    db: Session,
    payload: GlossaryImportRequest,
    user_id: str,
) -> GlossaryImportResponse:
    imported = 0
    updated = 0

    def upsert(context_key: str, source_text: str, target_text: str) -> None:
        nonlocal imported, updated
        source = source_text.strip()
        if not source:
            return
        target = target_text.strip()
        existing = find_existing(db, context_key, source, None, None)
        if existing is None:
            term = GlossaryTerm(
                source_text=source,
                target_text=target,
                context_key=context_key,
                status=payload.status,
                created_by=user_id,
                updated_by=user_id,
            )
            db.add(term)
            db.flush()
            record_history(db, term, "import", user_id)
            imported += 1
            return
        existing.target_text = target
        existing.status = payload.status
        existing.version += 1
        existing.updated_by = user_id
        existing.updated_at = utc_now()
        record_history(db, existing, "import", user_id)
        updated += 1

    for source_text, target_text in payload.glossary.items():
        upsert("global", source_text, target_text)
    for context_key, entries in payload.langGlossary.items():
        for source_text, target_text in entries.items():
            upsert(context_key, source_text, target_text)

    db.commit()
    return GlossaryImportResponse(imported=imported, updated=updated)

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import current_user, require_editor
from ..models import GlossaryTerm, GlossaryTermHistory, User
from ..schemas import (
    GlossaryBundle,
    GlossaryImportRequest,
    GlossaryImportResponse,
    GlossaryTermCreate,
    GlossaryTermHistoryOut,
    GlossaryTermOut,
    GlossaryTermUpdate,
)
from ..services.glossary_service import (
    active_terms_query,
    bundle_from_terms,
    create_term_record,
    history_out,
    import_glossary_records,
    set_term_status,
    soft_delete_term,
    term_out,
    update_term_record,
    validate_status_filter,
)

router = APIRouter(prefix="/glossary", tags=["glossary"])


@router.get("")
def get_glossary(
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[User, Depends(current_user)],
    status_filter: str = Query("approved", alias="status"),
) -> GlossaryBundle:
    status_filter = validate_status_filter(status_filter)
    terms = list(
        db.scalars(
            active_terms_query()
            .where(GlossaryTerm.status == status_filter)
            .order_by(GlossaryTerm.context_key, GlossaryTerm.source_text)
        )
    )
    return bundle_from_terms(terms)


@router.get("/terms")
def list_terms(
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[User, Depends(current_user)],
    status_filter: str | None = Query(None, alias="status"),
    context_key: str | None = Query(None, alias="contextKey"),
) -> list[GlossaryTermOut]:
    query = active_terms_query().order_by(
        GlossaryTerm.context_key, GlossaryTerm.source_text
    )
    if status_filter:
        status_filter = validate_status_filter(status_filter)
        query = query.where(GlossaryTerm.status == status_filter)
    if context_key:
        query = query.where(GlossaryTerm.context_key == context_key)
    return [term_out(term) for term in db.scalars(query)]


@router.get("/changes")
def list_changes(
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[User, Depends(current_user)],
    since: datetime,
) -> list[GlossaryTermOut]:
    terms = list(
        db.scalars(
            select(GlossaryTerm)
            .where(GlossaryTerm.updated_at > since)
            .order_by(GlossaryTerm.updated_at)
        )
    )
    return [term_out(term) for term in terms]


@router.get("/{term_id}/history")
def list_history(
    term_id: str,
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[User, Depends(require_editor)],
) -> list[GlossaryTermHistoryOut]:
    items = list(
        db.scalars(
            select(GlossaryTermHistory)
            .where(GlossaryTermHistory.term_id == term_id)
            .order_by(GlossaryTermHistory.changed_at)
        )
    )
    return [history_out(item) for item in items]


@router.post("", status_code=status.HTTP_201_CREATED)
def create_term(
    payload: GlossaryTermCreate,
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(current_user)],
) -> GlossaryTermOut:
    return term_out(create_term_record(db, payload, user.id, user.role))


@router.post("/{term_id}/approve")
def approve_term(
    term_id: str,
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(require_editor)],
) -> GlossaryTermOut:
    return term_out(set_term_status(db, term_id, "approved", "approve", user.id))


@router.post("/{term_id}/reject")
def reject_term(
    term_id: str,
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(require_editor)],
) -> GlossaryTermOut:
    return term_out(set_term_status(db, term_id, "rejected", "reject", user.id))


@router.put("/{term_id}")
def update_term(
    term_id: str,
    payload: GlossaryTermUpdate,
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(require_editor)],
) -> GlossaryTermOut:
    return term_out(update_term_record(db, term_id, payload, user.id))


@router.delete("/{term_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_term(
    term_id: str,
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(require_editor)],
) -> None:
    soft_delete_term(db, term_id, user.id)


@router.post("/import")
def import_glossary(
    payload: GlossaryImportRequest,
    db: Annotated[Session, Depends(get_db)],
    user: Annotated[User, Depends(require_editor)],
) -> GlossaryImportResponse:
    return import_glossary_records(db, payload, user.id)


@router.get("/export")
def export_glossary(
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[User, Depends(current_user)],
) -> GlossaryBundle:
    terms = list(
        db.scalars(
            active_terms_query()
            .where(GlossaryTerm.status == "approved")
            .order_by(GlossaryTerm.context_key, GlossaryTerm.source_text)
        )
    )
    return bundle_from_terms(terms)

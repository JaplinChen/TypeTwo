import argparse
import json
import sys
from pathlib import Path

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.database import Base, SessionLocal, engine
from app.models import GlossaryTerm, User, utc_now


def import_file(path: Path, user_email: str | None = None) -> tuple[int, int]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("glossary.json 必須是 JSON object")

    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        user_id = None
        if user_email:
            user = db.scalar(select(User).where(User.email == user_email))
            user_id = user.id if user else None

        inserted = 0
        updated = 0
        for source_text, target_text in data.items():
            source = str(source_text).strip()
            if not source:
                continue
            target = "" if target_text is None else str(target_text).strip()
            existing = db.scalar(
                select(GlossaryTerm).where(
                    GlossaryTerm.context_key == "global",
                    GlossaryTerm.source_text == source,
                    GlossaryTerm.deleted_at.is_(None),
                )
            )
            if existing is None:
                db.add(
                    GlossaryTerm(
                        source_text=source,
                        target_text=target,
                        context_key="global",
                        status="approved",
                        created_by=user_id,
                        updated_by=user_id,
                    )
                )
                inserted += 1
                continue
            existing.target_text = target
            existing.updated_by = user_id
            existing.updated_at = utc_now()
            existing.version += 1
            updated += 1
        db.commit()
        return inserted, updated


def main() -> None:
    parser = argparse.ArgumentParser(description="匯入 TypeTwo glossary.json")
    parser.add_argument("path", type=Path)
    parser.add_argument("--user-email")
    args = parser.parse_args()
    inserted, updated = import_file(args.path, args.user_email)
    print(f"匯入完成：新增 {inserted} 筆，更新 {updated} 筆")


if __name__ == "__main__":
    main()

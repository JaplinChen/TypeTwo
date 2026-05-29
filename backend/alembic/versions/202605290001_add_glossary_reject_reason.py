"""新增詞彙退回原因

Revision ID: 202605290001
Revises: 202605260001
Create Date: 2026-05-29
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "202605290001"
down_revision: str | None = "202605260001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "glossary_term_history",
        sa.Column("reason", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("glossary_term_history", "reason")

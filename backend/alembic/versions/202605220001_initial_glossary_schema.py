"""建立詞彙表初始 schema

Revision ID: 202605220001
Revises:
Create Date: 2026-05-22
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "202605220001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "glossary_terms",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("source_text", sa.Text(), nullable=False),
        sa.Column("target_text", sa.Text(), nullable=False),
        sa.Column("source_lang", sa.String(length=64), nullable=True),
        sa.Column("target_lang", sa.String(length=64), nullable=True),
        sa.Column("context_key", sa.String(length=128), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("created_by", sa.String(length=36), nullable=True),
        sa.Column("updated_by", sa.String(length=36), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["updated_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_glossary_terms_context_key", "glossary_terms", ["context_key"])
    op.create_index("ix_glossary_terms_deleted_at", "glossary_terms", ["deleted_at"])
    op.create_index("ix_glossary_terms_status", "glossary_terms", ["status"])
    op.create_index("ix_glossary_terms_updated_at", "glossary_terms", ["updated_at"])
    op.create_index(
        "glossary_terms_unique_active",
        "glossary_terms",
        ["context_key", "source_text", "source_lang", "target_lang"],
        unique=True,
        postgresql_where=sa.text("deleted_at IS NULL"),
        sqlite_where=sa.text("deleted_at IS NULL"),
    )

    op.create_table(
        "glossary_term_history",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("term_id", sa.String(length=36), nullable=False),
        sa.Column("source_text", sa.Text(), nullable=False),
        sa.Column("target_text", sa.Text(), nullable=False),
        sa.Column("source_lang", sa.String(length=64), nullable=True),
        sa.Column("target_lang", sa.String(length=64), nullable=True),
        sa.Column("context_key", sa.String(length=128), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("operation", sa.String(length=32), nullable=False),
        sa.Column("changed_by", sa.String(length=36), nullable=True),
        sa.Column("changed_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["changed_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_glossary_term_history_changed_at",
        "glossary_term_history",
        ["changed_at"],
    )
    op.create_index(
        "ix_glossary_term_history_context_key",
        "glossary_term_history",
        ["context_key"],
    )
    op.create_index(
        "ix_glossary_term_history_status",
        "glossary_term_history",
        ["status"],
    )
    op.create_index(
        "ix_glossary_term_history_term_id",
        "glossary_term_history",
        ["term_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_glossary_term_history_term_id", table_name="glossary_term_history")
    op.drop_index("ix_glossary_term_history_status", table_name="glossary_term_history")
    op.drop_index(
        "ix_glossary_term_history_context_key",
        table_name="glossary_term_history",
    )
    op.drop_index(
        "ix_glossary_term_history_changed_at",
        table_name="glossary_term_history",
    )
    op.drop_table("glossary_term_history")

    op.drop_index("glossary_terms_unique_active", table_name="glossary_terms")
    op.drop_index("ix_glossary_terms_updated_at", table_name="glossary_terms")
    op.drop_index("ix_glossary_terms_status", table_name="glossary_terms")
    op.drop_index("ix_glossary_terms_deleted_at", table_name="glossary_terms")
    op.drop_index("ix_glossary_terms_context_key", table_name="glossary_terms")
    op.drop_table("glossary_terms")

    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")

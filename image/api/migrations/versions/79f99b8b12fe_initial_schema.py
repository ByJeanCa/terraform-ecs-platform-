"""initial schema

Revision ID: 79f99b8b12fe
Revises: 
Create Date: 2025-11-30 23:18:12.891701

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '79f99b8b12fe'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create initial tables."""

    # Create questions table
    op.create_table(
        'questions',
        sa.Column('id', sa.Integer(), primary_key=True, nullable=False),
        sa.Column('question_text', sa.String(), nullable=True),
    )

    # Create choices table
    op.create_table(
        'choices',
        sa.Column('id', sa.Integer(), primary_key=True, nullable=False),
        sa.Column('choice_text', sa.String(), nullable=True),
        sa.Column('is_correct', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('question_id', sa.Integer(), sa.ForeignKey('questions.id'), nullable=True),
    )


def downgrade() -> None:
    """Drop initial tables."""
    op.drop_table('choices')
    op.drop_table('questions')

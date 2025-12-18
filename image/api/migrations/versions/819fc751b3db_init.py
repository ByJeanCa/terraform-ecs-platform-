"""init

Revision ID: 819fc751b3db
Revises: 79f99b8b12fe
Create Date: 2025-12-01 03:18:35.973546

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '819fc751b3db'
down_revision: Union[str, Sequence[str], None] = '79f99b8b12fe'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """No schema changes in this migration."""
    pass


def downgrade() -> None:
    """No schema changes in this migration."""
    pass

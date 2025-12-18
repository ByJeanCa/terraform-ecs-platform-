import os
from logging.config import fileConfig
from alembic import context
from sqlalchemy import engine_from_config, pool
from api import models
import json

# Alembic Config object
config = context.config

# Logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

secret_raw = os.getenv("DB_SECRET")

if not secret_raw:
    raise RuntimeError("DB_SECRET no está definido en las variables de entorno")

secret = json.loads(secret_raw)

USER = secret["username"]
PASSWORD = secret["password"]

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DATABASE_URL = f"postgresql://{USER}:{PASSWORD}@{DB_HOST}/{DB_NAME}"


# Tell Alembic to use this URL
config.set_main_option("sqlalchemy.url", DATABASE_URL)

# Your models' metadata
target_metadata = models.Base.metadata

def run_migrations_offline():
    context.configure(
        url=DATABASE_URL,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    configuration = config.get_section(config.config_ini_section) or {}
    configuration["sqlalchemy.url"] = DATABASE_URL

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()

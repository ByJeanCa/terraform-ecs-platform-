import json
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# 1. Leer el JSON de Secrets Manager desde la variable de entorno
secret_raw = os.getenv("DB_SECRET")

if not secret_raw:
    raise RuntimeError("DB_SECRET no está definido en las variables de entorno")

secret = json.loads(secret_raw)

USER = secret["username"]
PASSWORD = secret["password"]

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")

# 3. Construir URL
URL_DATABASE = f"postgresql://{USER}:{PASSWORD}@{DB_HOST}/{DB_NAME}"

# 4. Crear engine
engine = create_engine(URL_DATABASE)

Sessionlocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

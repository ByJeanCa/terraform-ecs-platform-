import time
import subprocess
import sqlalchemy
from sqlalchemy import text
from sqlalchemy.orm import Session
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Annotated
from api import models
from api.database import engine, Sessionlocal

# --- Modelos Pydantic ---
class ChoiceBase(BaseModel):
    choice_text: str
    is_correct: bool

class QuestionBase(BaseModel):
    question_text: str
    choices: List[ChoiceBase]

# --- Dependencia de DB ---
def get_db():
    db = Sessionlocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]

# --- Inicialización de la app ---
app = FastAPI()

# --- Evento de startup: esperar y migrar ---
@app.on_event("startup")
def startup_event():
    max_retries = 30
    for i in range(max_retries):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print("✅ Conexión exitosa a PostgreSQL")
            break
        except Exception as e:
            print(f"⏳ Intento {i+1}/{max_retries} — Esperando a PostgreSQL... ({e})")
            time.sleep(1)
    else:
        print("❌ No se pudo conectar a la base de datos después de varios intentos.")
        raise RuntimeError("Database not available")

    # Ejecutar migraciones de Alembic
    try:
        print("🚀 Ejecutando migraciones de Alembic...")
        subprocess.run(
            ["alembic", "upgrade", "head"],
            cwd="/app/api",
            check=True
        )
        print("✅ Migraciones completadas.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error ejecutando migraciones: {e}")
        raise RuntimeError("Error running Alembic migrations")

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/questions/{question_id}")
async def read_question(question_id: int, db: db_dependency):
    result = db.query(models.Questions).filter(models.Questions.id == question_id).first()
    if not result:
        raise HTTPException(status_code=404, detail="Question not found")
    return result

@app.get("/choices/{question_id}")
async def read_choices(question_id: int, db: db_dependency):
    result = db.query(models.Choices).filter(models.Choices.question_id == question_id).all()
    if not result:
        raise HTTPException(status_code=404, detail="Choices not found")
    return result

@app.post("/questions/")
async def create_questions(question: QuestionBase, db: db_dependency):
    db_question = models.Questions(question_text=question.question_text)
    db.add(db_question)
    db.commit()
    db.refresh(db_question)

    for choice in question.choices:
        db_choice = models.Choices(
            choice_text=choice.choice_text,
            is_correct=choice.is_correct,
            question_id=db_question.id
        )
        db.add(db_choice)
    db.commit()

    return {"question_id": db_question.id, "message": "Pregunta creada correctamente"}

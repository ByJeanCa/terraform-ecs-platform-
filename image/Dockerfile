FROM python:3.14-slim-trixie

RUN adduser apiuser
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r /app/requirements.txt 
COPY . .

ENV PYTHONPATH=/app

RUN chown -R apiuser:apiuser /app

USER apiuser

EXPOSE 8000

ENTRYPOINT ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080"]

FROM python:3.11-slim

WORKDIR /app

COPY . /app/backend

RUN pip install fastapi uvicorn "pydantic[email]"

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
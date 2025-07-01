FROM python:3.11-slim

WORKDIR /app

COPY . /app/backend

RUN pip install fastapi uvicorn "pydantic[email]" sqlalchemy databases python-dotenv passlib[bcrypt] bcrypt==4.0.1 asyncpg
RUN pip install 'uvicorn[standard]' websockets

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
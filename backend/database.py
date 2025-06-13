import os
from sqlalchemy import MetaData, Table, Column, Integer, String, create_engine, TIMESTAMP
from databases import Database
from dotenv import load_dotenv
from datetime import datetime

# load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '../database/.env'))

DATABASE_URL = os.getenv("DATABASE_URL")

metadata = MetaData()

games = Table(
    "game_rooms",
    metadata,
    Column("room_id", Integer, primary_key=True),
    Column("assigned_id", String(50), unique=True),
    Column("password", String(100)),
    Column("game_state", String(20)),
)

people = Table(
    "users",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("login", String(50), unique=True),
    Column("password", String(100)),
    Column("created_at", TIMESTAMP(timezone=True), default=datetime.utcnow),
    Column("last_visited", TIMESTAMP(timezone=True), default=datetime.utcnow),
)

database = Database(DATABASE_URL)
engine = create_engine(DATABASE_URL)

# for creating room
async def create_game_room(assigned_id: str, password: str, game_state: str = "waiting"):
    query = games.insert().values(assigned_id=assigned_id, password=password, game_state=game_state)
    return await database.execute(query)

# for deleting room
async def delete_game_room(room_id: int):
    query = games.delete().where(games.c.room_id == room_id)
    return await database.execute(query)

# for searching room
async def search_game_room(assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    return await database.fetch_one(query)



# for creating user
async def create_user(id: int, login: str, password: str, created_at: datetime | None = None, last_visited: datetime | None = None ):
    query = users.insert().values(id=id, login = login, password=password, created_at=created_at or datetime.utcnow(), last_visited = last_visited or datetime.utcnow())
    return await database.execute(query)

# for deleting user
async def delete_user(user_id: int):
    query = users.delete().where(users.c.id == user_id)
    return await database.execute(query)

# for searching user
async def search_user_by_id(user_id: int):
    query = users.select().where(users.c.id == user_id)
    return await database.fetch_one(query)

async def search_user_by_login(login: str):
    query = users.select().where(users.c.login == login)
    return await database.fetch_one(query)
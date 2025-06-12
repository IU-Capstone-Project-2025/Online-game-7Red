import os
from sqlalchemy import MetaData, Table, Column, Integer, String, create_engine
from databases import Database
from dotenv import load_dotenv

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
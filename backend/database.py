import os
from sqlalchemy import MetaData, Table, Column, Integer, String, create_engine, TIMESTAMP, ForeignKey, Boolean
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


user_room = Table(
    "user_room",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("room_id", Integer, ForeignKey("game_rooms.room_id", ondelete="CASCADE"), primary_key=True),
    Column("ready", Boolean, default=False),
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

profiles = Table(
    "profiles",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("name", String(100), nullable=False),
    Column("avatar", String(255)),
)

database = Database(DATABASE_URL)
engine = create_engine(DATABASE_URL)

#--------------------ROOMS-------------------------------------------------------------------------------------------------------------------------------------------------------------------

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


# check for assigned_id and password existance
async def assigned_id_exists(assigned_id: str) -> bool:
    query = games.select().where(games.c.assigned_id == assigned_id)
    result = await database.fetch_one(query)
    return result is not None

async def password_exist(password: str) -> bool:
    query = games.select().where(games.c.password == password)
    result = await database.fetch_one(query)
    return result is not None


#-------------------------USERS----------------------------------------------------------------------------------------------------------------------------------------------

# for creating user
async def create_user(login: str, password: str, created_at: datetime | None = None, last_visited: datetime | None = None ):
    query = people.insert().values(login = login, password=password, created_at=created_at or datetime.utcnow(), last_visited = last_visited or datetime.utcnow())
    return await database.execute(query)

# for deleting user
async def delete_user(user_id: int):
    query = people.delete().where(people.c.id == user_id)
    return await database.execute(query)

# for searching user
async def search_user_by_id(user_id: int):
    query = people.select().where(people.c.id == user_id)
    return await database.fetch_one(query)

async def search_user_by_login(login: str):
    query = people.select().where(people.c.login == login)
    return await database.fetch_one(query)

async def create_profile(user_id: int, name: str, avatar: str = None):
    query = profiles.insert().values(user_id=user_id, name=name, avatar=avatar)
    return await database.execute(query)


async def get_profile_by_user_id(user_id: int):
    query = profiles.select().where(profiles.c.user_id == user_id)
    return await database.fetch_one(query)

# adding user to the room
async def add_user_to_room(user_id: int, assigned_id: str):
    # find the internal room_id by assigned_id
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]
    insert_query = user_room.insert().values(user_id=user_id, room_id=room_id)
    await database.execute(insert_query)
    

async def remove_user_from_room(user_id: int, assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room mot found")
    room_id = room["room_id"]
    delete = user_room.delete().where((user_room.c.user_id == user_id) & (user_room.c.room_id == room_id))
    await database.execute(delete)
    
    
async def set_user_ready(user_id: int, assigned_id: str, ready: bool):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]
    set_query = user_room.update().where((user_room.c.user_id == user_id) & (user_room.c.room_id == room_id)).values(ready=ready)
    await database.execute(set_query)
    
async def get_room_players_and_ready(assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]

    players = (user_room.join(profiles, user_room.c.user_id == profiles.c.user_id))
    query = (
        user_room.select()
        .with_only_columns(profiles.c.name, user_room.c.ready)
        .select_from(players)
        .where(user_room.c.room_id == room_id)
    )
    rows = await database.fetch_all(query)
    players = [row["name"] for row in rows]
    ready_p = [row["name"] for row in rows if row["ready"]]
    return players, ready_p
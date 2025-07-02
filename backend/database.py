import os
from sqlalchemy import (MetaData, Table, Text, Column, Date, Integer, String, 
                        create_engine, TIMESTAMP, ForeignKey, Boolean, select)
from databases import Database
from dotenv import load_dotenv
from datetime import datetime, UTC, date, timedelta

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

users = Table(
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

user_achievements = Table(
    "user_achievements",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("achievement_id", Integer, ForeignKey("achievements.id", ondelete="CASCADE"), primary_key=True),
)

visit_history = Table(
    "visit_history",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("visit_date", Date, primary_key=True),
)

achievements = Table(
    "achievements",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("name", String(100), nullable=False),
    Column("description", Text),
)

statistics = Table(
    "statistics",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("total_played", Integer, default=0),
    Column("wins", Integer, default=0),
    Column("cur_straight_wins", Integer, default=0),
    Column("max_straight_wins", Integer, default=0),
    Column("bot_wins", Integer, default=0), 
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

# for searching room by assigned_id and returning room_id
async def return_room_id_using_assigned_id(assigned_id: str):
    query = games.select().with_only_columns(games.c.room_id).where(games.c.assigned_id == assigned_id)
    result = await database.fetch_one(query)
    return result.room_id

# check for assigned_id and password existance
async def assigned_id_exists(assigned_id: str) -> bool:
    query = games.select().where(games.c.assigned_id == assigned_id)
    result = await database.fetch_one(query)
    return result is not None

async def password_exist(password: str) -> bool:
    query = games.select().where(games.c.password == password)
    result = await database.fetch_one(query)
    return result is not None

async def update_room_state(assigned_id: str, state: str):
    query = (
        games.update()
        .where(games.c.assigned_id == assigned_id)
        .values(game_state=state)
    )
    await database.execute(query)


#-------------------------USERS----------------------------------------------------------------------------------------------------------------------------------------------

# for creating user
async def create_user(login: str, password: str, created_at: datetime | None = None, last_visited: datetime | None = None ):
    query = users.insert().values(
        login=login,
        password=password,
        created_at=created_at or datetime.now(UTC),
        last_visited=last_visited or datetime.now(UTC)
    )
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

async def create_profile(user_id: int, name: str, avatar: str = None):
    query = profiles.insert().values(user_id=user_id, name=name, avatar=avatar)
    return await database.execute(query)

async def get_profile_by_user_id(user_id: int):
    query = profiles.select().where(profiles.c.user_id == user_id)
    return await database.fetch_one(query)

async def get_profile_name_by_user_id(user_id: int):
    query = profiles.select().where(profiles.c.user_id == user_id)
    res = await database.fetch_one(query)

    if not res:
        raise Exception("Profile not found")
    
    return res["name"]

# adding user to the room
async def add_user_to_room(user_id: int, assigned_id: str):
    # find the internal room_id by assigned_id
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]
    check_query = user_room.select().where(
        (user_room.c.user_id == user_id) & (user_room.c.room_id == room_id)
    )
    exists = await database.fetch_one(check_query)
    if exists:
        raise Exception("User already in the room")
    
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
    
    check = user_room.select().where(user_room.c.room_id == room_id)
    members = await database.fetch_all(check)
    if not members:
        await delete_game_room(room_id)
    
    
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

async def get_room_players_ids_and_names(assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]

    players_join = user_room.join(profiles, user_room.c.user_id == profiles.c.user_id)
    query = (
        select(profiles.c.name, user_room.c.user_id)
        .select_from(players_join)
        .where(user_room.c.room_id == room_id)
    )
    
    rows = await database.fetch_all(query)
    players = [row["name"] for row in rows]
    ids = [row["user_id"] for row in rows]
    return players, ids

async def update_last_visited(user_id: int):
    query = users.update().where(users.c.user_id == user_id).values(last_visited=datetime.now(UTC))
    await database.execute(query)


#--------------------------achievements--------------------------------------------------------------    
async def add_visit(user_id: int):
    today = date.today()
    query = visit_history.insert().values(user_id=user_id, visit_date=today)
    try:
        await database.execute(query)
    except Exception:
        pass
    
    
async def get_visit_streak(user_id: int):
    query = visit_history.select().where(visit_history.c.user_id == user_id)
    visits = await database.fetch_all(query)
    dates = sorted([v["visit_date"] for v in visits], reverse=True)
    streak = 0
    prev = None
    for d in dates:
        if prev is None or prev == d + timedelta(days=1):
            streak += 1
        else:
            break
    return streak

async def award_achievement_if_needed(user_id: int, achievement_id: int):
    query = user_achievements.select().where(
        (user_achievements.c.user_id == user_id) &
        (user_achievements.c.achievement_id == achievement_id)
    )
    exist = await database.fetch_one(query)
    if not exist:
        insert = user_achievements.insert().values(
            user_id=user_id, achievement_id=achievement_id
        )
        await database.execute(insert)
        
async def get_achievement_id_by_name(name: str):
    query = achievements.select().where(achievements.c.name == name)
    achievement = await database.fetch_one(query)
    if achievement:
        return achievement["id"]
    return None

async def get_win_streak(user_id: int):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if stats:
        return stats["cur_straight_wins"]
    return 0

async def update_win_streak(user_id: int, is_win: bool):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if not stats:
        await database.execute(statistics.insert().values(
            user_id=user_id,
            total_played=1,
            wins=1 if is_win else 0,
            cur_straight_wins=1 if is_win else 0,
            max_straight_wins=1 if is_win else 0
        ))
        return
    cur_streak = stats["cur_straight_wins"]
    max_streak = stats["max_straight_wins"]
    total_played = stats["total_played"] + 1
    wins = stats["wins"] + (1 if is_win else 0)

    if is_win:
        cur_streak += 1
        if cur_streak > max_streak:
            max_streak = cur_streak
    else:
        cur_streak = 0
    
    upd = statistics.update().where(statistics.c.user_id == user_id).values(
        cur_straight_wins=cur_streak,
        max_straight_wins=max_streak,
        total_played=total_played,
        wins=wins
    ) 
    await database.execute(upd) 
    

async def check_and_award_win_streak(user_id: int):
    streak = await get_win_streak(user_id)
    if streak >= 5:
        achievement_id = await get_achievement_id_by_name("5_wins_streak")
        if achievement_id:
            await award_achievement_if_needed(user_id, achievement_id)
            
async def increment_bot_wins(user_id: int):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if not stats:
        await database.execute(statistics.insert().values(
            user_id=user_id,
            total_played=0,
            wins=0,
            cur_straight_wins=0,
            max_straight_wins=0,
            bot_wins=1
        ))
        return 1
    
    bot_wins = stats.get("bot_wins", 0) + 1
    upd = statistics.update().where(statistics.c.user_id == user_id).values(bot_wins=bot_wins)
    await database.execute(upd)
    return bot_wins

async def check_and_award_bot_wins(user_id: int):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if stats and stats.get("bot_wins", 0) >= 3:
        achievement_id = await get_achievement_id_by_name("3_wins_of_bot")
        if achievement_id:
            await award_achievement_if_needed(user_id, achievement_id)
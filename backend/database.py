import os
from sqlalchemy import (MetaData, Table, Text, Column, Date, Integer, String, 
                        create_engine, TIMESTAMP, ForeignKey, Boolean, select)
from databases import Database
from dotenv import load_dotenv
from datetime import datetime, UTC, date, timedelta

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), '../database/.env'))

# Get database URL from environment variables
DATABASE_URL = os.getenv("DATABASE_URL")

# Initialize SQLAlchemy metadata
metadata = MetaData()

# Define database tables using SQLAlchemy models

# Table for game rooms
games = Table(
    "game_rooms",
    metadata,
    Column("room_id", Integer, primary_key=True),
    Column("assigned_id", String(50), unique=True),
    Column("password", String(100)),
    Column("game_state", String(20)),
)

# Table for user-room associations (many-to-many)
user_room = Table(
    "user_room",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("room_id", Integer, ForeignKey("game_rooms.room_id", ondelete="CASCADE"), primary_key=True),
    Column("ready", Boolean, default=False),
    Column("room_type", String(15)),
)

# Table for user accounts
users = Table(
    "users",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("login", String(50), unique=True),
    Column("password", String(100)),
    Column("created_at", TIMESTAMP(timezone=True), default=datetime.utcnow),
    Column("last_visited", TIMESTAMP(timezone=True), default=datetime.utcnow),
)

# Table for user profiles
profiles = Table(
    "profiles",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("name", String(100), nullable=False),
    Column("avatar", String(255)),
)

# Table for user-achievement associations (many-to-many)
user_achievements = Table(
    "user_achievements",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("achievement_id", Integer, ForeignKey("achievements.id", ondelete="CASCADE"), primary_key=True),
)

# Table for tracking user visit history
visit_history = Table(
    "visit_history",
    metadata,
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("visit_date", Date, primary_key=True),
)

# Table for achievements
achievements = Table(
    "achievements",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("name", String(100), nullable=False),
    Column("description", Text),
)

# Table for user game statistics
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

# Initialize database connection
database = Database(DATABASE_URL)
engine = create_engine(DATABASE_URL)

#--------------------ROOMS-------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create a new game room in the database
async def create_game_room(assigned_id: str, password: str, game_state: str = "waiting"):
    query = games.insert().values(assigned_id=assigned_id, password=password, game_state=game_state)
    return await database.execute(query)

# Delete a game room by its ID
async def delete_game_room(room_id: int):
    query = games.delete().where(games.c.room_id == room_id)
    return await database.execute(query)

# Find a game room by its assigned ID
async def search_game_room(assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    return await database.fetch_one(query)

# Get the internal room_id using the public assigned_id
async def return_room_id_using_assigned_id(assigned_id: str):
    query = games.select().with_only_columns(games.c.room_id).where(games.c.assigned_id == assigned_id)
    result = await database.fetch_one(query)
    return result.room_id

# Check if a room with the given assigned_id exists
async def assigned_id_exists(assigned_id: str) -> bool:
    query = games.select().where(games.c.assigned_id == assigned_id)
    result = await database.fetch_one(query)
    return result is not None

# Check if a room with the given password exists
async def password_exist(password: str) -> bool:
    query = games.select().where(games.c.password == password)
    result = await database.fetch_one(query)
    return result is not None

# Update the game state of a room
async def update_room_state(assigned_id: str, state: str):
    query = (
        games.update()
        .where(games.c.assigned_id == assigned_id)
        .values(game_state=state)
    )
    await database.execute(query)

async def get_room_state(room_id: int):
    query = (
        games.select()
        .where(games.c.room_id == room_id)
    )
    return await database.fetch_one(query)

#-------------------------USERS----------------------------------------------------------------------------------------------------------------------------------------------

# Create a new user account
async def create_user(login: str, password: str, created_at: datetime | None = None, last_visited: datetime | None = None ):
    query = users.insert().values(
        login=login,
        password=password,
        created_at=created_at or datetime.now(UTC),
        last_visited=last_visited or datetime.now(UTC)
    )
    return await database.execute(query)

# Delete a user account by ID
async def delete_user(user_id: int):
    query = users.delete().where(users.c.id == user_id)
    return await database.execute(query)

# Find a user by their ID
async def search_user_by_id(user_id: int):
    query = users.select().where(users.c.id == user_id)
    return await database.fetch_one(query)

# Find a user by their login name
async def search_user_by_login(login: str):
    query = users.select().where(users.c.login == login)
    return await database.fetch_one(query)

# Create a user profile
async def create_profile(user_id: int, name: str, avatar: str = None):
    query = profiles.insert().values(user_id=user_id, name=name, avatar=avatar)
    return await database.execute(query)

# Get a user's profile by their ID
async def get_profile_by_user_id(user_id: int):
    query = profiles.select().where(profiles.c.user_id == user_id)
    return await database.fetch_one(query)

# Get a user's name from their profile
async def get_profile_name_by_user_id(user_id: int):
    query = profiles.select().where(profiles.c.user_id == user_id)
    res = await database.fetch_one(query)

    if not res:
        raise Exception("Profile not found")
    
    return res["name"]

# Add a user to a game room
async def add_user_to_room(user_id: int, assigned_id: str, type: str = "None"):
    # find the internal room_id by assigned_id
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]
    
    # Check if user is already in the room
    check_query = user_room.select().where(
        (user_room.c.user_id == user_id) & (user_room.c.room_id == room_id)
    )
    exists = await database.fetch_one(check_query)
    if exists:
        raise Exception("User already in the room")
    
    # Add user to room
    insert_query = user_room.insert().values(user_id=user_id, room_id=room_id, room_type=type)
    await database.execute(insert_query)
    
# Remove a user from a game room
async def remove_user_from_room(user_id: int, assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room mot found")
    room_id = room["room_id"]
    
    # Remove the user from the room
    delete = user_room.delete().where((user_room.c.user_id == user_id) & (user_room.c.room_id == room_id))
    await database.execute(delete)
    
    # If room is empty after removal, delete the room
    check = user_room.select().where(user_room.c.room_id == room_id)
    members = await database.fetch_all(check)
    if not members:
        await delete_game_room(room_id)
    
# Set a user's ready status in a room
async def set_user_ready(user_id: int, assigned_id: str, ready: bool):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]
    set_query = user_room.update().where((user_room.c.user_id == user_id) & (user_room.c.room_id == room_id)).values(ready=ready)
    await database.execute(set_query)
    
# Get all players and their ready status in a room
async def get_room_players_and_ready(assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]

    # Join tables to get player names and ready status
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

# Get player IDs and names in a room
async def get_room_players_ids_and_names(assigned_id: str):
    query = games.select().where(games.c.assigned_id == assigned_id)
    room = await database.fetch_one(query)
    if not room:
        raise Exception("Room not found")
    room_id = room["room_id"]

    # Join tables to get player IDs and names
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

# Update a user's last visited timestamp
async def update_last_visited(user_id: int):
    query = users.update().where(users.c.user_id == user_id).values(last_visited=datetime.now(UTC))
    await database.execute(query)

async def user_exists_in_room(user_id: int, assigned_id: str) -> bool:
    query = user_room.select().where(
        (user_room.c.user_id == user_id) & 
        (user_room.c.room_id == await return_room_id_using_assigned_id(assigned_id))
    )
    result = await database.fetch_one(query)
    return result is not None


#--------------------------achievements--------------------------------------------------------------    

# Record a user's daily visit
async def add_visit(user_id: int):
    today = date.today()
    query = visit_history.insert().values(user_id=user_id, visit_date=today)
    try:
        await database.execute(query)
    except Exception:
        pass  # Ignore if already exists
    
# Calculate a user's consecutive visit streak
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

# Award an achievement to a user if they don't already have it
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
        

# Check and award the 7-day streak achievement if eligible
async def check_and_award_7_days_streak(user_id: int):
    streak = await get_visit_streak(user_id)
    if streak >= 7:
        achievement_id = await get_achievement_id_by_name("7_days_streak")
        if achievement_id:
            awarded = await award_achievement_if_needed(user_id, achievement_id)
            if awarded:
                return "7_days_streak"
    return None


# Get achievement ID by name
async def get_achievement_id_by_name(name: str):
    query = achievements.select().where(achievements.c.name == name)
    achievement = await database.fetch_one(query)
    if achievement:
        return achievement["id"]
    return None

# Get a user's current win streak
async def get_win_streak(user_id: int):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if stats:
        return stats["cur_straight_wins"]
    return 0

# Update a user's win streak and statistics
async def update_win_streak(user_id: int, is_win: bool):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    
    # Create initial statistics if none exist
    if not stats:
        await database.execute(statistics.insert().values(
            user_id=user_id,
            total_played=1,
            wins=1 if is_win else 0,
            cur_straight_wins=1 if is_win else 0,
            max_straight_wins=1 if is_win else 0,
            bot_wins=0
        ))
        return
        
    # Update existing statistics
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
    
# Check and award the 5-win streak achievement if eligible
async def check_and_award_win_streak(user_id: int):
    streak = await get_win_streak(user_id)
    if streak >= 5:
        achievement_id = await get_achievement_id_by_name("5_wins_streak")
        if achievement_id:
            await award_achievement_if_needed(user_id, achievement_id)
            
# Increment a user's bot win counter
async def increment_bot_wins(user_id: int):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    
    # Create initial statistics if none exist
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
    

    bot_wins = stats["bot_wins"] + 1
    upd = statistics.update().where(statistics.c.user_id == user_id).values(bot_wins=bot_wins)
    await database.execute(upd)
    return bot_wins

# Check and award the 3 bot wins achievement if eligible
async def check_and_award_bot_wins(user_id: int):
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if stats and getattr(stats, "bot_wins", 0) >= 3:
        achievement_id = await get_achievement_id_by_name("3_wins_over_the_bot")
        if achievement_id:
            await award_achievement_if_needed(user_id, achievement_id)
async def create_user_statistics(user_id: int):
    query = statistics.insert().values(
        user_id=user_id,
        total_played=0,
        wins=0,
        cur_straight_wins=0,
        max_straight_wins=0,
        bot_wins=0
    )
    await database.execute(query)
#--------------------------reconnect--------------------------------------------------------------  
async def get_room_type_for_user(user_id: int, room_id: int) -> str:
    """
    This function retrieves the type of room (e.g., 'online', 'private') for a user in a specific room.
    Args:
        user_id: ID user
        room_id: ID room
        
    Returns:
        str: Type of room ('online', 'private', 'online_reconnect', 'private_reconnect', 'None')

    Raises:
        Exception: If user-room association is not found
    """
    query = user_room.select().where(
        (user_room.c.user_id == user_id) & 
        (user_room.c.room_id == room_id)
    )
    
    result = await database.fetch_one(query)
    
    if not result:
        raise Exception("User not found in the room")
    return result["room_type"]

async def change_room_type_for_user_by_assigned_id(room_id: int, type: str) -> str:
    query = user_room.update().where(user_room.c.room_id == room_id).values(room_type=type)
    await database.execute(query)
    return type

async def change_room_type_for_user_by_user_id(user_id: int, room_id: int, type: str) -> str:
    query = user_room.update().where(
        (user_room.c.user_id == user_id) & 
        (user_room.c.room_id == room_id)
    ).values(room_type=type)
    await database.execute(query)
    return type

async def change_room_type_for_user_automatic(room_id: int, list_user_id: list[int]) -> str:
    """
    This function changes the room type for a user in a specific room based on their current type.
    Args:
        room_id: ID of the room
        user_id: ID of the user
        
    Returns:
        str: New type of room ('online', 'private', 'online_reconnect', 'private_reconnect')
    """
    for user_id in list_user_id:
        current_type = await get_room_type_for_user(user_id, room_id)
        
        if current_type == "online_reconnect":
            new_type = "online"
        elif current_type == "private_reconnect":
            new_type = "private"
        elif current_type == "online":
            new_type = "online_reconnect"
        elif current_type == "private":
            new_type = "private_reconnect"
        else:
            raise Exception("Invalid room type for automatic change")
        await change_room_type_for_user_by_assigned_id(room_id, new_type)
    
    return "".join([f"User {user_id} changed to {new_type}" for user_id in list_user_id])
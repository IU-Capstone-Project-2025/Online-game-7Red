from fastapi import APIRouter, Body, HTTPException
from passlib.context import CryptContext
from backend.database import (
    statistics, user_achievements, search_user_by_id, users, get_achievement_id_by_name, database, profiles
)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter(prefix="/settings", tags=["settings"])

@router.post("/user_stats")
async def user_stats(user_id: int = Body(..., embed=True)):
    # Get user statistics from the database
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if not stats:
        raise HTTPException(status_code=404, detail="User stats not found")

    # Extract statistics values
    winstrick = stats["max_straight_wins"]
    num_of_games = stats["total_played"]
    wins = stats["wins"]
    # Calculate win rate (avoid division by zero)
    winrate = int((wins / num_of_games) * 100) if num_of_games > 0 else 0

    # Check user achievements
    ach_names = ["7_days_streak", "3_wins_over_the_bot", "5_wins_streak" ]
    ach_ids = []
    # Get achievement IDs by their names
    for name in ach_names:
        aid = await get_achievement_id_by_name(name)
        ach_ids.append(aid)
    # Fetch user's completed achievements
    query = user_achievements.select().where(user_achievements.c.user_id == user_id)
    user_achs = await database.fetch_all(query)
    # Create a set of achievement IDs that the user has completed
    user_ach_ids = {row["achievement_id"] for row in user_achs}
    # Check which achievements the user has completed
    achievements = [aid in user_ach_ids if aid else False for aid in ach_ids]

    # Return user statistics and achievements
    return {
        "winstrick": winstrick,
        "num_of_games": num_of_games,
        "winrate": winrate,
        "achievements": achievements
    }

@router.post("/change_nickname")
async def chenge_nickname(user_id: int = Body(...,embed=True), new_nickname: str = Body(..., embed=True)):
    # Get user profile from database
    query = profiles.select().where(profiles.c.user_id == user_id)
    profile = await database.fetch_one(query)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    # Update nickname in the profile
    update = profiles.update().where(profiles.c.user_id == user_id).values(name = new_nickname)
    await database.execute(update)
    return {"message": "Nickname updated successfully", "new_nickname": new_nickname}

@router.post("/change_password")
async def change_password(
    user_id: int = Body(...,embed=True),
    prev_password: str = Body(...,embed=True),
    new_password: str = Body(...,embed=True),
    repeated_password: str = Body(...,embed=True)
):
    # Get user from database
    user = await search_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    # Verify current password
    if not pwd_context.verify(prev_password, user["password"]):
        raise HTTPException(status_code=403, detail="Previous password is incorrect")
    # Check if new passwords match
    if new_password != repeated_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")
    # Hash and save the new password
    hashed_password = pwd_context.hash(new_password)
    update = users.update().where(users.c.user_id == user_id).values(password=hashed_password)
    await database.execute(update)
    return {"message": "Password updated successfully"}
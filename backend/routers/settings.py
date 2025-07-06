from fastapi import APIRouter, Body, HTTPException
from backend.database import (
    statistics, user_achievements, get_achievement_id_by_name, database
)

router = APIRouter(prefix="/settings", tags=["settings"])

@router.post("/user_stats")
async def user_stats(user_id: int = Body(..., embed=True)):
    # Get user statistics from the database
    query = statistics.select().where(statistics.c.user_id == user_id)
    stats = await database.fetch_one(query)
    if not stats:
        raise HTTPException(status_code=404, detail="User stats not found")

    # Extract statistics values
    winstrick = stats["cur_straight_wins"]
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
from fastapi import APIRouter, Body, HTTPException
from app.models import JoinRoomRequest
from app.database import (assigned_id_exists, password_exist, create_game_room, add_user_to_room, 
search_game_room, remove_user_from_room, set_user_ready, get_room_players_and_ready, search_open_online_room)
import random
import asyncio
import logging


router = APIRouter(prefix="/api/rooms", tags=["rooms"])

# Global variables for online matchmaking
online_queue = []  # Queue of users waiting for online match
online_queue_status = {}  # Status tracking for users in queue
ONLINE_ROOM_SIZE = 4  # Number of players required for an online room
ONLINE_WAIT_SECONDS = 58  # Maximum wait time before starting a game with fewer players



async def generate_unique_assigned_id():
    """Generate a unique 5-digit room ID that doesn't exist in the database"""
    for _ in range(100):  # Try up to 100 times
        assigned_id = "{:05d}".format(random.randint(0, 99999))
        if not await assigned_id_exists(assigned_id):
            return assigned_id
    raise Exception("Could not generate unique id")


async def generate_unique_password():
    """Generate a unique 5-digit password that doesn't exist in the database"""
    for _ in range(100):  # Try up to 100 times
        password = "{:05d}".format(random.randint(0, 99999))
        if not await password_exist(password):
            return password
    raise Exception("Could not generate unique password")
            

@router.post("/create")
async def create_room(user_id: int = Body(..., embed=True)):
    """Create a new game room and add the creator to it"""
    assigned_id = await generate_unique_assigned_id()
    password = await generate_unique_password()
    await create_game_room(assigned_id, password)
    await add_user_to_room(user_id, assigned_id, room_type="private")
    return {
        "assigned_id": assigned_id,
        "password": password 
    }
    

@router.post("/join")
async def join_room(request: JoinRoomRequest):
    """Join an existing game room using room ID and password"""
    room = await search_game_room(request.assigned_id)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room["password"] != request.password:
        raise HTTPException(status_code=403, detail="Incorrect password")
    if room["game_state"] != "waiting":
        raise HTTPException(status_code=403, detail="Game already started")
    
    try:
        await add_user_to_room(request.user_id, request.assigned_id)
    except Exception as e:
        if "User already in the room" in str(e):
            raise HTTPException(status_code=409, detail="User already in the room")
        if "Room is full" in str(e):
            raise HTTPException(status_code=403, detail="Room is full")
        raise
    return {"message": "User added to the room"}


@router.post("/leave")
async def leave_room(
    user_id: int = Body(..., embed=True),
    assigned_id: str = Body(..., embed=True)
):
    """Remove a user from a game room"""
    try:
        await remove_user_from_room(user_id, assigned_id)
        return {"message": f"User {user_id} left room {assigned_id}"}
    except Exception as e:
       raise HTTPException(status_code=404, detail=str(e))
   

@router.post("/ready")
async def player_ready(user_id: int = Body(..., embed=True), assigned_id: str = Body(..., embed=True)):
    """Mark a player as ready to start the game"""
    try:
        await set_user_ready(user_id, assigned_id, True)
        return {"message": f"Player {user_id} is ready in room {assigned_id}"}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/not_ready")
async def player_not_ready(user_id: int = Body(..., embed=True), assigned_id: str = Body(..., embed=True)):
    """Mark a player as not ready to start the game"""
    try:
        await set_user_ready(user_id, assigned_id, False)
        return {"message": f"Player {user_id} is not ready in room {assigned_id}"}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))
    

@router.post("/state")
async def update_room_state(assigned_id: str = Body(..., embed=True)):
    """Get the current state of a room (players and their ready status)"""
    try:
        players, ready_players = await get_room_players_and_ready(assigned_id)
        return {
            "players": players,
            "ready_players": ready_players
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))
    
    
#--------------------------Find online players--------------------------------------------------------------
    
async def start_online_game(players):
    """Create a game room for matched online players"""
    assigned_id = await generate_unique_assigned_id()
    password = await generate_unique_password()
    await create_game_room(assigned_id, password)
    for user_id in players:
        await add_user_to_room(user_id, assigned_id, room_type="public")
        online_queue_status[user_id] = {
            "status": "matched",
            "assigned_id": assigned_id,
            "password": password,
            "players": players
        }
    return assigned_id, password


online_queue_timer = None

async def online_queue_timeout(initial_queue):
    global online_queue_timer
    await asyncio.sleep(ONLINE_WAIT_SECONDS)
    online_queue_timer = None
    still_waiting = list(online_queue)
    if len(still_waiting) >= 2:
        for uid in still_waiting:
            online_queue.remove(uid)
        await start_online_game(still_waiting)
    else:
        for uid in still_waiting:
            online_queue.remove(uid)
            online_queue_status[uid] = {"status": "no_players"}




@router.post("/find_online")
async def find_online(user_id: int = Body(..., embed=True)):
    global online_queue_timer
    # 1. Try to find a suitable existing room
    room = await search_open_online_room()
    if room:
        try:
            await add_user_to_room(user_id, room["assigned_id"])
            online_queue_status[user_id] = {
                "status": "matched",
                "assigned_id": room["assigned_id"],
                "password": room["password"],
                "players": [user_id] 
            }
            return online_queue_status[user_id]
        except Exception:
            pass  # If adding failed (e.g., race condition) - continue to next step

    # 2. If no suitable room exists - use standard queue
    if user_id in online_queue:
        return {"status": online_queue_status.get(user_id, "waiting")}
    online_queue.append(user_id)
    online_queue_status[user_id] = {"status":"waiting"}
    
    if len(online_queue) >= 2:
        players = online_queue[:ONLINE_ROOM_SIZE]
        for uid in players:
            online_queue.remove(uid)
        await start_online_game(players)
        return online_queue_status[user_id]
    
    if len(online_queue) < ONLINE_ROOM_SIZE:
        if online_queue_timer is not None:
            online_queue_timer.cancel()
        if len(online_queue) > 0:
            online_queue_timer = asyncio.create_task(online_queue_timeout(list(online_queue)))
    return {"status":"waiting"}



@router.post("/find_online_status")
async def find_online_status(user_id: int = Body(..., embed=True)):
    """
    Check the current status of a user in the online matchmaking queue.
    If the user is in the queue and an open room exists, add them to that room.
    """
    # If user is in queue and there's an available room, try to place them
    if user_id in online_queue:
        room = await search_open_online_room()
        if room:
            try:
                # Add user to the found room
                await add_user_to_room(user_id, room["assigned_id"])
                # Remove user from the waiting queue
                online_queue.remove(user_id)
                # Update user's matchmaking status
                online_queue_status[user_id] = {
                    "status": "matched",
                    "assigned_id": room["assigned_id"],
                    "password": room["password"],
                    "players": [user_id]
                }
                return online_queue_status[user_id]
            except Exception:
                # Continue if adding to room fails (e.g., race condition)
                pass  

    # Debugging information
    logging.info(f"[In function find_online_status] Current online_queue: {online_queue}")
    logging.info(f"[In function find_online_status] Current online_queue_status: {online_queue_status}")
    
    # Return the user's current status if they're in the tracking dictionary
    if user_id in online_queue_status:
        return online_queue_status[user_id]
    
    # Return default status if user is not in queue
    return {"status": "not_in_queue"}


@router.post("/cancel_find_online")
async def cancel_find_online(user_id: int = Body(..., embed=True)):
    """Remove a user from the matchmaking queue"""
    if user_id in online_queue:
        online_queue.remove(user_id)
    if user_id in online_queue_status:
        del online_queue_status[user_id]
    return {"status": "cancelled"}
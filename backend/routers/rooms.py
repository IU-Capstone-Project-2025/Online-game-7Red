from fastapi import APIRouter, Body, HTTPException
from backend.models import  JoinRoomRequest
from backend.database import (assigned_id_exists, password_exist, create_game_room, add_user_to_room, 
search_game_room, remove_user_from_room, set_user_ready, get_room_players_and_ready)
import random
import asyncio
router = APIRouter(prefix="/rooms", tags=["rooms"])

online_queue = []
online_queue_status = {}
ONLINE_ROOM_SIZE = 4
ONLINE_WAIT_SECONDS = 60


async def generate_unique_assigned_id():
    for _ in range(100):
        assigned_id = "{:05d}".format(random.randint(0, 99999))
        if not await assigned_id_exists(assigned_id):
            return assigned_id
    raise Exception("Could not generate unique id")


async def generate_unique_password():
    for _ in range(100):
        password = "{:05d}".format(random.randint(0, 99999))
        if not await password_exist(password):
            return password
    raise Exception("Could not generate unique password")
            

@router.post("/create")
async def create_room(user_id: int = Body(..., embed=True)):
    assigned_id = await generate_unique_assigned_id()
    password = await generate_unique_password()
    await create_game_room(assigned_id, password)
    await add_user_to_room(user_id, assigned_id)
    return {
        "assigned_id": assigned_id,
        "password": password 
    }
    

@router.post("/join")
async def join_room(request: JoinRoomRequest):
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
        raise
    return {"message": "User added to the room"}


@router.post("/leave")
async def leave_room(
    user_id: int = Body(..., embed=True),
    assigned_id: str = Body(..., embed=True)
):
    try:
        await remove_user_from_room(user_id, assigned_id)
        return {"message": f"User {user_id} left room {assigned_id}"}
    except Exception as e:
       raise HTTPException(status_code=404, detail=str(e))
   

@router.post("/ready")
async def player_ready(user_id: int = Body(..., embed=True), assigned_id: str = Body(..., embed=True)):
    try:
        await set_user_ready(user_id, assigned_id, True)
        return {"message": f"Player {user_id} is ready in room {assigned_id}"}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/not_ready")
async def player_not_ready( user_id: int = Body(..., embed=True), assigned_id: str = Body(..., embed=True)):
    try:
        await set_user_ready(user_id, assigned_id, False)
        return {"message": f"Player {user_id} is not ready in room {assigned_id}"}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))
    

@router.post("/state")
async def update_room_state(assigned_id: str = Body(..., embed=True)):
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
    assigned_id = await generate_unique_assigned_id()
    password = await generate_unique_password()
    await create_game_room(assigned_id, password)
    for user_id in players:
        await add_user_to_room(user_id, assigned_id)
        online_queue_status[user_id] = {
            "status": "matched",
            "assigned_id": assigned_id,
            "password": password,
            "players": players
        }
    return assigned_id, password


async def online_queue_timeout(players_snapshot):
    await asyncio.sleep(ONLINE_WAIT_SECONDS)
    still_waiting = [uid for uid in players_snapshot if uid in online_queue]
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
    if user_id in online_queue:
        return {"status": online_queue_status.get(user_id, "waiting")}
    online_queue.append(user_id)
    online_queue_status[user_id] = {"status":"waiting"}
    if len(online_queue) == 1:
        asyncio.create_task(online_queue_timeout(list(online_queue)))
    
    if len(online_queue) == ONLINE_ROOM_SIZE:
        players = list(online_queue)
        for uid in players:
            online_queue.remove(uid)
        await start_online_game(players)
        return online_queue_status[user_id]
    return {"status":"waiting"}

@router.post("/find_online_status")
async def find_online_status(user_id: int = Body(..., embed=True)):
    if user_id in online_queue_status:
        return online_queue_status[user_id]
    return {"status": "not_in_queue"}

@router.post("/cancel_find_online")
async def cancel_find_online(user_id: int = Body(..., embed=True)):
    if user_id in online_queue:
        online_queue.remove(user_id)
    if user_id in online_queue_status:
        del online_queue_status[user_id]
    return {"status": "cancelled"}
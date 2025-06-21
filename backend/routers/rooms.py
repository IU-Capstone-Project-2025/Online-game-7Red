from fastapi import APIRouter, Body, HTTPException
from backend.models import  JoinRoomRequest
from backend.database import (assigned_id_exists, password_exist, create_game_room, add_user_to_room, 
search_game_room)
import random
router = APIRouter(prefix="/rooms", tags=["rooms"])


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
            

@router.get("/create")
async def create_room(user_id: int):
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
    await add_user_to_room(request.user_id, request.assigned_id)
    return {"message": "User added to the room"}


@router.post("{room_id}/leave")
async def leave_room(room_id: str, player_id: int = Body(..., embed=True)):
    #
    return {
        "message": "Not implemented yet"
    }

@router.post("/{room_id}/ready")
async def player_ready(room_id: str, player_id: int = Body(..., embed=True)):
    # Recieve ready messages from players
    return {"message": "Not implemented yet"}

@router.post("{room_id}/not_ready")
async def player_ready(room_id: str, player_id: int = Body(..., embed=True)):
    # Recieve not_ready messages from players
    return {"message": "Not implemented yet"}



@router.post("/{room_id}/state")
async def update_game_state(room_id: str, state: dict = Body(...)):
    # Update the game state for a room.
    # Flutter sends the new state
    # Save the state in the database
    return {"message": "Not implemented yet"}

@router.get("/{room_id}/state")
async def get_game_state(room_id: str):
    # Get the current game state for a room.
    # Get the state from the database
    return {"message": "Not implemented yet"}


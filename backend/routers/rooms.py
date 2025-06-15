from fastapi import APIRouter, Body
from backend.models import CreateRoomRequest, JoinRoomRequest

router = APIRouter(prefix="/rooms", tags=["rooms"])

@router.post("/create")
async def create_room(request: CreateRoomRequest):
    # dummy
    return {
        "message": "Room created",
        "room_id": request.room_id
    }

@router.post("/join")
async def join_room(request: JoinRoomRequest):
    # dummy
    return {
        "message": "Joined room",
        "room_id": request.room_id
    }
    

@router.post("/{room_id}/ready")
async def player_ready(room_id: str, player_id: int = Body(..., embed=True)):
    # Recieve ready messages from players
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
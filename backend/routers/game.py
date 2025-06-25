from fastapi import APIRouter

router = APIRouter(prefix="/game", tags=["game"])

@router.post("/{room_id}/player/{player_id}/result")
async def post_player_result(room_id: str, player_id: int, result: str):
    #
    return {"message": "Not implemented yet"}

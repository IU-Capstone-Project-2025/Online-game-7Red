from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException
from typing import Dict
from backend.red7state import Red7GameState

router = APIRouter(prefix="/game", tags=["game"])

class GameManager:
    def __init__(self):
        self.active_games: Dict[str, Red7GameState] = {}  # room_id: Red7GameState
        self.connections: Dict[str, WebSocket] = {}  # player_id: websocket

    async def create_game(self, room_id: int) -> Red7GameState:
        """Initialize a new game instance"""
        if room_id not in self.active_games:
            game = Red7GameState(room_id)
            await game.get_room_players_info_from_db()  # Load players from DB
            self.active_games[room_id] = game
            game.start_game()
        return self.active_games[room_id]

manager = GameManager()

@router.websocket("/{room_id}/ws")
async def game_websocket(websocket: WebSocket, room_id: int, player_id: int):
    await websocket.accept()
    manager.connections[player_id] = websocket
    
    try:
        # Initialize or join game
        game = await manager.create_game(room_id)
        
        # Send initial game state
        await websocket.send_json({
            "type": "initialized",
            "names": game.players_name_list,
            "id": game.players_id_list,
            "my_hand": game.players[player_id]["hand"]
        })

        while True:

            data = await websocket.receive_json()

            player_id = data["my_id"]
            room_id = data["room_id"]
            my_palette_ch = data["my_pallete_ch"]
            new_rule = data["curr_rule"]
            new_hand = data["my_hand"]
            new_palette = data["pallete"]

            
            if game.current_player == player_id:
                is_winning = game.check_move(
                    player_id=player_id,
                    card_played=my_palette_ch,
                    new_rule=new_rule,
                    new_hand=new_hand,
                    new_palette=new_palette
                )
                
                if is_winning:
                    await websocket.send_json({"type": "right_turn"})
                else:
                    await websocket.send_json({"type": "wrong_result", 
                                               "my_pallete_ch": my_palette_ch,
                                               "return_rule": game.current_rule})
                
                await broadcast_game_state(game, player_id, is_winning, my_palette_ch)
                game.next_player()

    except WebSocketDisconnect:
        del manager.connections[player_id]
        # Handle player disconnect logic
    except Exception as e:
        await websocket.close(code=1011, reason=str(e))

async def broadcast_game_state(game: Red7GameState, cur_player_id: int, is_winning: bool, my_palette_ch: str):
    """Send updated game state to all players in room"""
    if not game:
        return

    for player_id in game.players_id_list:
        if player_id in manager.connections:
            if player_id == cur_player_id:
                await manager.connections[player_id].send_json({
                    "type": "change_turn",
                    "loose": 0 if is_winning else 1,
                    "id_did": cur_player_id,
                    "his_palette_ch": my_palette_ch,
                    "rule": game.current_rule,
                    "next_lose": 0 if game.check_winning_at_beginning(game.current_player) else 1
                })
            else: 
                await manager.connections[player_id].send_json({
                    "type": "change_turn",
                    "loose": 0 if is_winning else 1,
                    "id_did": cur_player_id,
                    "his_palette_ch": my_palette_ch,
                    "rule": game.current_rule,
                    "next_lose": 0 if game.check_winning_at_beginning(game.current_player) else 1
                })
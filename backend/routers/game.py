from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
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

@router.websocket("/{assigned_id}/ws")
async def game_websocket(
    websocket: WebSocket,
    assigned_id: str,
    player_id: int = Query(...)):
    await websocket.accept()
    print(f"Connected: assigned_id={assigned_id}, player_id={player_id}", flush=True)
    manager.connections[player_id] = websocket
    #room_id = await return_room_id_using_assigned_id(str(assigned_id))
    room_id = assigned_id
    print(f"Room ID: {room_id}", flush=True)  # Debug room ID lookup
    try:
        # Initialize or join game
        game = await manager.create_game(room_id)
        
        print(f"names: {game.players_name_list}, ids: {game.players_id_list}, my_hand: {game.players[player_id]}", flush=True) 
        # Send initial game state
        await websocket.send_json({
            "type": "initialized",
            "names": game.players_name_list,
            "id": game.players_id_list,
            "my_hand": game.players[player_id]["hand"]
        })

        while True:

            data = await websocket.receive_json()

            type_cur = data["type"] #my_turn or time_out
            player_id = data["my_id"]
            room_id = data["my_room"]
            my_palette_ch = data["my_pallete_ch"]
            new_rule = data["rule_ch"]
            new_hand = data["my_hand"]
            new_palette = data["pallete"]

            print(f"Got from front {type_cur}, {player_id}, {room_id}, {my_palette_ch}, {new_rule}, {new_hand}, {new_palette}")

            if  type_cur == "my_turn" and game.current_player == player_id:
                if not game.players[player_id]["possible_moves"]:
                    is_winning = game.check_move(
                        player_id=player_id,
                        new_rule=new_rule,
                        new_hand=new_hand,
                        new_palette=new_palette
                    )
                else:
                    print("Check in pos moves", flush=True)
                    is_winning = game.check_in_possible_moves(
                        player_id=player_id,
                        new_rule=new_rule,
                        new_hand=new_hand,
                        new_palette=new_palette
                    )
                
                if is_winning:
                    await websocket.send_json({"type": "right_turn"})
                else:
                    print(f"old_r {game.cur_rule_card} new_r {new_rule} pal_ch {my_palette_ch}")
                    await websocket.send_json({"type": "wrong_turn", 
                                               "my_pallete_ch": my_palette_ch,
                                               "rule_ch": new_rule,
                                               "old_rule": game.cur_rule_card})
                    continue 

            elif type_cur == "time_out":
                is_winning = False

            print(f'Cur player befor {game.current_player}')
            game.next_player()
            print(f'Cur player after {game.current_player}')
            next_lose = not game.check_winning_at_beginning(game.current_player)
            print(f"Next lose out loop {next_lose}")
            await broadcast_game_state(game, player_id, is_winning, my_palette_ch, next_lose)
            print(f"Next lose out loop {next_lose}")
            max_checks = len(game.players_id_list)
            while next_lose and max_checks > 0:
                max_checks -= 1
                cur_player = game.current_player
                game.next_player()
                next_lose = not game.check_winning_at_beginning(game.current_player)
                print(f"Next lose in loop {next_lose}")
                await broadcast_game_state(game, cur_player, 0, None, next_lose)
            

    except WebSocketDisconnect:
        print("hrre", flush=True)
        del manager.connections[player_id]
        # Check if room is now empty
        game = manager.active_games.get(room_id)
        if game and all(p not in manager.connections for p in game.players_id_list):
            del manager.active_games[room_id]
            print("hrre", flush=True)
            #delete_game_room(room_id)
    except Exception as e:
        print("heeerre", flush=True)
        print(e, flush=True)
        print(str(e), flush=True)
        await websocket.close(code=1011, reason=str(e))

async def broadcast_game_state(game: Red7GameState, cur_player_id: int, is_winning: bool, my_palette_ch: str, next_lose: bool):
    """Send updated game state to all players in room"""
    if not game:
        return

    print(f"is_win {is_winning}, cur_player {cur_player_id}, pal_ch {my_palette_ch}, rule {game.current_rule}, next_lose {next_lose}")
    for player_id in game.players_id_list:
        if player_id in manager.connections:
            await manager.connections[player_id].send_json({
                "type": "change_turn",
                "loose": 0 if is_winning else 1, #imp several 2 if "next_lose" is 1
                "id_did": cur_player_id, #imp (check)
                "his_palette_ch": my_palette_ch,
                "rule": game.current_rule,
                "next_lose": 1 if next_lose else 0
            })

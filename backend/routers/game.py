from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from typing import Dict, List
from backend.red7state import Red7GameState

router = APIRouter(prefix="/game", tags=["game"])

class GameManager:
    def __init__(self):
        self.active_games: Dict[str, Red7GameState] = {}  # room_id: Red7GameState
        self.connections: Dict[str, WebSocket] = {}  # player_id: websocket
        self.exited_id: Dict[str, List] = {}
        self.commonVar: Dict[str, List] = {}

    async def create_game(self, room_id: int) -> Red7GameState:
        """Initialize a new game instance"""
        if room_id not in self.active_games:
            game = Red7GameState(room_id)
            await game.get_room_players_info_from_db()  # Load players from DB
            self.active_games[room_id] = game
            if room_id not in self.exited_id:
                self.exited_id[room_id] = []
            if room_id not in self.commonVar:
                self.commonVar[room_id] = {"exit_was": False, "type_cur": None, "ex_player": None}
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
    # exit_was = False
    # type_cur = None
    room_id = assigned_id
    print(f"Room ID: {room_id}", flush=True)  # Debug room ID lookup
    try:
        # Initialize or join game
    while connection_active:
        try:
            await update_room_state(str(assigned_id), "playing")
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

                if data["type"] == "exit":
                    print(f'Player {data["my_id"]} requested exit', flush=True)
                    manager.exited_id[room_id].append(data["my_id"])
                    manager.commonVar[room_id]['exit_was'] = True
                    manager.commonVar[room_id]['ex_player'] = data["my_id"]
                    break

                type_cur = data["type"] #my_turn or time_out
                manager.commonVar[room_id]['type_cur'] = type_cur
                player_id = data["my_id"]
                #room_id_from_json = data["my_room"]
                my_palette_ch = data["my_pallete_ch"]
                new_rule = data["rule_ch"]
                new_hand = data["my_hand"]
                new_palette = data["pallete"]

                print(f"Got from front {type_cur}, {player_id}, {room_id}, {my_palette_ch}, {new_rule}, {new_hand}, {new_palette}", flush=True)
                print(f"turn {type_cur}, player_id {player_id}, game.current_player {game.current_player}", flush=True)
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
                    #game.players[player_id]["active"] = False
                    
                    # Safely handle exited_id
                    if room_id not in manager.exited_id:
                        manager.exited_id[room_id] = []
                    if player_id not in manager.exited_id[room_id]:
                        manager.exited_id[room_id].append(player_id)
                    
                    print(f"Player {player_id} timed out in room {room_id}", flush=True)

                else:
                    print("something else happened...", flush=True)
                    is_winning = True
                    print(f"this is type now: {type_cur}", flush=True)

                #print(f'ids that exited: {manager.exited_id[room_id]}', flush=True)
                print(f'Cur player before {game.current_player}')
                game.next_player()
                print(f'Cur player after {game.current_player}')
                
                if game.current_player in manager.exited_id[room_id] and type_cur == "my_turn":
                    print("HERE PROBLEM", flush=True)
                    next_lose = True
                    manager.exited_id[room_id].remove(game.current_player)
                    print(f'ids that exited after removal: {manager.exited_id[room_id]}', flush=True)

                else:
                    print("OR HERE", flush=True)
                    next_lose = not game.check_winning_at_beginning(game.current_player)
                # print("SSSSSSS", flush=True)
                # print(f"Next lose out loop {next_lose}")
                await broadcast_game_state(game, player_id, is_winning, my_palette_ch, new_rule, next_lose)
                # print("SSSSSSS", flush=True)
                # print(f"Next lose out loop {next_lose}")
                max_checks = len(game.players_id_list)
                while next_lose and max_checks > 0:
                    print(max_checks)
                    max_checks -= 1
                    cur_player = game.current_player
                    game.next_player()
                    next_player = game.current_player
                    if game.players[next_player]["active"]:
                        if next_player in manager.exited_id[room_id]:
                            next_lose = True
                            manager.exited_id[room_id].remove(next_player)

                        else:
                            next_lose = not game.check_winning_at_beginning(next_player)

                        try:
                            print("SSSHHH", flush=True)
                            print(f"Next lose in loop {next_lose}", flush=True)
                        except Exception as e:
                            print(f"CRASH BETWEEN PRINTS: {e}", flush=True)
                        await broadcast_game_state(game, cur_player, False, None, None, next_lose)
                    else:
                        print(game.players, flush=True)
                

        except WebSocketDisconnect:
            print(f"exit state: {manager.commonVar[room_id]['exit_was']}", flush=True)
            if not manager.commonVar[room_id]['exit_was']:
                print("Changed state in disconnect", flush=True)
                game.players[player_id]["active"] = False
                
            elif manager.commonVar[room_id]['exit_was'] and manager.commonVar[room_id]['type_cur'] == "time_out":
                print("Cexit_was true and type time_out", flush=True)
                active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
                print(f'active players before in here: {active_players}')
                game.players[manager.commonVar[room_id]['ex_player']]["active"] = False
                active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
                print(f'active players in here: {active_players}')
                
            # if type_cur == "time_out":
            #     game.players[player_id]["active"] = False
            connection_active = False
            break
            # print(f"{manager.connections}", flush=True)
            # print(f"{manager.active_games}", flush=True)
            # del manager.connections[player_id]
            # # Check if room is now empty
            # game = manager.active_games.get(room_id)
            # if game and all(p not in manager.connections for p in game.players_id_list):
            #     del manager.active_games[room_id]
            #     print("hrre", flush=True)
            #     #delete_game_room(room_id)
            # print(f"{manager.connections}", flush=True)
            # print(f"{manager.active_games}", flush=True)
            # if len(manager.connections) == 0:
            #     await update_room_state(str(assigned_id), "finished")
        except Exception as e:
            print(f"Unexpected error: {e}", flush=True)
            connection_active = False
            await websocket.close(code=1011)
            break

        finally:
            # Cleanup code that doesn't send messages
            #print(game.players, flush=True)
            print(f"{manager.connections}", flush=True)
            print(f"{manager.active_games}", flush=True)
            if player_id in manager.connections:
                del manager.connections[player_id]

            game = manager.active_games.get(assigned_id)
                # if player_id in game.players:
                #     game.players[player_id]["active"] = False
                
                # Check if room is empty using active status, not connections
                #if all(not p["active"] for p in game.players.values()):
            if game and all(p not in manager.connections for p in game.players_id_list):
                del manager.active_games[assigned_id]
                del manager.exited_id[assigned_id]
                del manager.commonVar[assigned_id]
                await update_room_state(str(assigned_id), "finished")
            # elif len(manager.connections) == 0:
            #     del manager.active_games[assigned_id]
            #     await update_room_state(str(assigned_id), "finished")
            print(f"{manager.connections}", flush=True)
            print(f"{manager.active_games}", flush=True)
    

async def broadcast_game_state(game: Red7GameState, cur_player_id: int, is_winning: bool, my_palette_ch: str, new_rule: str, next_lose: bool):
    """Send updated game state to all players in room"""
    if not game:
        return

    print(f"is_win {is_winning}, cur_player {cur_player_id}, pal_ch {my_palette_ch}, rule {new_rule}, next_lose {next_lose}", flush=True)

    print(f"NO PRINT WHYY", flush=True)
    active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
    if len(active_players) == 1:
        print(f'active players now {active_players}', flush=True)
        for player_id in game.players_id_list:
            if player_id in manager.connections:
                await manager.connections[player_id].send_json({
                    "type": "change_turn",
                    "lose": False,
                    "id_did": cur_player_id, #imp (check)
                    "his_pallete_ch": my_palette_ch,
                    "rule_ch": new_rule,
                    "next_lose": False
                })

    else:
        for player_id in game.players_id_list:
            if player_id in manager.connections:
                await manager.connections[player_id].send_json({
                    "type": "change_turn",
                    "lose": 0 if is_winning else 1, #imp several 2 if "next_lose" is 1
                    "id_did": cur_player_id, #imp (check)
                    "his_pallete_ch": my_palette_ch,
                    "rule_ch": new_rule,
                    "next_lose": 1 if next_lose else 0
                })
    print(active_players, flush=True)
    if not is_winning:
        game.players[cur_player_id]["active"] = False
        print(f"CHANGE TO INACTIVE {cur_player_id}", flush=True)
    active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
    print(active_players, flush=True)

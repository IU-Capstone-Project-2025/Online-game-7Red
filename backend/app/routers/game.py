#importing necessary libraries/functions 
from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from typing import Dict, List
from app.red7state import Red7GameState
from app.database import update_room_state, update_win_streak, update_win_streak, check_and_award_win_streak
import asyncio

#creating FastAPI router for endpoints for game with other players
router = APIRouter(prefix="/api/game", tags=["game"])

#class that manages websocket connections and games in game rooms
class GameManager:
    def __init__(self):
        self.active_games: Dict[str, Red7GameState] = {}  #room_id: Red7GameState (stores active game rooms' ids)
        self.connections: Dict[str, WebSocket] = {}  #player_id: websocket (stores players' connectiond)
        self.exited_id: Dict[str, List] = {}  #room_id: list (stores ids of exited players)
        self.commonVar: Dict[str, List] = {} #room_id: list (stores common variables for a game room)
        #locks for managing race condition situations (when players connect to a room/make a move)
        self._init_lock = asyncio.Lock() 
        self._state_lock = asyncio.Lock()

    #function that creates a game
    async def create_game(self, room_id: int) -> Red7GameState:
        """Thread-safe game initialization"""
        if room_id in self.active_games:
            return self.active_games[room_id]
        
        async with self._init_lock:
            if room_id not in self.active_games:
                try:
                    print(f"[In function create_game] Initializing new game for room {room_id}")
                    game = Red7GameState(room_id)
                    
                    #initializing game state
                    await game.get_room_players_info_from_db()
                    await game.start_game()
                    
                    #setting up room related data
                    self.active_games[room_id] = game
                    self.exited_id[room_id] = []
                    self.commonVar[room_id] = {
                        "exit_was": False,
                        "type_cur": None,
                        "final_winner": None
                    }
                    
                    print(f"[In function create_game] Game initialized for room {room_id}")
                    return game
                
                #exception handling
                except Exception as e:
                    print(f"[In function create_game] Game initialization failed: {e}")
                    if room_id in self.active_games:
                        del self.active_games[room_id]
                    raise
        
        return self.active_games[room_id]

#connection manager
manager = GameManager()

#creating websocket-related endpoint for a game with other players
@router.websocket("/{assigned_id}/ws")
async def game_websocket(
    websocket: WebSocket,
    assigned_id: str,
    player_id: int = Query(...)):
    await websocket.accept()
    connection_active = True
    print(f"Connected: assigned_id={assigned_id}, player_id={player_id}", flush=True)

    while connection_active:
        try:
            #adding player to the dictionary of connections
            manager.connections[player_id] = websocket
            room_id = assigned_id
            print(f"Room ID: {room_id}", flush=True) 
            
            #changing room's state in database
            await update_room_state(str(assigned_id), "playing")

            #creating a game
            game = await manager.create_game(room_id)
            
            print(f"[Player ({game.players[player_id]['name']}, {player_id}) got data] names: {game.players_name_list}, ids: {game.players_id_list}, my_hand: {game.players[player_id]}", flush=True) 

            #sending initial game state
            await websocket.send_json({
                "type": "initialized",
                "names": game.players_name_list,
                "id": game.players_id_list,
                "my_hand": game.players[player_id]["hand"]
            })

            while True:
                #receiving player's move from frontend
                data = await websocket.receive_json()

                #handling of player's explicit exit
                if data["type"] == "exit":
                    print(f'Player {data["my_id"]} requested exit', flush=True)
                    manager.exited_id[room_id].append(data["my_id"])
                    manager.commonVar[room_id]['exit_was'] = True
                    break

                #storing recieved data as variables
                type_cur = data["type"] #my_turn, time_out, or exit
                manager.commonVar[room_id]['type_cur'] = type_cur
                player_id = data["my_id"]
                my_palette_ch = data["my_pallete_ch"]
                new_rule = data["rule_ch"]
                new_hand = data["my_hand"]
                new_palette = data["pallete"]

                print(f"Got from frontend turn_type-{type_cur}, player_id-{player_id}, room_id-{room_id}, palette_change-{my_palette_ch}, rule_change-{new_rule}, new_hand-{new_hand}, new_palette-{new_palette}", flush=True)
                print(f"Turn: {type_cur}, player_id: {player_id}, game.current_player: {game.current_player}", flush=True)

                #according to the move type, checking the correctness of player's move (whether or not a player makes a winning move in their turn)
                if  type_cur == "my_turn" and game.current_player == player_id:
                    async with manager._state_lock:  #acquire lock before accessing game state
                        #doing a particular move check if player's dictionary of possible moves is empty (happens on the very first move of a player)
                        if not game.players[player_id]["possible_moves"]:
                            print("Checking the move on its own (using check_move)", flush=True)
                            is_winning = game.check_move(
                                player_id=player_id,
                                new_rule=new_rule,
                                new_hand=new_hand,
                                new_palette=new_palette
                            )

                        #doing a move check in dictionary of possible moves
                        else:
                            print("Checking in dictionary of possible moves", flush=True)
                            is_winning = game.check_in_possible_moves(
                                player_id=player_id,
                                new_rule=new_rule,
                                new_hand=new_hand,
                                new_palette=new_palette
                            )
                        print(f"Check happened, output of is_winning condition: {is_winning}", flush=True)
                    
                    #if the move is correct, sending message to frontend
                    if is_winning:
                        print(f"Player made a correct turn, sending 'right_turn' to frontend!", flush=True)
                        await websocket.send_json({"type": "right_turn"})
                    #if the move is incorrect, sending message to the frontend and going to the beginning of the while loop (recieving another move attempt from frontend from the same player)
                    else:
                        print(f"Player tried to make an incorrect move!", flush=True)
                        try:
                            print("Sending 'wrong_turn' response with data:", flush=True)
                            print(f"old_rule: {game.cur_rule_card}, new_rule: {new_rule}, palette_change: {my_palette_ch}", flush=True)
                            await asyncio.wait_for(
                                websocket.send_json({
                                    "type": "wrong_turn",
                                    "my_pallete_ch": my_palette_ch,
                                    "rule_ch": new_rule,
                                    "old_rule": game.cur_rule_card
                                }),
                                timeout=5.0
                            )
                            print("'wrong_turn' sent successfully!", flush=True)
                        except asyncio.TimeoutError:
                            print("[ERROR] Frontend timed out! Closing connection.", flush=True)
                            await websocket.close()
                            break
                        continue

                #if move type is time_out, player loses automatically
                elif type_cur == "time_out":
                    is_winning = False                
                    print(f"Player {player_id} timed out in room {room_id}", flush=True)

                else:
                    print("something else happened...", flush=True)
                    #is_winning = True
                    print(f"this is type now: {type_cur}", flush=True)

                #print(f'Cur player before {game.current_player}')
                prev_player = game.current_player
                game.next_player() #changing current player to the next one
                #print(f'Cur player after {game.current_player}')
                print(f"List of EXITED IDS: {manager.exited_id[room_id]}")

                is_active = True #variable for correctly handling switch between active/inactive states of a player
                
                #handling situations when some player exited the room before their turn
                if game.current_player in manager.exited_id[room_id] and type_cur == "my_turn":
                    print(f"Player {game.current_player} exited the room before their turn!", flush=True)
                    next_lose = True
                    manager.exited_id[room_id].remove(game.current_player)
                    is_active = False
                    print(f"Player {game.current_player} was removed from EXITED IDS", flush=True)
                    print(f'EXITED IDS after removal: {manager.exited_id[room_id]}', flush=True)

                #handling situations when some player (pl 1) exited the room before their turn, and the player (pl 2) before (orfer: pl 2 -> pl 1) exited/timed out in their turn
                elif game.current_player in manager.exited_id[room_id] and type_cur == "time_out" and len(game.players_id_list) > 2:
                    print(f"Player {game.current_player} exited the room, but the player {prev_player} timed out", flush=True)
                    next_lose = True
                    manager.exited_id[room_id].remove(game.current_player)
                    is_active = False
                    print(f"Player {game.current_player} was removed from EXITED IDS", flush=True)
                    print(f'EXITED IDS after removal: {manager.exited_id[room_id]}', flush=True)

                #normal situation when no players exited the game
                else:
                    print("No one exited the game not on their turn", flush=True)
                    if type_cur == "time_out":
                        game.players[player_id]['active'] = False
                        next_lose = not game.check_winning_at_beginning(game.current_player)
                        game.players[player_id]['active'] = True
                    next_lose = not game.check_winning_at_beginning(game.current_player)

                #sending message about player's made move to the frontend
                await broadcast_game_state(game, player_id, is_winning, my_palette_ch, new_rule, next_lose)

                #handling of the case when players continuously lose at the beginning of their turns (without an opportynity to make a move)
                active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
                max_checks = len(active_players)
                while next_lose and max_checks > 0:
                    max_checks -= 1
                    print(f"Players that got next_lose = True sequentially: {len(active_players) - max_checks}", flush=True)
                    cur_player = game.current_player
                    game.next_player()
                    next_player = game.current_player
                    if game.players[next_player]["active"]:
                        if next_player in manager.exited_id[room_id]:
                            print(f"Next player {next_player} is in EXITED IDS", flush=True)
                            next_lose = True
                            manager.exited_id[room_id].remove(next_player)
                        elif not is_active:
                            print(f"Current player {cur_player} was in EXITED IDS and became inactive", flush=True)
                            game.players[cur_player]["active"] = False
                            next_lose = not game.check_winning_at_beginning(next_player)
                        else:
                            print("No exited players need handling", flush=True)
                            if type_cur == "time_out":
                                game.players[cur_player]['active'] = False
                                next_lose = not game.check_winning_at_beginning(next_player)
                                game.players[cur_player]['active'] = True
                            else:
                                next_lose = not game.check_winning_at_beginning(next_player)


                        print(f"Will the next player lose at the beginning: {next_lose}", flush=True)

                        await broadcast_game_state(game, cur_player, False, None, None, next_lose)
                    else:
                        print("The player has inactive state (game.players[next_player]['active'] != True)!", flush=True)
                
        #websocket disconnet handling
        except WebSocketDisconnect:
            print(f"Player {player_id} entered WebSocketDisconnect", flush=True)
            print(f"Did anyone exit the game: {manager.commonVar[room_id]['exit_was']}", flush=True)
            next_player_id = get_next_player_id(game, player_id)
            active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]

            if not manager.commonVar[room_id]['exit_was']:
                print("Changed state in disconnect", flush=True)
                print(f'Active players before: {active_players}')
                game.players[player_id]["active"] = False
                print(f"Player {player_id} became inactive", flush=True)
                
            elif next_player_id in manager.exited_id[room_id] and manager.commonVar[room_id]['type_cur'] == "time_out":
                print("Situation when a player timed out and the next player exited happened", flush=True)
                print(f'Active players before: {active_players}')
                game.players[next_player_id]["active"] = False
                print(f"Player {player_id} became inactive", flush=True)

            active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
            print(f'Active players now: {active_players}')
                
            connection_active = False
            break
        
        #exception handling
        except Exception as e:
            print(f"Unexpected error: {e}", flush=True)
            connection_active = False
            await websocket.close(code=1011)
            break
        
        #handling of the game's end for players
        finally:
            print(f"In manager.connections before finally-block: {manager.connections}", flush=True)
            print(f"In manager.active_games before finally-block: {manager.active_games}", flush=True)
            if game.assigned_id not in manager.active_games:
                return
            #getting the winner's id
            cur_winner = manager.commonVar[game.assigned_id]["final_winner"]
            #getting the list of active players
            active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
            print(f"Active players in finally-block {active_players}", flush=True)
            #if a player is in the dictionary with connections, deleting the player
            if player_id in manager.connections:
                del manager.connections[player_id]
                connection_active = False
                print(f"Current_winner: {cur_winner}, list of exited players: {manager.exited_id[room_id]}", flush=True)

                #updating statistics in the database
                if (cur_winner == player_id and (player_id not in manager.exited_id[room_id])) or (cur_winner == None and len(active_players) == 0):
                    print(f"Player {player_id} won!", flush=True)
                    await update_win_streak(player_id, True)
                    await check_and_award_win_streak(player_id)
                else:
                    print(f"Player {player_id} lost", flush=True)
                    await update_win_streak(player_id, False)
                    await check_and_award_win_streak(player_id)

            game = manager.active_games.get(assigned_id)

            #checking if the game is finished - there are no players in the dictionary with connections that were the members of the game
            if game and all(p not in manager.connections for p in game.players_id_list):
                #deleting the data related to the game and game room
                del manager.active_games[assigned_id]
                del manager.exited_id[assigned_id]
                del manager.commonVar[assigned_id]
                #updating room's state in database
                await update_room_state(str(assigned_id), "finished")
                print(f"The game in room {assigned_id} finished! Room state was updated, room data was cleaned")

            print(f"In manager.connections after finally-block: {manager.connections}", flush=True)
            print(f"In manager.active_games after finally-block: {manager.active_games}", flush=True)
    
#function to send messages to the frontend after a player made an appropriate move
async def broadcast_game_state(game: Red7GameState, cur_player_id: int, is_winning: bool, my_palette_ch: str, new_rule: str, next_lose: bool):
    """Send updated game state to all players in room"""
    if not game:
        return
    print("Sending a message via broadcast_game_state", flush=True)
    print(f"Data: is_winning-{is_winning}, current_player-{cur_player_id}, palette_change-{my_palette_ch}, rule_change-{new_rule}, next_lose-{next_lose}", flush=True)

    #getting all the active players
    active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]

    #sending a message about a player's move to every active player in the room
    for player_id in game.players_id_list:
        if player_id in manager.connections:
            await manager.connections[player_id].send_json({
                "type": "change_turn",
                "lose": 0 if is_winning else 1,
                "id_did": cur_player_id,
                "his_pallete_ch": my_palette_ch,
                "rule_ch": new_rule,
                "next_lose": 1 if next_lose else 0
            })

    print(f"Checking active players in broadcast_game_state after sending a message: {active_players}", flush=True)

    #if a player made a losing move, changing player's active state to False
    if not is_winning:
        game.players[cur_player_id]["active"] = False
        print(f"CHANGE TO INACTIVE {cur_player_id}", flush=True)
        game.check_winning_at_beginning(game.current_player)
    
    #if a player made a winning move, the player is considered a winner
    else:
        manager.commonVar[game.assigned_id]["final_winner"] = cur_player_id
        
    active_players = [pid for pid in game.players_id_list if game.players[pid]["active"]]
    print(f"Checking active players in broadcast_game_state after updating players' states: {active_players}", flush=True)

#function that gets the id of the next player according to the given player id
def get_next_player_id(game: Red7GameState, cur_player_id: int):
    my_list = game.players_id_list
    index = my_list.index(cur_player_id)
    if index + 1 < len(my_list):
        next_value = my_list[index + 1]
        next_pl_ind = index + 1
    else:
        next_value =  my_list[0]
        next_pl_ind = 0
    print(f"[In function get_next_player_id] After {cur_player_id} goes {next_value}", flush=True)
    return next_value, next_pl_ind
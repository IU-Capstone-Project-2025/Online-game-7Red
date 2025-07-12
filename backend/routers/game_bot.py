#importing necessary libraries/functions 
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict
from backend.database import get_profile_name_by_user_id, increment_bot_wins, check_and_award_bot_wins
from backend.routers.bot import start_bot_game, bot_move, encode_card, decode_card
from backend.red7state import Red7GameState

#creating FastAPI router for endpoints for game with bot
router = APIRouter(prefix="/ai_game", tags=["AI Game"])

#dictionary of active connections: player_id: websocket
active_connections: Dict[int, WebSocket] = {}

#creating websocket-related endpoint for a game with bot
@router.websocket("/{player_id}")
async def websocket_game(websocket: WebSocket, player_id: int):
    await websocket.accept() #accepting websocket
    active_connections[player_id] = websocket  #registering websocket connection
    final_winner = None #variable for tracking current winner
    try:
        #getting player's information from profile
        name = await get_profile_name_by_user_id(player_id)
        
        #initializing game
        game_data = await start_bot_game()
        session = game_data["session_id"]
        game = Red7GameState(session)
        game.deal_cards_bot_game(player_id, game_data["obs"]["hand_human"], name)
        
        #sending initial data to frontend
        await websocket.send_json({
            "type": "initialized",
            "names": [name, "bot"],
            "id": [player_id, -1],
            "my_hand": game_data["obs"]["hand_human"]
        })
        
        #main game loop
        while True:
            #receiving player's move from frontend
            data = await websocket.receive_json()
            
            type_cur = data["type"]
            my_palette_ch = data["my_pallete_ch"]
            new_rule = data["rule_ch"]
            new_hand = data["my_hand"]
            new_palette = data["pallete"]

            print(f"Got from front {type_cur}, {player_id}, {my_palette_ch}, {new_rule}, {new_hand}, {new_palette}")

            #according to the move type, checking the correctness of player's move (whether or not a player makes a winning move in their turn)
            if type_cur == "my_turn":
                #doing a particular move check if player's dictionary of possible moves is empty (happens on the very first move of a player)
                if not game.players[player_id]["possible_moves"]:
                    is_winning = game.check_move(
                        player_id=player_id,
                        new_rule=new_rule,
                        new_hand=new_hand,
                        new_palette=new_palette
                    )

                #doing a move check in dictionary of possible moves
                else:
                    print("Check in pos moves", flush=True)
                    is_winning = game.check_in_possible_moves(
                        player_id=player_id,
                        new_rule=new_rule,
                        new_hand=new_hand,
                        new_palette=new_palette
                    )
                
                #if the move is correct, sending message to frontend
                if is_winning:
                    await websocket.send_json({"type": "right_turn"})
                #if the move is incorrect, sending message to the frontend and going to the beginning of the while loop (recieving another move attempt from frontend from the same player)
                else:
                    print(f"old_r {game.cur_rule_card} new_r {new_rule} pal_ch {my_palette_ch}")
                    await websocket.send_json({"type": "wrong_turn", 
                                               "my_pallete_ch": my_palette_ch,
                                               "rule_ch": new_rule,
                                               "old_rule": game.cur_rule_card})
                    continue 
            
            #if move type is time_out, player loses automatically
            elif type_cur == "time_out":
                is_winning = False
                final_winner = 1
            else:
                print("something else happened...", flush=True)
                continue 

            bot_response = None
            #if player makes correct move, response from bot is recieved
            if type_cur == "my_turn" and is_winning:
                print(f'{my_palette_ch} {new_rule}', flush=True)
                card_play = encode_card(my_palette_ch) if my_palette_ch is not None else 0
                rule_change = encode_card(new_rule) if new_rule is not None else 0
                action = [card_play, rule_change]
                bot_response = await bot_move(session, action)

            #registering current round's winner
            final_winner = bot_response["winner"] if bot_response != None else None
            #checking whether or not bot loses at the beginning of its turn 
            if bot_response:
                next_lose = True if bot_response["winner"] == 0 else False
            else:
                next_lose = False
            #sending message about player's made move to the frontend
            await broadcast_game_state(game, player_id, is_winning, my_palette_ch, new_rule, next_lose, player_id)
            print(game.players)
            print(game.cur_rule_card)
            print(game.current_rule)
            print()
            print(bot_response)

            #handling bot turn if applicable (it only exists if player won on their turn)
            if bot_response:
                is_winning = not bot_response["done"]
                #if bot made a move that doesn't end the game, sending a message to the frontend with bot's made move
                if is_winning:
                    pal_ch = decode_card(bot_response["bot_action"][0]) if bot_response["bot_action"][0] != 0 else None
                    rule_ch = decode_card(bot_response["bot_action"][1]) if bot_response["bot_action"][1] != 0 else None

                    if pal_ch != None:
                        game.players[-1]["palette"].append(pal_ch)
                
                    if rule_ch != None:
                        game.cur_rule_card = rule_ch
                        game.current_rule = game.rule_to_int(rule_ch[0])

                    next_lose = not game.check_winning_at_beginning(player_id)
                    await broadcast_game_state(game, -1, is_winning, pal_ch, rule_ch, next_lose, player_id)
                #if bot made a move that ends the game, sending a message about it to the frontend
                else:
                    print(bot_response["winner"])
                    is_winning = True if bot_response["winner"] == 1 else False
                    await broadcast_game_state(game, -1, is_winning, None, None, is_winning, player_id)
            print("After bot")
            print(game.players)
            print(game.cur_rule_card)
            print(game.current_rule)

            #handling of the case when players continuously lose at the beginning of their turns (without an opportynity to make a move)
            max_checks = len(game.players_id_list)
            while next_lose and max_checks > 0:
                print(max_checks)
                max_checks -= 1
                cur_player = game.current_player
                game.next_player()
                next_player = game.current_player
                if game.players[next_player]["active"]:
                    next_lose = not game.check_winning_at_beginning(next_player)
                    try:
                        print("SSSHHH", flush=True)
                        print(f"Next lose in loop {next_lose}", flush=True)
                    except Exception as e:
                        print(f"CRASH BETWEEN PRINTS: {e}", flush=True)
                    await broadcast_game_state(game, cur_player, False, None, None, next_lose)
                else:
                    print(game.players)

    #websocket disconnet handling
    except WebSocketDisconnect:
        print(f"Open bot connections before: {active_connections}", flush=True)
        active_connections.pop(player_id, None)  #cleaning up inactive connections
        print(f"Open bot connections after: {active_connections}", flush=True)
        #updating statistics in the database
        if final_winner == 0:
            await increment_bot_wins(player_id) 
            await check_and_award_bot_wins(player_id)
    #exception handling
    except Exception as e:
        await websocket.send_json({"error": str(e)})
        raise

#function to send messages to the frontend after a player made an appropriate move
async def broadcast_game_state(game: Red7GameState, cur_player_id: int, is_winning: bool, my_palette_ch: str, new_rule: str, next_lose: bool, player_id: int):
    """Send updated game state to all players in room"""
    if not game:
        return

    print(f"is_win {is_winning}, cur_player {cur_player_id}, pal_ch {my_palette_ch}, rule {new_rule}, next_lose {next_lose}", flush=True)
    if not is_winning:
        game.players[cur_player_id]["active"] = False

    await active_connections[player_id].send_json({
        "type": "change_turn",
        "lose": 0 if is_winning else 1,
        "id_did": cur_player_id,
        "his_pallete_ch": my_palette_ch,
        "rule_ch": new_rule,
        "next_lose": 1 if next_lose else 0
    })

#importing necessary libraries/functions 
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict
from app.database import get_profile_name_by_user_id, increment_bot_wins, check_and_award_bot_wins
from app.routers.bot import start_bot_game, bot_move, encode_card, decode_card
from app.red7state import Red7GameState
import logging

#creating FastAPI router for endpoints for game with bot
router = APIRouter(prefix="/api/ai_game", tags=["AI Game"])

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

            logging.info(f"Got from frontend turn_type-{type_cur}, player_id-{player_id}, palette_change-{my_palette_ch}, rule_change-{new_rule}, new_hand-{new_hand}, new_palette-{new_palette}")

            #according to the move type, checking the correctness of player's move (whether or not a player makes a winning move in their turn)
            if type_cur == "my_turn":
                #doing a particular move check if player's dictionary of possible moves is empty (happens on the very first move of a player)
                if not game.players[player_id]["possible_moves"]:
                    logging.info("Checking the move on its own (using check_move)")
                    is_winning = game.check_move(
                        player_id=player_id,
                        new_rule=new_rule,
                        new_hand=new_hand,
                        new_palette=new_palette
                    )

                #doing a move check in dictionary of possible moves
                else:
                    logging.info("Checking in dictionary of possible moves")
                    is_winning = game.check_in_possible_moves(
                        player_id=player_id,
                        new_rule=new_rule,
                        new_hand=new_hand,
                        new_palette=new_palette
                    )
                logging.info(f"Check happened, output of is_winning condition: {is_winning}")
                
                #if the move is correct, sending message to frontend
                if is_winning:
                    logging.info(f"Player made a correct turn, sending 'right_turn' to frontend!")
                    await websocket.send_json({"type": "right_turn"})
                #if the move is incorrect, sending message to the frontend and going to the beginning of the while loop (recieving another move attempt from frontend from the same player)
                else:
                    logging.info(f"Player tried to make an incorrect move!")
                    logging.info("Sending 'wrong_turn' response with data:")
                    logging.info(f"old_rule: {game.cur_rule_card}, new_rule: {new_rule}, palette_change: {my_palette_ch}")
                    await websocket.send_json({"type": "wrong_turn", 
                                               "my_pallete_ch": my_palette_ch,
                                               "rule_ch": new_rule,
                                               "old_rule": game.cur_rule_card})
                    continue
            
            #if move type is time_out, player loses automatically
            elif type_cur == "time_out":
                is_winning = False
                final_winner = 1
                logging.info(f"Player {player_id} timed out")
            else:
                logging.info("something else happened...")
                continue 

            bot_response = None
            #if player makes correct move, response from bot is recieved
            if type_cur == "my_turn" and is_winning:
                logging.info(f"Player's {player_id} turn")
                logging.info(f"Player {player_id} is winning")
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
            logging.info(f"Bot's response to player's move: {bot_response}")

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
                    #if player has no possible moves at the beginning
                    if next_lose:
                        await broadcast_game_state(game, player_id, False, None, None, False, player_id)
                #if bot made a move that ends the game, sending a message about it to the frontend
                else:
                    logging.info(f'Game is over (game with player {player_id})!')
                    logging.info(f"Winner is {'player' if bot_response['winner'] == 0 else 'bot'}")
                    is_winning = True if bot_response["winner"] == 1 else False
                    #if bot wins
                    if is_winning:
                        if bot_response.get("bot_action"):
                            pal_ch = decode_card(bot_response["bot_action"][0]) if bot_response["bot_action"][0] != 0 else None
                            rule_ch = decode_card(bot_response["bot_action"][1]) if bot_response["bot_action"][1] != 0 else None
                            await broadcast_game_state(game, -1, is_winning, pal_ch, rule_ch, is_winning, player_id)
                        else:
                            await broadcast_game_state(game, -1, is_winning, None, None, is_winning, player_id)
                        await broadcast_game_state(game, player_id, False, None, None, False, player_id)
                    #if player wins
                    else:
                        await broadcast_game_state(game, -1, is_winning, None, None, is_winning, player_id)

            #handling of the case when players continuously lose at the beginning of their turns (without an opportynity to make a move)
            max_checks = len(game.players_id_list)
            while next_lose and max_checks > 0:
                max_checks -= 1
                cur_player = game.current_player
                game.next_player()
                next_player = game.current_player
                if game.players[next_player]["active"]:
                    next_lose = not game.check_winning_at_beginning(next_player)
                    
                    logging.info(f"Will the next player lose at the beginning: {next_lose}")
                    await broadcast_game_state(game, cur_player, False, None, None, next_lose)
                else:
                    logging.info("The player has inactive state (game.players[next_player]['active'] != True)!")

    #websocket disconnet handling
    except WebSocketDisconnect:
        logging.info(f"Player {player_id} entered WebSocketDisconnect")
        logging.info(f"Open bot connections before: {active_connections}")
        active_connections.pop(player_id, None)  #cleaning up inactive connections
        logging.info(f"Open bot connections after: {active_connections}")
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

    logging.info("Sending a message via broadcast_game_state")
    logging.info(f"Data: is_winning-{is_winning}, current_player-{cur_player_id}, palette_change-{my_palette_ch}, rule_change-{new_rule}, next_lose-{next_lose}")

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
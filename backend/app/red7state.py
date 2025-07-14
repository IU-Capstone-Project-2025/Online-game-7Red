#importing necessary libraries/functions
from enum import Enum
from typing import List, Dict
from app.database import get_room_players_ids_and_names
import random
from collections import defaultdict
import random
import logging


#card colors and values
class CardColor(Enum):
    RED = "R"
    ORANGE = "O"
    YELLOW = "Y"
    GREEN = "G"
    BLUE = "B"
    INDIGO = "I"
    VIOLET = "V"

CARD_VALUES = list(range(1, 8))  #values are 1 through 7

#game rules (to define what rule is currently active)
PALETTE_RULES = [
    "Highest Card", #red
    "Most of One Number", #orange
    "Most of One Color", #yellow
    "Most Even Cards", #green
    "Most Different Colors", #blue
    "Most Cards in a Row", #indigo
    "Most Cards Below 4" #violet
]

#class that represents a game state
class Red7GameState:
    def __init__(self, assigned_id: str):
        self.assigned_id = assigned_id #id of the room where the game happens
        self.players = {}  #game players (player_id: {hand: [], palette: [], name: str, active: bool, possible_moves: {}})
        self.players_name_list = [] #list of players' names
        self.players_id_list = [] #list of players' ids
        self.started = False #game started state
        self.max_players = 4 #max players in a room
        self.min_players = 2 #min players in a room
        self.current_player = None #current player's id
        self.current_rule = 0  #current rule (game starts with Red rule (Highest Card))
        self.cur_rule_card = "R0"
        self.deck = [] #deck of cards
        self.game_over = False #game over state

    #function to get players' information from database
    async def get_room_players_info_from_db(self):
        """Load players from database with proper error handling"""
        logging.info(f"[In funcion get_room_players_info_from_db] Starting to fetch players for room {self.assigned_id}")
        
        names, ids = await get_room_players_ids_and_names(str(self.assigned_id))
        logging.info(f"[In funcion get_room_players_info_from_db] Received from DB - names: {names}, ids: {ids}")
        
        if not names or not ids:
            raise ValueError("Empty data returned from database")
            
        #players order shuffling
        combined = list(zip(names, ids))
        random.shuffle(combined)
        self.players_name_list, self.players_id_list = zip(*combined)
        self.players_name_list = list(self.players_name_list)
        self.players_id_list = list(self.players_id_list)
        
        logging.info(f"[In funcion get_room_players_info_from_db] Final player list - names: {self.players_name_list}, ids: {self.players_id_list}")
            
    #function to convert string representation of a card to tuple
    def card_to_tuple(self, card: str) -> tuple[int, int]:
        """Convert card string to (color_index, value) tuple (e.g., 'R7' to (0, 7))"""

        if not card or len(card) < 2:
            raise ValueError(f"Invalid card format: {card}")
        
        color_char = card[0].upper()
        value_str = card[1:]
        
        #converting color to index
        try:
            color = CardColor(color_char)
            color_index = list(CardColor).index(color)
        except ValueError:
            raise ValueError(f"Invalid color in card: {card}")
        
        #converting value to int
        try:
            value = int(value_str)
            if value not in CARD_VALUES:
                raise ValueError
        except ValueError:
            raise ValueError(f"Invalid value in card: {card}")
        
        return (color_index, value)
    
    #converting string rule card representation to integer
    def rule_to_int(self, rule: str) -> int:
            color_enum = CardColor(rule)
            color_index = list(CardColor).index(color_enum) 
            return color_index
    
    #converting integer rule card representation to string
    def int_to_rule(self, ind_rule: int) -> str:
        return list(CardColor)[ind_rule].value

    #initializing a deck of cards
    def initialize_deck(self):
        """Create and shuffle the deck of cards"""
        self.deck = []
        for color in CardColor:
            for value in CARD_VALUES:
                self.deck.append(f"{color.value}{value}")
        random.shuffle(self.deck)

    #dealing cards to players
    def deal_cards(self):
        """Deal initial cards to players"""
        for i in range(len(self.players_id_list)):
            self.players[self.players_id_list[i]] = {}

            #each player gets 7 cards in hand
            self.players[self.players_id_list[i]]["hand"] = [self.deck.pop() for _ in range(7)]
            #initial card palette is empty
            self.players[self.players_id_list[i]]["palette"] = []
            #player's name
            self.players[self.players_id_list[i]]["name"] = self.players_name_list[i]
            #player is active
            self.players[self.players_id_list[i]]["active"] = True
            #player doesn't have checked possible moves yet
            self.players[self.players_id_list[i]]["possible_moves"] = {}

    #dealing cards a player when the game is against bot
    def deal_cards_bot_game(self, player_id: int, hand_human: List[str], name: str):
        """Deal initial cards to a human and to the bot"""
        #human's data
        self.players[player_id] = {}
        self.players[player_id]["hand"] = hand_human
        self.players[player_id]["palette"] = []
        self.players[player_id]["name"] = name
        self.players[player_id]["active"] = True
        self.players[player_id]["possible_moves"] = {}

        #bot's data
        self.players[-1] = {}      
        self.players[-1]["hand"] = []
        self.players[-1]["palette"] = []
        self.players[-1]["name"] = "bot"
        self.players[-1]["active"] = True
        self.players[-1]["possible_moves"] = {}

    #starting a game
    async def start_game(self):
        """Start a game"""
        if self.started:
            return
        
        self.initialize_deck()
        self.deal_cards()
        self.current_player = self.players_id_list[0]
        self.started = True
        self.game_over = False

    #changing current player
    def next_player(self):
        """Move to the next active player"""
        players = [pid for pid, p in self.players.items() if p["active"]]
        logging.info(f"[In funcion next_player] Current active players: {players}")
        if not players:
            return False
            
        current_index = players.index(self.current_player)
        next_index = (current_index + 1) % len(players)
        prev_player = self.current_player
        self.current_player = players[next_index]
        prev_player_name, cur_player_name = self.players[prev_player]["name"], self.players[self.current_player]["name"]
        logging.info(f"[In funcion next_player] Player was changed successfully!")
        logging.info(f"[In funcion next_player] Player before: ({prev_player_name}, {prev_player})")
        logging.info(f"[In funcion next_player] Player now: ({cur_player_name}, {self.current_player})")
        return True

    #checking if a player can make a move after previous player's turn
    def check_winning_at_beginning(self, player_id: int) -> List[Dict]:
        if player_id not in self.players:
            return []
        
        #saving the original game state
        original_state = {
            'hand': self.players[player_id]["hand"].copy(),
            'palette': self.players[player_id]["palette"].copy(),
            'rule': self.current_rule,
            'rule_card': self.cur_rule_card
        }
        winning_moves = []

        #extract colors present in hand
        colors_in_hand = [card[0] for card in original_state['hand']]

        #including None (no rule change) + rules matching hand colors
        possible_rules = [(None, None)]
        #generating possible rules to change
        for i in range(len(colors_in_hand)):
            possible_rules.append((colors_in_hand[i], int(original_state['hand'][i][1])))

        #generating possible cards to play
        possible_cards = [None] + original_state['hand']

        #generating possible combinations of moves
        for i in range(len(possible_rules)):
            for j in range(len(possible_cards)):
                if i == j: #if cards are the same, skip
                    continue
                new_rule = possible_rules[i]
                card_played = possible_cards[j]

                #if a move is pass on both rule change and card paly, skip
                if new_rule[0] is None and card_played is None:
                    continue

                new_hand = original_state['hand'].copy()
                new_palette = original_state['palette'].copy()

                #handling card play
                if card_played is not None:
                    if card_played not in new_hand:
                        continue  #invalid card
                    new_hand.remove(card_played)
                    new_palette.append(card_played)

                #handling rule change
                orig_rule_str = self.cur_rule_card
                
                new_rule_full = str(new_rule[0]) + str(new_rule[1])
                actual_rule = new_rule_full if new_rule[0] is not None else orig_rule_str

                if new_rule[0] is not None:  #removing a card for rule change
                    card = str(new_rule[0]) + str(new_rule[1])
                    new_hand.remove(card)


                #checking if this move wins
                if self.check_move(player_id, actual_rule, new_hand, new_palette):
                    
                    winning_moves.append({
                        "card_played": card_played,
                        "new_rule": actual_rule,
                        "new_hand": new_hand,
                        "new_palette": new_palette
                    })

        #restore original state
        self.players[player_id]["hand"] = original_state['hand']
        self.players[player_id]["palette"] = original_state['palette']
        self.current_rule = original_state['rule']
        self.cur_rule_card = original_state['rule_card']

        #saving player's possible moves
        self.players[player_id]["possible_moves"] = winning_moves
        logging.info(f"[In funcion check_winning_at_beginning] Possible moves at the beginning were checked for player {player_id}")
        logging.info(f"[In funcion check_winning_at_beginning] Number of possible moves: {len(winning_moves)}")
        return len(winning_moves) > 0
    
    #function that checks a move in possible_moves dictionary
    def check_in_possible_moves(self, player_id: int, new_rule: str, new_hand: List[str], new_palette: List[str]) -> bool:
        try:
            #print(f"Rule at the beginning of check_in_possible_moves: {self.cur_rule_card}", flush=True)
            #retrieving possible moves from dictionary
            moves = self.players[player_id]["possible_moves"]
            if not moves:
                return False
        
            #pre-sorting the target hand and palette once
            sorted_new_hand = sorted(new_hand)
            sorted_new_palette = sorted(new_palette)
            target_rule = self.cur_rule_card if new_rule is None else new_rule

            #checking the move
            for move in moves:
                if move["new_rule"] != target_rule:
                    continue
                if sorted(move["new_hand"]) != sorted_new_hand:
                    continue
                if sorted(move["new_palette"]) != sorted_new_palette:
                    continue
                    
                #if exact match was found, changing player's hand an palette to new ones from the move
                self.players[player_id]["hand"] = new_hand
                self.players[player_id]["palette"] = new_palette
                #changing current rule a new one (if a move included rule change)
                if new_rule is not None:
                    self.cur_rule_card = new_rule
                    self.current_rule = self.rule_to_int(self.cur_rule_card[0])
                #print(f"Rule at the end of check_in_possible_moves: {self.cur_rule_card}", flush=True)
                logging.info("In check_possible_moves found exact match")
                #return True
                return True
            
        #exception handling
        except Exception as e:
            logging.info(f"Move validation crashed: {e}")
            return False 
    
        #return False if no matches were found
        logging.info("In check_possible_moves didn't find exact match")
        return False

    #function to check a move's correctness according to the game's rules
    def check_move(self, player_id: int, new_rule: str, new_hand: List[str], new_palette: List[str]) -> bool:
        """Validates if a move is legal and checks if it leads to a winning state"""
            
        #keeping original game state

        original_state = {
            'hand': self.players[player_id]["hand"].copy(),
            'palette': self.players[player_id]["palette"].copy(),
            'rule': self.current_rule,
            'rule_card': self.cur_rule_card
        }
        
        #applying proposed changes temporarily
        self.players[player_id]["hand"] = new_hand
        self.players[player_id]["palette"] = new_palette
        if new_rule != None:
            self.current_rule = self.rule_to_int(new_rule[0])
            self.cur_rule_card = new_rule

        #retrieving ids of active opponents
        opponent_ids = [pid for pid in self.players.keys() if pid != player_id and self.players[pid]["active"]]
        
        #checking winning conditions (all rules must be considered for a winning move)
        is_winning = all(self.evaluate_winning_condition(player_id, opponent_ids))

        #if the move is not a winning one, going back to the original state
        if not is_winning:
            self.players[player_id]["hand"] = original_state['hand']
            self.players[player_id]["palette"] = original_state['palette']
            self.current_rule = original_state['rule']
            self.cur_rule_card = original_state['rule_card']
        
        return is_winning

    #function that evaluates if a currnt state is winning for a player
    def evaluate_winning_condition(self, player_id: int, opponent_ids: List[int]) -> List[bool]:
        """Evaluates if current state is winning for player"""
        
        rule_name = PALETTE_RULES[self.current_rule]
        result_arr = []
        
        #checking all the rules on the move's correctness
        if rule_name == "Highest Card":
            result_arr = self._highest_card_rule(player_id, opponent_ids)
        elif rule_name == "Most of One Number":
            result_arr = self._most_of_one_number_rule(player_id, opponent_ids)
        elif rule_name == "Most of One Color":
            result_arr = self._most_of_one_color_rule(player_id, opponent_ids)
        elif rule_name == "Most Even Cards":
            result_arr = self._most_even_cards_rule(player_id, opponent_ids)
        elif rule_name == "Most Different Colors":
            result_arr = self._most_different_colors_rule(player_id, opponent_ids)
        elif rule_name == "Most Cards in a Row":
            result_arr = self._most_cards_in_row_rule(player_id, opponent_ids)
        elif rule_name == "Most Cards Below 4":
            result_arr = self._most_cards_below_4_rule(player_id, opponent_ids)

        return result_arr
    
    #function that checks red rule correctness
    def _highest_card_rule(self, my_id, opp_ids) -> List[bool]:
        """Red rule: Player with the highest card in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                res.append(True)
                continue
            
            my_max_val = max([num for (_, num) in palette])
            opp_max_val = max([num for (_, num) in opp_palette])
            
            if my_max_val != opp_max_val:
                res.append(my_max_val > opp_max_val)
                continue
                
            #highest priority color
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_val]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_val]
            
            my_best_color = min([color for (color, _) in my_max_cards])
            opp_best_color = min([color for (color, _) in opp_max_cards])
            res.append(my_best_color < opp_best_color)
        return res
    

    #function that checks orange rule correctness
    def _most_of_one_number_rule(self, my_id, opp_ids) -> List[bool]:
        """Orange rule: Player with the most cards of one number in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                res.append(True)
                continue
        
            my_counts = defaultdict(int)
            for (_, num) in palette:
                my_counts[num] += 1
            my_best = max(my_counts.values())
            
            opp_counts = defaultdict(int)
            for (_, num) in opp_palette:
                opp_counts[num] += 1
            opp_best = max(opp_counts.values())
            
            if my_best != opp_best:
                res.append(my_best > opp_best)
                continue
            
            #higher number wins
            my_top_num = max([num for num, cnt in my_counts.items() if cnt == my_best])
            opp_top_num = max([num for num, cnt in opp_counts.items() if cnt == opp_best])

            if my_top_num != opp_top_num:
                res.append(my_top_num > opp_top_num)
                continue
            
            #highest priority color (0=red is best)
            my_max_cards = [(color, num) for (color, num) in palette if num == my_top_num]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_top_num]
            
            my_best_color = min([color for (color, _) in my_max_cards])
            opp_best_color = min([color for (color, _) in opp_max_cards])

            res.append(my_best_color < opp_best_color)
        return res
    
    #function that checks yellow rule correctness
    def _most_of_one_color_rule(self, my_id, opp_ids) -> List[bool]:
        """Yellow rule: Player with the most cards of the same color in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                res.append(True)
                continue

            my_counts = defaultdict(int)
            for (color, num) in palette:
                my_counts[color] += 1
            my_best = max(my_counts.values())
            
            opp_counts = defaultdict(int)
            for (color, num) in opp_palette:
                opp_counts[color] += 1
            opp_best = max(opp_counts.values())
            
            if my_best != opp_best:
                res.append(my_best > opp_best)
                continue
            
            #the most frequent color(s)
            my_top_colors = [color for color, cnt in my_counts.items() if cnt == my_best]
            opp_top_colors = [color for color, cnt in opp_counts.items() if cnt == opp_best]
            
            #getting all cards in the most frequent color(s)
            my_cards_in_top_colors = [(color, num) for (color, num) in palette if color in my_top_colors]
            opp_cards_in_top_colors = [(color, num) for (color, num) in opp_palette if color in opp_top_colors]
            
            #highest number in those colors
            my_max_num = max([num for (color, num) in my_cards_in_top_colors])
            opp_max_num = max([num for (color, num) in opp_cards_in_top_colors])
            
            if my_max_num != opp_max_num:
                res.append(my_max_num > opp_max_num)
                continue
            
            #highest priority color among those cards
            my_best_color = min([color for (color, num) in my_cards_in_top_colors if num == my_max_num])
            opp_best_color = min([color for (color, num) in opp_cards_in_top_colors if num == opp_max_num])

            res.append(my_best_color < opp_best_color)
        return res

    #function that checks green rule correctness
    def _most_even_cards_rule(self, my_id, opp_ids) -> List[bool]:
        """Green rule: Player with the most number of even cards in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                my_evens = sum(1 for (_, num) in palette if num % 2 == 0)
                if my_evens == 0:
                    res.append(False)
                else:
                    res.append(True)
                continue

            my_evens = sum(1 for (_, num) in palette if num % 2 == 0)
            opp_evens = sum(1 for (_, num) in opp_palette if num % 2 == 0)
            
            if my_evens != opp_evens:
                res.append(my_evens > opp_evens)
                continue
            
            #highest even card
            my_max_even = max([num for (_, num) in palette if num % 2 == 0], default=0)
            opp_max_even = max([num for (_, num) in opp_palette if num % 2 == 0], default=0)
            
            if my_max_even != opp_max_even:
                res.append(my_max_even > opp_max_even)
                continue
            
            #color priority among highest even cards
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_even]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_even]

            if len(my_max_cards) == 0:
                res.append(False)
                continue
            
            my_best_color = min([color for (color, _) in my_max_cards], default=7)
            opp_best_color = min([color for (color, _) in opp_max_cards], default=7)
            
            res.append(my_best_color < opp_best_color)
        return res

    #function that checks blue rule correctness
    def _most_different_colors_rule(self, my_id, opp_ids) -> List[bool]:
        """Blue rule: Player with the most cards of different colors in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                res.append(True)
                continue

            my_colors = len({color for (color, _) in palette})
            opp_colors = len({color for (color, _) in opp_palette})
            
            if my_colors != opp_colors:
                res.append(my_colors > opp_colors)
                continue
            
            #highest priority number
            my_max_val = max([num for (_, num) in palette])
            opp_max_val = max([num for (_, num) in opp_palette])
            
            if my_max_val != opp_max_val:
                res.append(my_max_val > opp_max_val)
                continue
                
            #highest priority color
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_val]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_val]
            
            my_best_color = min([color for (color, _) in my_max_cards])
            opp_best_color = min([color for (color, _) in opp_max_cards])
            res.append(my_best_color < opp_best_color)
        return res

    #function that checks indigo rule correctness
    def _most_cards_in_row_rule(self, my_id, opp_ids) -> List[bool]:
        """Indigo rule: Player with cards that make the longest sequence in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                res.append(True)
                continue

            def longest_sequence_info(cards):
                numbers = sorted({num for (_, num) in cards})  # unique numbers
                if not numbers:
                    return (0, 0, 0)  # (length, max_num, best_color)
                
                max_len = 1
                current_len = 1
                best_max_num = numbers[0]
                
                for i in range(1, len(numbers)):
                    if numbers[i] == numbers[i-1] + 1:
                        current_len += 1
                        if current_len > max_len or (current_len == max_len and numbers[i] > best_max_num):
                            max_len = current_len
                            best_max_num = numbers[i]  # tracking the highest num in the longest seq
                    else:
                        current_len = 1
                
                # Find all cards that are part of the longest sequence
                seq_cards = [(color, num) for (color, num) in cards 
                            if num >= best_max_num - max_len + 1 and num <= best_max_num]
                
                # Find the color of the maximum card in the sequence
                max_card_in_seq = best_max_num
                # Get all cards with the maximum number in the sequence
                max_cards = [(color, num) for (color, num) in seq_cards if num == max_card_in_seq]
                
                # Among these, return the color of the first one (or use min() if you want highest priority)
                best_color = max_cards[0][0] if max_cards else 0
                
                return (max_len, best_max_num, best_color)
            
            my_len, my_max_num, my_color = longest_sequence_info(palette)
            opp_len, opp_max_num, opp_color = longest_sequence_info(opp_palette)
            
            #comparing sequence lengths
            if my_len != opp_len:
                res.append(my_len > opp_len)
                continue
            
            #comparing highest numbers in the sequence if len == 1
            if my_len == opp_len == 1:
                #highest priority number
                my_max_val = max([num for (_, num) in palette])
                opp_max_val = max([num for (_, num) in opp_palette])
            
                if my_max_val != opp_max_val:
                    res.append(my_max_val > opp_max_val)
                    continue
                #highest priority color
                my_max_cards = [(color, num) for (color, num) in palette if num == my_max_val]
                opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_val]
                
                my_best_color = min([color for (color, _) in my_max_cards])
                opp_best_color = min([color for (color, _) in opp_max_cards])
                res.append(my_best_color < opp_best_color)
                continue
            
            #comparing highest numbers in the sequence
            if my_max_num != opp_max_num:
                res.append(my_max_num > opp_max_num)
                continue
            
            #comparing color priority of the highest sequence number
            res.append(my_color < opp_color)
        return res
        
    #function that checks violet rule correctness
    def _most_cards_below_4_rule(self, my_id, opp_ids) -> List[bool]:
        """Violet rule: Player with the most cards less than 4 in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            if not palette:
                res.append(False)
                continue
            elif not opp_palette:
                my_lt4 = sum(1 for (_, num) in palette if num < 4)
                if my_lt4 == 0:
                    res.append(False)
                else:
                    res.append(True)
                continue

            my_lt4 = sum(1 for (_, num) in palette if num < 4)
            opp_lt4 = sum(1 for (_, num) in opp_palette if num < 4)
            
            if my_lt4 != opp_lt4:
                res.append(my_lt4 > opp_lt4)
                continue
            
            #highest card under 4
            my_max_lt4 = max([num for (_, num) in palette if num < 4], default=0)
            opp_max_lt4 = max([num for (_, num) in opp_palette if num < 4], default=0)
            
            if my_max_lt4 != opp_max_lt4:
                res.append(my_max_lt4 > opp_max_lt4)
                continue
            
            #color priority among highest cards < 4
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_lt4]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_lt4]

            if len(my_max_cards) == 0:
                res.append(False)
                continue
            
            my_best_color = min([color for (color, _) in my_max_cards], default=7)
            opp_best_color = min([color for (color, _) in opp_max_cards], default=7)
            
            res.append(my_best_color < opp_best_color)
        return res
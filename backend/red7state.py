from enum import Enum
from typing import List, Dict
from backend.database import get_room_players_ids_and_names
import random
from collections import defaultdict
import random


# Card colors and values
class CardColor(Enum):
    RED = "R"
    ORANGE = "O"
    YELLOW = "Y"
    GREEN = "G"
    BLUE = "B"
    INDIGO = "I"
    VIOLET = "V"

CARD_VALUES = list(range(1, 8))  # 1 through 7

# Game rules - each palette defines what rule is currently active
PALETTE_RULES = [
    "Highest Card",        # Red
    "Most of One Number",  # Orange
    "Most of One Color",   # Yellow
    "Most Even Cards",     # Green
    "Most Different Colors",  # Blue
    "Most Cards in a Row",    # Indigo
    "Most Cards Below 4"      # Violet
]

class Red7GameState:
    def __init__(self, assigned_id: str):
        self.assigned_id = assigned_id
        self.players = {}  # player_id: {hand: [], palette: [], name: str}
        self.players_name_list = []
        self.players_id_list = []
        self.started = False
        self.max_players = 4
        self.min_players = 2
        self.current_player = None
        self.current_rule = 0  # Starts with Red rule (Highest Card)
        self.cur_rule_card = "R0"
        self.deck = []
        self.discard_pile = []
        self.game_over = False
        self.winner = None
        self.round = 1

    async def get_room_players_info_from_db(self):
        """Load players from database with proper error handling"""
        print(f"[DEBUG] Starting to fetch players for room {self.assigned_id}", flush=True)
        
        names, ids = await get_room_players_ids_and_names(str(self.assigned_id))
        print(f"[DEBUG] Received from DB - names: {names}, ids: {ids}", flush=True)
        
        if not names or not ids:
            raise ValueError("Empty data returned from database")
            
        # Shuffle player
        combined = list(zip(names, ids))
        random.shuffle(combined)
        self.players_name_list, self.players_id_list = zip(*combined)
        self.players_name_list = list(self.players_name_list)
        self.players_id_list = list(self.players_id_list)
        
        print(f"[DEBUG] Final player list - names: {self.players_name_list}, ids: {self.players_id_list}", flush=True)
            
    
    def card_to_tuple(self, card: str) -> tuple[int, int]:
        """Convert card string (e.g., 'R7') to (color_index, value) tuple.
        
        Args:
            card: Card string in format "{ColorLetter}{Value}" (e.g., "R7")
        
        Returns:
            Tuple of (color_index, value) where:
            - color_index: 0 (Red) to 6 (Violet)
            - value: 1-7
        
        Raises:
            ValueError: If card format is invalid
        """
        if not card or len(card) < 2:
            raise ValueError(f"Invalid card format: {card}")
        
        color_char = card[0].upper()
        value_str = card[1:]
        
        # Convert color to index
        try:
            color = CardColor(color_char)  # Raises ValueError if invalid
            color_index = list(CardColor).index(color)
        except ValueError:
            raise ValueError(f"Invalid color in card: {card}")
        
        # Convert value to int
        try:
            value = int(value_str)
            if value not in CARD_VALUES:
                raise ValueError
        except ValueError:
            raise ValueError(f"Invalid value in card: {card}")
        
        return (color_index, value)
    
    def rule_to_int(self, rule: str) -> int:
            color_enum = CardColor(rule)
            color_index = list(CardColor).index(color_enum) 
            return color_index
    
    def int_to_rule(self, ind_rule: int) -> str:
        return list(CardColor)[ind_rule].value

    def initialize_deck(self):
        """Create and shuffle the deck of cards"""
        self.deck = []
        for color in CardColor:
            for value in CARD_VALUES:
                self.deck.append(f"{color.value}{value}")
        random.shuffle(self.deck)

    def deal_cards(self):
        """Deal initial cards to players"""
        for i in range(len(self.players_id_list)):
            self.players[self.players_id_list[i]] = {}
            # Each player gets 7 cards in hand and 1 in palette
            self.players[self.players_id_list[i]]["hand"] = [self.deck.pop() for _ in range(7)]
            # if i == 0:
            #     self.players[self.players_id_list[i]]["hand"] = ['B4', 'V5', 'G3', 'V2', 'R1', 'I4', 'G1']
            # else: 
            #     self.players[self.players_id_list[i]]["hand"] = ['R4', 'B5', 'B3', 'R2', 'O1', 'I1', 'B7']
            self.players[self.players_id_list[i]]["palette"] = []
            self.players[self.players_id_list[i]]["name"] = self.players_name_list[i]
            self.players[self.players_id_list[i]]["active"] = True
            self.players[self.players_id_list[i]]["possible_moves"] = {}
    
    def deal_cards_bot_game(self, player_id: int, hand_human: List[str], name: str):
        self.players[player_id] = {}
        self.players[player_id]["hand"] = hand_human
        self.players[player_id]["palette"] = []
        self.players[player_id]["name"] = name
        self.players[player_id]["active"] = True
        self.players[player_id]["possible_moves"] = {}

        self.players[-1] = {}      
        self.players[-1]["hand"] = []
        self.players[-1]["palette"] = []
        self.players[-1]["name"] = "bot"
        self.players[-1]["active"] = True
        self.players[-1]["possible_moves"] = {}

    async def start_game(self):
        """Async version that should be called within a locked context"""
        if self.started:
            return
        
        self.initialize_deck()
        self.deal_cards()
        self.current_player = self.players_id_list[0]  # First player from shuffled list
        self.current_rule = 0  # Red rule
        self.cur_rule_card = None
        self.started = True
        self.game_over = False

    def next_player(self):
        """Move to the next active player"""
        players = [pid for pid, p in self.players.items() if p["active"]]
        print(f"Active players {players}", flush=True)
        if not players:
            return False
            
        current_index = players.index(self.current_player)
        next_index = (current_index + 1) % len(players)
        self.current_player = players[next_index]
        print("All is well isnside next_player()", flush=True)
        return True

    def check_winning_at_beginning(self, player_id: int) -> List[Dict]:
        if player_id not in self.players:
            return []
        
        original_state = {
            'hand': self.players[player_id]["hand"].copy(),
            'palette': self.players[player_id]["palette"].copy(),
            'rule': self.current_rule,
            'rule_card': self.cur_rule_card
        }
        winning_moves = []

        # Extract colors present in hand (e.g., {'R', 'G'} from ['R7', 'G3'])
        colors_in_hand = [card[0] for card in original_state['hand']]

        # Include None (no rule change) + rules matching hand colors
        possible_rules = [(None, None)]
        for i in range(len(colors_in_hand)):
            possible_rules.append((colors_in_hand[i], int(original_state['hand'][i][1])))

        possible_cards = [None] + original_state['hand']

        for i in range(len(possible_rules)):
            for j in range(len(possible_cards)):
                if i == j:
                    continue
                new_rule = possible_rules[i]
                #print(f"new rule {new_rule}")
                card_played = possible_cards[j]

                if new_rule[0] is None and card_played is None:
                    continue

                new_hand = original_state['hand'].copy()
                new_palette = original_state['palette'].copy()

                # --- Handle Card Play (if any) ---
                if card_played is not None:
                    if card_played not in new_hand:
                        continue  # Invalid card
                    new_hand.remove(card_played)
                    new_palette.append(card_played)

                # --- Handle Rule Change (if any) ---
                orig_rule_str = self.cur_rule_card
                # if orig_rule_str == new_rule:
                #     continue
                
                new_rule_full = str(new_rule[0]) + str(new_rule[1])
                actual_rule = new_rule_full if new_rule[0] is not None else orig_rule_str

                if new_rule[0] is not None:  # Only remove a card for rule changes (not for None)
                    # Find the first card in hand matching the new rule's color
                    card = str(new_rule[0]) + str(new_rule[1])
                    new_hand.remove(card)


                # Check if this move wins
                if self.check_move(player_id, actual_rule, new_hand, new_palette):
                    
                    winning_moves.append({
                        "card_played": card_played,
                        "new_rule": actual_rule,
                        "new_hand": new_hand,
                        "new_palette": new_palette
                    })

        # Restore original state
        self.players[player_id]["hand"] = original_state['hand']
        self.players[player_id]["palette"] = original_state['palette']
        self.current_rule = original_state['rule']
        #print(f"before {self.cur_rule_card} after {original_state['rule_card']}")
        self.cur_rule_card = original_state['rule_card']

        self.players[player_id]["possible_moves"] = winning_moves
        #print(self.players[player_id]["possible_moves"], flush=True)
        print("Win at beg!!!", flush=True)
        print(len(winning_moves), flush=True)
        return len(winning_moves) > 0
    
    def check_in_possible_moves(self, player_id: int, new_rule: str, new_hand: List[str], new_palette: List[str]) -> bool:
        try:
            moves = self.players[player_id]["possible_moves"]
            if not moves:
                return False
        
            # Pre-sort the target hand and palette once
            sorted_new_hand = sorted(new_hand)
            sorted_new_palette = sorted(new_palette)
            target_rule = self.cur_rule_card if new_rule is None else new_rule

            for move in moves:
                # Early exit conditions
                if move["new_rule"] != target_rule:
                    continue
                if sorted(move["new_hand"]) != sorted_new_hand:
                    continue
                if sorted(move["new_palette"]) != sorted_new_palette:
                    continue
                    
                # Found exact match
                self.players[player_id]["hand"] = new_hand
                self.players[player_id]["palette"] = new_palette
                if new_rule is not None:
                    self.cur_rule_card = new_rule
                    self.current_rule = self.rule_to_int(self.cur_rule_card[0])
                print("In check_possible_moves found exact match", flush=True)
                return True
            
        except Exception as e:
            print(f"Move validation crashed: {e}", flush=True)
            return False 
    
        print("In check_possible_moves didn't find exact match", flush=True)
        return False

    def check_move(self, player_id: int, new_rule: str, new_hand: List[str], new_palette: List[str]) -> bool:
        """
        Validates if a move is legal and checks if it leads to a winning state.
        
        Args:
            player_id: Player making the move
            card_played: The card being played (for validation)
            new_rule: Proposed new rule after move
            new_hand: Proposed new hand after move
            new_palette: Proposed new palette after move
            
        Returns:
            bool: True if move is valid and leads to winning state
        """
            
        # 2. Create temporary game state

        original_state = {
            'hand': self.players[player_id]["hand"].copy(),
            'palette': self.players[player_id]["palette"].copy(),
            'rule': self.current_rule,
            'rule_card': self.cur_rule_card
        }
        
        # 3. Apply proposed changes temporarily
        self.players[player_id]["hand"] = new_hand
        self.players[player_id]["palette"] = new_palette
        #print(f'rule: {new_rule} hand: {new_hand} pallete: {new_palette}', flush=True)
        if new_rule != None:
            self.current_rule = self.rule_to_int(new_rule[0])
            self.cur_rule_card = new_rule

        #print(self.current_rule, flush=True)

        opponent_ids = [pid for pid in self.players.keys() if pid != player_id and self.players[pid]["active"]]
        
        # 4. Check winning condition
        is_winning = all(self.evaluate_winning_condition(player_id, opponent_ids))

        if not is_winning:
            self.players[player_id]["hand"] = original_state['hand']
            self.players[player_id]["palette"] = original_state['palette']
            self.current_rule = original_state['rule']
            self.cur_rule_card = original_state['rule_card']
        
        return is_winning

    def evaluate_winning_condition(self, player_id: int, opponent_ids: List[int]) -> List[bool]:
        """Evaluates if current state is winning for player"""
        
        rule_name = PALETTE_RULES[self.current_rule]
        result_arr = []
        
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
        
    def _highest_card_rule(self, my_id, opp_ids) -> List[bool]:
        """Red rule: Player with the highest card in their palette wins"""
        res = []
        palette = [self.card_to_tuple(ent) for ent in self.players[my_id]["palette"]]
        for cur_opp_id in opp_ids:
            opp_palette = [self.card_to_tuple(ent) for ent in self.players[cur_opp_id]["palette"]]

            #checks in case of emty palletes
            # if not palette and not opp_palette:
            #     res.append(True)
            #     continue
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
    
    def _most_of_one_color_rule(self, my_id, opp_ids) -> List[bool]:
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

    def _most_even_cards_rule(self, my_id, opp_ids) -> List[bool]:
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

    def _most_different_colors_rule(self, my_id, opp_ids) -> List[bool]:
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

    def _most_cards_in_row_rule(self, my_id, opp_ids) -> List[bool]:
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
        

    def _most_cards_below_4_rule(self, my_id, opp_ids) -> List[bool]:
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
import numpy as np
import random
from typing import Tuple, List
import torch
# import colorama
# from colorama import Fore, Style
from collections import defaultdict

#colorama.init(autoreset=True)

class Red7Env:
    COLORS = ["R", "O", "Y", "G", "L", "B", "V"]
    COLOR_NAMES = ["Red", "Orange", "Yellow", "Green", "LightBlue", "Blue", "Violet"]
    # COLOR_CODES = [Fore.RED, Fore.LIGHTRED_EX, Fore.YELLOW, Fore.GREEN,
    #                Fore.CYAN, Fore.BLUE, Fore.MAGENTA]


    """
        Initialize a new game instance.
        
        Args:
            seed (int|None): Seed for RNG. None for random initialization  
            verbose (bool): Verbose console output mode
            
        Initializes:
            - Card deck (1-49)
            - Player hands and palettes
            - Current rule (default Red/0)
            - Game state (current player, done flag)
    """
    def __init__(self, seed: int = None, verbose: bool = True):
        self.hand_size = 7
        self.verbose = verbose
        if seed is not None:
            self.seed(1)
        self.reset()


    """
        Reset game to initial state.
        
        Returns:
            dict: Observation containing:
                - hand (Tensor[int]): Current player's hand (padded to 7)
                - my_palette (Tensor[int]): Current player's palette
                - opp_palette (Tensor[int]): Opponent's palette
                - rule (Tensor[int]): Current active rule
                - hand_len (Tensor[float]): Hand card count
                - my_palette_len (Tensor[float]): Palette size
                - opp_hand_len (Tensor[float]): Opponent hand count
                - opp_palette_len (Tensor[float]): Opponent palette size
                - known_deck (Tensor[float]): Deck mask (1-present, 0-absent)
        """
    def reset(self):
        self.deck = list(range(1, 50))
        random.shuffle(self.deck)
        self.player1_hand = self.deck[:self.hand_size]
        self.player2_hand = self.deck[self.hand_size:self.hand_size * 2]
        self.deck = self.deck[self.hand_size * 2:]
        self.player1_palette = []
        self.player2_palette = []
        self.rule = 0
        self._current_player = 0
        self.done = False
        self.winner = None
        return self._get_obs()
    
    """
        Get current player index.
        
        Returns:
            int: 0 (first player) or 1 (second player)
        """
    def current_player(self):
        return self._current_player


    """
        Pad card list with zeros to standard hand size.
        
        Args:
            cards (list[int]): List of card IDs (1-49)
            
        Returns:
            np.ndarray: Array of length 7 (cards + zeros)
        """
    def _pad(self, cards):
        return np.array(cards + [0] * (self.hand_size - len(cards)), dtype=np.int64)


    """
        Create bitmask of remaining deck cards.
        
        Returns:
            np.ndarray[float32]: Array of length 49 where:
                - 1.0 - card in deck
                - 0.0 - card not in deck
        """
    def _deck_mask(self):
        mask = np.zeros(49, dtype=np.float32)
        for card in self.deck:
            mask[card - 1] = 1.0
        return mask
    """
        Compute matrix of valid actions for current state.
        
        Returns:
            np.ndarray[float32]: 50x50 matrix where:
                - [i,j] = 1.0 if action valid
                - i: card for palette (0-skip)
                - j: card for rule change (0-skip)
                
        Logic:
            1. Checks which cards are in hand
            2. For each combination verifies if it maintains winning state
        """
    def legal_actions_mask(self, ) -> np.ndarray:
        """
        Возвращает маску легальных действий для текущего игрока.
        Маска — матрица 50x50, где mask[i][j] == 1.0 значит ход возможен.
        i — карта для правила или карта для палитки,
        j — карта для смены правила.
        """
        mask = np.zeros((50, 50), dtype=np.float32)
        if self._current_player == 0:
            hand = self.player1_hand
            pallete = self.player1_palette
            opp_pallete = self.player2_palette
        else:
            hand = self.player2_hand
            pallete = self.player2_palette
            opp_pallete = self.player1_palette
        hand_set = set(hand)
        mask[0][0] = 1

        for i in range(1, 50):
            if i in hand_set:
                mask[i][0] = 1.0
                if not check_win(pallete.copy() + [i], [opp_pallete], self.rule):
                    mask[i][0] = 0
                for j in range(1, 50):
                    if j in hand_set and i != j:
                        if not check_win(pallete.copy() + [i], [opp_pallete], (j - 1) // 7):
                            mask[i][j] = 0
                        else:
                            mask[i][j] = 1.0
        for j in range(1, 50):
            if j in hand_set:
                mask[0][j] = 1.0
                if not check_win(pallete, [opp_pallete], (j - 1) // 7):
                        mask[0][j] = 0
            

        return mask

    """Print current game state to console with color coding."""
    def render(self):
        cp = 1 - self._current_player
        print("\n" + "="*42)
        print(f"Current Turn: Player {cp}")
        print("-" * 42)
        print(f"Player 0 (You):")
        print(f"  Hand:    {self._cards_to_str(self.player1_hand)}")
        print(f"  Palette: {self._cards_to_str(self.player1_palette)}")
        print(f"Player 1 (Opponent):")
        print(f"  Hand:    {self._cards_to_str(self.player2_hand)}")
        print(f"  Palette: {self._cards_to_str(self.player2_palette)}")
        print(f"\nCurrent Rule: {self.COLOR_NAMES[self.rule]}")
        print(f"Deck: {len(self.deck)} cards remaining")
        print("="*42 + "\n")

    """
        Format card as colored string.
        
        Args:
            card (int): Card ID (1-49)
            
        Returns:
            str: String like "R3" (color + value) with ANSI color
            
        Example:
            1 → "R1" (red)
            8 → "O1" (orange)
        """
    def _color_str(self, card: int) -> str:
        if card < 1 or card > 49:
            return "Invalid"
        val = (card - 1) % 7 + 1
        col = (card - 1) // 7
        #return self.COLOR_CODES[col] + f"{self.COLORS[col]}{val}" + Style.RESET_ALL
        return f"{self.COLORS[col]}{val}"

    """
        Convert card list to formatted string.
        
        Args:
            cards (list[int]): List of card IDs
            
        Returns:
            str: Space-separated cards ("R1 O2 Y3")
    """
    def _cards_to_str(self, cards: List[int]) -> str:
        return " ".join([self._color_str(c) for c in sorted(cards)])

    """
        Get the current rule card color index.
        
        Returns:
            int: Current rule color index (0-6)
    """
    def get_rule_card(self) -> int:
        return self.rule

    """
        Get hand cards for specified player.
        
        Args:
            player_index (int): 0 for first player, 1 for second player
            
        Returns:
            List[int]: List of card IDs in player's hand
            
        Raises:
            ValueError: If player_index is not 0 or 1
    """
    def get_hand(self, player_index: int) -> List[int]:
        if player_index == 0:
            return self.player1_hand
        elif player_index == 1:
            return self.player2_hand
        else:
            raise ValueError("Invalid player index. Only 0 or 1 are allowed.")

    """
        Get palette cards for specified player.
        
        Args:
            player_index (int): 0 for first player, 1 for second player
            
        Returns:
            List[int]: List of card IDs in player's palette
            
        Raises:
            ValueError: If player_index is not 0 or 1
    """
    def get_palette(self, player_index: int) -> List[int]:
        if player_index == 0:
            return self.player1_palette
        elif player_index == 1:
            return self.player2_palette
        else:
            raise ValueError("Invalid player index. Only 0 or 1 are allowed.")

    """
        Get game winner.
        
        Returns:
            int: 
                - 0 - first player won
                - 1 - second player won
                - -1 - game not finished
        """
    def get_winner(self) -> int:
        return self.winner

    """
        Get current observation dictionary.
        
        Returns:
            dict: Observation containing:
                - hand: Padded hand tensor
                - my_palette: Padded palette tensor
                - opp_palette: Opponent's padded palette tensor  
                - rule: Current rule tensor
                - hand_len: Hand length tensor
                - my_palette_len: Palette length tensor
                - opp_hand_len: Opponent hand length tensor
                - opp_palette_len: Opponent palette length tensor
                - known_deck: Deck presence mask tensor
    """
    def _get_obs(self):
            if self._current_player == 0:
                return {
                    'hand': torch.tensor(self._pad(self.player1_hand)).unsqueeze(0),
                    'my_palette': torch.tensor(self._pad(self.player1_palette)).unsqueeze(0),
                    'opp_palette': torch.tensor(self._pad(self.player2_palette)).unsqueeze(0),
                    'rule': torch.tensor([[self.rule]], dtype=torch.long),
                    'hand_len': torch.tensor([[len(self.player1_hand)]], dtype=torch.float32),
                    'my_palette_len': torch.tensor([[len(self.player1_palette)]], dtype=torch.float32),
                    'opp_hand_len': torch.tensor([[len(self.player2_hand)]], dtype=torch.float32),
                    'opp_palette_len': torch.tensor([[len(self.player2_palette)]], dtype=torch.float32),
                    'known_deck': torch.tensor(self._deck_mask()).unsqueeze(0),
                }
            else:
                return {
                    'hand': torch.tensor(self._pad(self.player2_hand)).unsqueeze(0),
                    'my_palette': torch.tensor(self._pad(self.player2_palette)).unsqueeze(0),
                    'opp_palette': torch.tensor(self._pad(self.player1_palette)).unsqueeze(0),
                    'rule': torch.tensor([[self.rule]], dtype=torch.long),
                    'hand_len': torch.tensor([[len(self.player2_hand)]], dtype=torch.float32),
                    'my_palette_len': torch.tensor([[len(self.player2_palette)]], dtype=torch.float32),
                    'opp_hand_len': torch.tensor([[len(self.player1_hand)]], dtype=torch.float32),
                    'opp_palette_len': torch.tensor([[len(self.player1_palette)]], dtype=torch.float32),
                    'known_deck': torch.tensor(self._deck_mask()).unsqueeze(0),
                }
   
    """
        Execute game move.
        
        Args:
            action (tuple): (card_to_palette, card_to_rule)
                - card_to_palette (int): Card ID for palette (0-skip)
                - card_to_rule (int): Card ID for rule change (0-skip)
                
        Returns:
            tuple: (obs, reward, done, info)
                - obs (dict): New state
                - reward (float): Action reward
                - done (bool): Game over flag
                - info (dict): Additional info (empty)
                
        Reward logic:
            +0.1 for adding to palette
            +0.05 for changing rule
            +0.3 for maintaining winning position
            ±10 for win/loss
        """
    def step(self, action: Tuple[int, int]):
        if self.done:
            raise ValueError("Game is already over.")

        play_card, rule_card = action


        if self._current_player == 0:
            hand = self.player1_hand
            palette = self.player1_palette
            opponent_hand = self.player2_hand
            opponent_palette = self.player2_palette
        else:
            hand = self.player2_hand
            palette = self.player2_palette
            opponent_hand = self.player1_hand
            opponent_palette = self.player1_palette

        reward = 0.0

        def valid_card(x): return x != 0 and x in hand

        if valid_card(play_card):
            hand.remove(play_card)
            palette.append(play_card)
            reward += 0.1

        if valid_card(rule_card) and rule_card != play_card:
            hand.remove(rule_card)
            self.rule = (rule_card - 1) // 7
            reward += 0.05
        reward += float(min(len(hand)-len(opponent_hand),0)*1.2)
        if not check_win(palette, [opponent_palette], self.rule):
            self.done = True
            reward = -10.0 if self._current_player == 0 else 10.0
            self.winner = 1 - self._current_player 
            return self._get_obs(), reward, self.done, {}
        reward += 0.3
        has_winning_move = any(
            check_win(opponent_palette + [rc], [palette], card_color(rc))
            for rc in opponent_hand
        ) or any(
            check_win(opponent_palette, [palette], card_color(rc))
            for rc in opponent_hand
        ) or any(
            check_win(opponent_palette + [pc], [palette], card_color(rc))
            for pc in opponent_hand
            for rc in opponent_hand
            if pc != rc
        )

        if len(hand) == 0:
            if not has_winning_move:
                self.done = True
                self.winner = self._current_player
                reward = 10.0 if self._current_player == 0 else -10.0
            else:
                self.done = True
                self.winner = 1 - self._current_player
                reward = -10.0 if self._current_player == 0 else 10.0
            return self._get_obs(), reward, self.done, {}

        

        if not has_winning_move:
            self.done = True
            reward = 10.0 if self._current_player == 0 else -10.0
            self.winner = self._current_player
            #print(f"Player {self._current_player + 1} has no winning moves. Game over.")
            return self._get_obs(), reward, self.done, {}

        self._current_player = 1 - self._current_player
        return self._get_obs(), reward, self.done, {}

    """
        Apply pre-generated move.
        
        Args:
            player_id (int): 0 or 1
            move (tuple): (rule_card, new_hand, new_palette)
                - rule_card: Rule card ID
                - new_hand: New hand after move
                - new_palette: New palette
        """
    def apply_move(self, player_id: int, move: Tuple[int, List[int], List[int]]):
        """
        Применяет выигрышный ход к среде Red7. Аналогично step, но на вход принимает move из get_winning_moves.
        :param player_id: 0 или 1 — индекс игрока
        :param move: кортеж (rule_card, new_hand, new_palette)
        """
        rule_card, new_hand, new_palette = move

        if player_id == 0:
            self.player1_hand = new_hand
            self.player1_palette = new_palette
        else:
            self.player2_hand = new_hand
            self.player2_palette = new_palette

        self.rule = card_color(rule_card)
        self._current_player = 1 - self._current_player
    
    """
        Create deep copy of current environment.
        
        Returns:
            Red7Env: New identical environment
        """
    def copy(self):
        """Create a deep copy of the environment"""
        new_env = Red7Env(verbose=False)
        new_env.deck = self.deck.copy()
        new_env.player1_hand = self.player1_hand.copy()
        new_env.player2_hand = self.player2_hand.copy()
        new_env.player1_palette = self.player1_palette.copy()
        new_env.player2_palette = self.player2_palette.copy()
        new_env.rule = self.rule
        new_env._current_player = self._current_player
        new_env.done = self.done
        new_env.winner = self.winner
        return new_env


"""
    Get card numerical value.
    
    Args:
        card (int): Card ID (1-49)
        
    Returns:
        int: Value from 1 to 7
        
    Example:
        1 → 1 (R1)
        15 → 1 (Y1)
        22 → 1 (G1)
    """
def card_value(card: int) -> int:
    return (card - 1) % 7 + 1

"""
    Get card color index.
    
    Args:
        card (int): Card ID
        
    Returns:
        int: Color index (0-6)
        
    Example:
        1 → 0 (Red)
        8 → 1 (Orange)
    """
def card_color(card: int) -> int:
    if card == 0 : return 0
    return (card - 1) // 7

"""
    Compare two cards by game rules.
    
    Args:
        a, b (int): Card IDs
        
    Returns:
        bool: True if a < b by game rules
        
    Rules:
        1. First by value (1 < 2 < ... < 7)
        2. If equal - by color (V > B > L > ... > R)
    """
def compare_cards(a: int, b: int) -> bool:
    va, vb = card_value(a), card_value(b)
    if va != vb:
        return va < vb
    return card_color(a) > card_color(b)

"""
    Find maximum card in list.
    
    Args:
        cards (list[int]): List of card IDs
        
    Returns:
        int: ID of maximum card
        
    Raises:
        RuntimeError: If list empty
    """
def find_max_card(cards: List[int]) -> int:
    if not cards:
        raise RuntimeError("Empty card list")
    max_card = cards[0]
    for c in cards[1:]:
        if compare_cards(max_card, c):
            max_card = c
    return max_card

"""
    Orange rule: most cards of same value.
    
    Returns:
        tuple: (count, card)
            - count: Max number of same values
            - card: Best card in group
    """
def comparison_orange(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0
    groups = defaultdict(list)
    for c in cards:
        groups[card_value(c)].append(c)

    max_count = 0
    max_card = cards[0]
    for group in groups.values():
        count = len(group)
        local_max = find_max_card(group)
        if count > max_count or (count == max_count and compare_cards(max_card, local_max)):
            max_count = count
            max_card = local_max
    return max_count, max_card

"""
    Yellow rule: most cards of same color.
    
    Returns:
        tuple: (count, card)
            - count: Max number of same color
            - card: Best card of color
    """
def comparison_yellow(cards: List[int]) -> Tuple[int, int]:
    if len(cards)==0:
        return 0,0
    groups = defaultdict(list)
    for c in cards:
        groups[card_color(c)].append(c)

    max_count = 0
    max_card = cards[0]
    for group in groups.values():
        count = len(group)
        local_max = find_max_card(group)
        if count > max_count or (count == max_count and compare_cards(max_card, local_max)):
            max_count = count
            max_card = local_max
    return max_count, max_card

"""
    Green rule: number of even-valued cards.
    
    Returns:
        tuple: (count, card)
            - count: Number of even cards
            - card: Best even card
    """
def comparison_green(cards: List[int]) -> Tuple[int, int]:
    if len(cards)==0:
        return 0,0
    filtered = [c for c in cards if card_value(c) % 2 == 0]
    if not filtered:
        return 0, 0
    return len(filtered), find_max_card(filtered)

"""
    Light Blue rule: number of different colors.
    
    Returns:
        tuple: (count, card)
            - count: Unique color count
            - card: Best card among them
    """
def comparison_lightblue(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0
    unique_colors = {card_color(c) for c in cards}
    return len(unique_colors), find_max_card(cards)

"""
    Blue rule: longest sequence of consecutive values.
    
    Returns:
        tuple: (length, card)
            - length: Longest sequence length
            - card: Best card in sequence
    """
def comparison_blue(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0

    values = sorted(set(card_value(c) for c in cards))
    max_len = 1
    cur_len = 1
    sequences = []
    temp_start = 0

    for i in range(1, len(values)):
        if values[i] == values[i - 1] + 1:
            cur_len += 1
        elif values[i] == values[i - 1]:
            continue
        else:
            sequences.append((cur_len, values[temp_start]))
            cur_len = 1
            temp_start = i
    
   
    sequences.append((cur_len, values[temp_start]))

    if not sequences:
        return 0, 0

    
    max_len = max(seq[0] for seq in sequences)
    
    
    max_sequences = [seq for seq in sequences if seq[0] == max_len]
    
    
    if len(max_sequences) > 1:
        
        best_seq = max(max_sequences, key=lambda x: x[1] + x[0] - 1) 
    else:
        best_seq = max_sequences[0]

    seq_values = set(range(best_seq[1], best_seq[1] + best_seq[0]))

    max_card = None
    for c in cards:
        if card_value(c) in seq_values:
            if max_card is None or compare_cards(max_card, c):
                max_card = c

    return max_len, max_card

"""
    Violet rule: number of cards with value < 4.
    
    Returns:
        tuple: (count, card)
            - count: Number of cards 1-3
            - card: Best such card
    """
def comparison_violet(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0
    filtered = [c for c in cards if card_value(c) < 4]
    if not filtered:
        return 0, 0
    return len(filtered), find_max_card(filtered)

"""
    Check if palette is winning.
    
    Args:
        me (list): Current player's cards
        other_palettes (list): Opponents' palettes
        rule_color (int): Current rule index (0-6)
        
    Returns:
        bool: True if 'me' beats all opponents
    """
def check_win(me: List[int], other_palettes: List[List[int]], rule_color: int) -> bool:
    if len(me) == 0:
        return False
    if rule_color == 0:
        my_result = (1, find_max_card(me))
    elif rule_color == 1:
        my_result = comparison_orange(me)
    elif rule_color == 2:
        my_result = comparison_yellow(me)
    elif rule_color == 3:
        my_result = comparison_green(me)
    elif rule_color == 4:
        my_result = comparison_lightblue(me)
    elif rule_color == 5:
        my_result = comparison_blue(me)
    elif rule_color == 6:
        my_result = comparison_violet(me)
    else:
        return False
    if my_result[0] == 0:
        return False
    for opp in other_palettes:
        if len(opp) == 0:
            continue
        if rule_color == 0:
            opp_result = (1, find_max_card(opp))
        elif rule_color == 1:
            opp_result = comparison_orange(opp)
        elif rule_color == 2:
            opp_result = comparison_yellow(opp)
        elif rule_color == 3:
            opp_result = comparison_green(opp)
        elif rule_color == 4:
            opp_result = comparison_lightblue(opp)
        elif rule_color == 5:
            opp_result = comparison_blue(opp)
        elif rule_color == 6:
            opp_result = comparison_violet(opp)
        else:
            return False

        if (my_result[0] < opp_result[0]) or (
                my_result[0] == opp_result[0] and compare_cards(my_result[1], opp_result[1])):
            return False

    return True

"""
    Generate all valid winning moves.
    
    Args:
        rule_card (int): Current rule card
        hand (list): Cards in hand
        my_palette (list): Current palette
        other_palettes (list): Opponents' palettes
        
    Returns:
        list: Tuples of (rule_card, new_hand, new_palette)
    """
def get_winning_moves(
    rule_card: int,
    hand: List[int],
    my_palette: List[int],
    other_palettes: List[List[int]],
) -> List[Tuple[int, List[int], List[int]]]:
    results = []
    current_rule = card_color(rule_card)

    for i, card in enumerate(hand):
        new_palette = my_palette + [card]
        if check_win(new_palette, other_palettes, current_rule):
            new_hand = hand[:i] + hand[i+1:]
            results.append((rule_card, new_hand, new_palette))

    for i, card in enumerate(hand):
        new_rule = card_color(card)
        new_rule_card = card
        new_hand = hand[:i] + hand[i+1:]
        if check_win(my_palette, other_palettes, new_rule):
            results.append((new_rule_card, new_hand, my_palette))

    for i in range(len(hand)):
        for j in range(len(hand)):
            if i == j:
                continue
            palette_card = hand[i]
            new_rule_card = hand[j]
            new_palette = my_palette + [palette_card]
            new_rule = card_color(new_rule_card)
            new_hand = [hand[k] for k in range(len(hand)) if k != i and k != j]
            if check_win(new_palette, other_palettes, new_rule):
                results.append((new_rule_card, new_hand, new_palette))

    return results

"""
    Print legal moves matrix in readable format.
    
    Args:
        mask (np.ndarray): 50x50 legal actions matrix
        hand (list): Current player's hand cards
    """
def print_legal_moves(mask, hand):
    """Визуализация доступных ходов"""
    print("\nLegal moves (row=palette, col=rule):")
    print("     " + " ".join(f"{c:>3}" for c in range(50)))
    for i in range(50):
        row = [f"{i:>2} |"]
        for j in range(50):
            if mask[i,j] > 0 and (i in hand or i == 0) and (j in hand or j == 0):
                row.append(f"{'X':>3}")
            else:
                row.append(f"{'':>3}")
        print(" ".join(row))
    print("\nYour hand:", [c for c in hand if c != 0])

import numpy as np
import random
from typing import Tuple, List
import torch
import colorama
from colorama import Fore, Style
from collections import defaultdict

colorama.init(autoreset=True)

class Red7Env:
    COLORS = ["R", "O", "Y", "G", "L", "B", "V"]
    COLOR_NAMES = ["Red", "Orange", "Yellow", "Green", "LightBlue", "Blue", "Violet"]
    COLOR_CODES = [Fore.RED, Fore.LIGHTRED_EX, Fore.YELLOW, Fore.GREEN,
                   Fore.CYAN, Fore.BLUE, Fore.MAGENTA]



    def __init__(self, seed: int = None, verbose: bool = True):
        self.hand_size = 7
        self.verbose = verbose
        if seed is not None:
            self.seed(1)
        self.reset()

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
    def current_player(self):
        return self._current_player

    def _pad(self, cards):
        return np.array(cards + [0] * (self.hand_size - len(cards)), dtype=np.int64)

    def _deck_mask(self):
        mask = np.zeros(49, dtype=np.float32)
        for card in self.deck:
            mask[card - 1] = 1.0
        return mask

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
        else:
            hand = self.player2_hand
        hand_set = set(hand)

        # Ход с добавлением карты в палитку (i > 0, j == 0)
        for i in range(1, 50):
            if i in hand_set:
                mask[i][0] = 1.0
                # Двойной ход: добавить карту в палитку + сменить правило
                for j in range(1, 50):
                    if j in hand_set and i != j:
                        mask[i][j] = 1.0
        # Смена правила (i == 0, j > 0)
        for j in range(1, 50):
            if j in hand_set:
                mask[0][j] = 1.0

        return mask


    def render(self):
        cp = 1 - self._current_player
        print("\n" + "="*42)
        print(f"{Style.BRIGHT}Current Turn: Player {cp}")
        print("-" * 42)
        print(f"{Style.BRIGHT}Player 0 (You):")
        print(f"  Hand:    {self._cards_to_str(self.player1_hand)}")
        print(f"  Palette: {self._cards_to_str(self.player1_palette)}")
        print(f"{Style.BRIGHT}Player 1 (Opponent):")
        print(f"  Hand:    {self._cards_to_str(self.player2_hand)}")
        print(f"  Palette: {self._cards_to_str(self.player2_palette)}")
        print(f"\nCurrent Rule: {self.COLOR_NAMES[self.rule]}")
        print(f"Deck: {len(self.deck)} cards remaining")
        print("="*42 + "\n")


    def _color_str(self, card: int) -> str:
        if card < 1 or card > 49:
            return "Invalid"
        val = (card - 1) % 7 + 1
        col = (card - 1) // 7
        return self.COLOR_CODES[col] + f"{self.COLORS[col]}{val}" + Style.RESET_ALL


    def _cards_to_str(self, cards: List[int]) -> str:
        return " ".join([self._color_str(c) for c in sorted(cards)])


    def get_rule_card(self) -> int:
        """Возвращает текущую карту правила."""
        return self.rule


    def get_hand(self, player_index: int) -> List[int]:
        """Возвращает руку игрока по индексу (0 или 1)."""
        if player_index == 0:
            return self.player1_hand
        elif player_index == 1:
            return self.player2_hand
        else:
            raise ValueError("Invalid player index. Only 0 or 1 are allowed.")


    def get_palette(self, player_index: int) -> List[int]:
        """Возвращает палитру игрока по индексу (0 или 1)."""
        if player_index == 0:
            return self.player1_palette
        elif player_index == 1:
            return self.player2_palette
        else:
            raise ValueError("Invalid player index. Only 0 or 1 are allowed.")


    def get_winner(self) -> int:
        """Возвращает индекс победившего игрока, или -1 если нет победителя."""
        return self.winner


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
            reward += 0.2

        if valid_card(rule_card) and rule_card != play_card:
            hand.remove(rule_card)
            self.rule = (rule_card - 1) // 7
            reward += 0.1
        reward += float(min(len(hand)-len(opponent_hand),0)*0.3)
        if not check_win(palette, [opponent_palette], self.rule):
            self.done = True
            reward = -10.0 if self._current_player == 0 else 10.0
            self.winner = 1 - self._current_player 
            return self._get_obs(), reward, self.done, {}
        reward += 0.5
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

        # Переключение игрока
        self._current_player = 1 - self._current_player
        return self._get_obs(), reward, self.done, {}

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



def card_value(card: int) -> int:
    return (card - 1) % 7 + 1

def card_color(card: int) -> int:
    if card == 0 : return 0
    return (card - 1) // 7

def compare_cards(a: int, b: int) -> bool:
    va, vb = card_value(a), card_value(b)
    if va != vb:
        return va < vb
    return card_color(a) > card_color(b)  # меньший цвет считается лучше

def find_max_card(cards: List[int]) -> int:
    if not cards:
        raise RuntimeError("Empty card list")
    max_card = cards[0]
    for c in cards[1:]:
        if compare_cards(max_card, c):  # если max_card < c → обновить
            max_card = c
    return max_card

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

def comparison_green(cards: List[int]) -> Tuple[int, int]:
    if len(cards)==0:
        return 0,0
    filtered = [c for c in cards if card_value(c) % 2 == 0]
    if not filtered:
        return 0, 0
    return len(filtered), find_max_card(filtered)

def comparison_lightblue(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0
    unique_colors = {card_color(c) for c in cards}
    return len(unique_colors), find_max_card(cards)

def comparison_blue(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0

    values = sorted(set(card_value(c) for c in cards))
    max_len = 1
    cur_len = 1
    sequences = []  # Будем хранить все последовательности (длина, начальное значение)
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
    
    # Добавляем последнюю последовательность
    sequences.append((cur_len, values[temp_start]))

    if not sequences:
        return 0, 0

    # Находим максимальную длину
    max_len = max(seq[0] for seq in sequences)
    
    # Фильтруем последовательности с максимальной длиной
    max_sequences = [seq for seq in sequences if seq[0] == max_len]
    
    # Если несколько последовательностей, выбираем с наибольшей картой
    if len(max_sequences) > 1:
        # Выбираем последовательность с наибольшим начальным значением (так как они последовательные)
        best_seq = max(max_sequences, key=lambda x: x[1] + x[0] - 1)  # начальное + длина -1 = последнее значение
    else:
        best_seq = max_sequences[0]

    # Вычисляем диапазон значений в выбранной последовательности
    seq_values = set(range(best_seq[1], best_seq[1] + best_seq[0]))

    # Ищем лучшую карту среди тех, которые входят в эту последовательность
    max_card = None
    for c in cards:
        if card_value(c) in seq_values:
            if max_card is None or compare_cards(max_card, c):
                max_card = c

    return max_len, max_card

def comparison_violet(cards: List[int]) -> Tuple[int, int]:
    if len(cards) == 0:
        return 0, 0
    filtered = [c for c in cards if card_value(c) < 4]
    if not filtered:
        return 0, 0
    return len(filtered), find_max_card(filtered)

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

def get_winning_moves(
    rule_card: int,
    hand: List[int],
    my_palette: List[int],
    other_palettes: List[List[int]],
) -> List[Tuple[int, List[int], List[int]]]:
    results = []
    current_rule = card_color(rule_card)

    # 1. Добавить карту в палетку (не меняя правило)
    for i, card in enumerate(hand):
        new_palette = my_palette + [card]
        if check_win(new_palette, other_palettes, current_rule):
            new_hand = hand[:i] + hand[i+1:]
            results.append((rule_card, new_hand, new_palette))

    # 2. Сменить правило (не добавляя в палетку)
    for i, card in enumerate(hand):
        new_rule = card_color(card)
        new_rule_card = card
        new_hand = hand[:i] + hand[i+1:]
        if check_win(my_palette, other_palettes, new_rule):
            results.append((new_rule_card, new_hand, my_palette))

    # 3. Добавить карту в палетку и сменить правило (двойной ход)
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

def simple_ai_move(env: Red7Env):
    mask = env.legal_actions_mask()
    hand = env.opponent_hand
    palette = env.opponent_palette
    my_palette = env.player_palette
    best_move = None

    for i in range(50):
        for j in range(50):
            if mask[i][j] > 0:
                temp_hand = hand[:]
                temp_palette = palette[:]
                rule = env.rule
                if i != 0 and i in temp_hand:
                    temp_hand.remove(i)
                    temp_palette.append(i)
                if j != 0 and j in temp_hand:
                    if j != i:
                        temp_hand.remove(j)
                    rule = (j - 1) // 7

                if check_win(temp_palette, [my_palette], rule):
                    return (i, j)

    # Если нет выигрышных — просто первый доступный ход
    for i in range(50):
        for j in range(50):
            if mask[i][j] > 0:
                return (i, j)

    return (0, 0)


def play_vs_ai(agent, num_games=1, verbose=True):
    """
    Игра против обученного DQN агента
    :param agent: Обученный DQNAgent
    :param num_games: Количество игр
    :param verbose: Вывод ходов
    """
    env = Red7Env(verbose=verbose)
    agent.epsilon = 0.01  # Минимальная exploration
    
    results = {'wins': 0, 'losses': 0, 'draws': 0}
    
    for game in range(1, num_games+1):
        obs = env.reset()
        done = False
        
        if verbose:
            print(f"\n=== Game {game}/{num_games} ===")
            env.render()
        
        while not done:
            current_player = env.current_player()
            
            if current_player == 0:  # Ход человека
                if verbose:
                    print("\nYour turn!")
                    print("Your hand:", env._cards_to_str(env.player1_hand))
                
                legal_mask = env.legal_actions_mask()
                if not legal_mask.any():
                    print("No legal moves! You lose.")
                    done = True
                    break
                
                # Ввод хода
                while True:
                    try:
                        move_input = input("Enter your move as 'palette_card rule_card' (0 to pass): ")
                        play_card, rule_card = map(int, move_input.split())
                        
                        # Проверка допустимости хода
                        if (play_card == 0 and rule_card == 0) or legal_mask[play_card, rule_card] > 0:
                            break
                        print("Invalid move! Legal moves matrix:")
                        print_legal_moves(legal_mask, env.player1_hand)
                    except:
                        print("Invalid input! Example: '12 0' to play card 12 to palette")
                
                action = (play_card, rule_card)
                
            else:  # Ход ИИ
                if verbose:
                    print("\nAI's turn...")
                
                with torch.no_grad():
                    obs_tensor = {k: v.to(agent.device) for k, v in obs.items()}
                    q_values = agent.model(obs_tensor)[0].cpu().numpy()
                
                legal_mask = env.legal_actions_mask()
                q_values[legal_mask == 0] = -np.inf
                action = np.unravel_index(np.argmax(q_values), q_values.shape)
                
                if verbose:
                    action_desc = f"Palette: {action[0]}, Rule: {action[1]}"
                    print(f"AI plays: {action_desc}")
            
            # Применяем ход
            obs, reward, done, _ = env.step(action)
            
            if verbose:
                env.render()
                if done:
                    winner = env.get_winner()
                    if winner == 0:
                        print("You won!")
                        results['wins'] += 1
                    elif winner == 1:
                        print("AI won!")
                        results['losses'] += 1
                    else:
                        print("Draw!")
                        results['draws'] += 1
    
    if num_games > 1:
        print("\n=== Final Results ===")
        print(f"Wins: {results['wins']}")
        print(f"Losses: {results['losses']}")
        print(f"Draws: {results['draws']}")
        print(f"Win Rate: {results['wins']/num_games*100:.1f}%")

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


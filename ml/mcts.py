import random
from collections import defaultdict
import time
import math
import random
from collections import defaultdict

#class that describes a game state 
class Red7State:
    def __init__(self):
        #cards are tuples: (color: 0-6, number: 1-7)
        self.deck = [(color, num) for color in range(7) for num in range(1, 8)]
        random.shuffle(self.deck)
        
        #players: 0 = AI, 1 = Human
        self.players = {
            0: {"hand": [], "palette": []},
            1: {"hand": [], "palette": []}
        }
        
        #giving cards to players
        for _ in range(7):
            self.players[0]["hand"].append(self.deck.pop())
            self.players[1]["hand"].append(self.deck.pop())
        
        #parameters that describe the initial game state
        self.current_rule = 0  #current rule (0 = highest card, 1 = most of one number...6 = less than 4)
        self.current_player = 1  #0 = AI starts first
        self.done = False
        self.last_move = None

    #function that copies a given state
    def copy(self):
        """Create a deep copy of the game state."""
        new_state = Red7State()
        new_state.deck = self.deck.copy()
        new_state.players = {
            0: {
                "hand": self.players[0]["hand"].copy(),
                "palette": self.players[0]["palette"].copy()
            },
            1: {
                "hand": self.players[1]["hand"].copy(),
                "palette": self.players[1]["palette"].copy()
            }
        }
        new_state.current_rule = self.current_rule
        new_state.current_player = self.current_player
        new_state.done = self.done
        new_state.last_move = self.last_move
        return new_state

    #function that generates all possible moves 
    def generate_combinations(self):
        """Generate all possible move combinations for current player.
        Returns list of tuples: (rule_card, play_card) where either can be None"""
        hand = self.players[self.current_player]["hand"]
        combinations = []
        
        #generation of all possible rule changes that are different from current rule
        rule_cards = [card for card in hand if card[0] != self.current_rule]
        
        #generation of all possible play cards
        play_cards = hand.copy()
        
        #move when only change rule is used (play_card is None)
        for rc in rule_cards:
            combinations.append((rc, None))
        
        #move when only play card is used (rule_card is None)
        for pc in play_cards:
            combinations.append((None, pc))
        
        #move when both change rule and play card are used
        for rc in rule_cards:
            for pc in play_cards:
                if rc != pc:
                    combinations.append((rc, pc))
        
        return combinations

    #function that applies moves
    def apply_move(self, move):
        """Apply a move and advance game state."""
        rule_card, play_card = move
        player = self.current_player
        self.last_move = move

        #applying rule change if present
        if rule_card is not None:
            self.current_rule = rule_card[0]
            self.players[player]["hand"].remove(rule_card)

        #applying play card if present
        if play_card is not None:
            self.players[player]["palette"].append(play_card)
            self.players[player]["hand"].remove(play_card)

        #checking if player has no cards left
        if len(self.players[player]["hand"]) == 0:
            self.done = True
            return -2

        #checking if player is losing under current rule
        if not self.is_winning(player):
            self.done = True
            return -1

        #switching player
        self.current_player = 1 - player
        return 0

    #function that checks if a player is winning
    def is_winning(self, player):
        """Check if a player is winning the current rule."""
        palette = self.players[player]["palette"]
        opponent = 1 - player
        opp_palette = self.players[opponent]["palette"]

        #checks in case of emty palletes
        if not palette and not opp_palette:
            return True
        elif not palette:
            return False
        elif not opp_palette:
            return True
        
        if self.current_rule == 0:  #highest card with color tiebreaker                
            my_max_val = max([num for (_, num) in palette])
            opp_max_val = max([num for (_, num) in opp_palette])
            
            if my_max_val != opp_max_val:
                return my_max_val > opp_max_val
                
            #highest priority color
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_val]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_val]
            
            my_best_color = min([color for (color, _) in my_max_cards])
            opp_best_color = min([color for (color, _) in opp_max_cards])
            return my_best_color < opp_best_color
        
        elif self.current_rule == 1:  #most cards of same number
            my_counts = defaultdict(int)
            for (_, num) in palette:
                my_counts[num] += 1
            my_best = max(my_counts.values())
            
            opp_counts = defaultdict(int)
            for (_, num) in opp_palette:
                opp_counts[num] += 1
            opp_best = max(opp_counts.values())
            
            if my_best != opp_best:
                return my_best > opp_best
            
            #higher number wins
            my_top_num = max([num for num, cnt in my_counts.items() if cnt == my_best])
            opp_top_num = max([num for num, cnt in opp_counts.items() if cnt == opp_best])

            if my_top_num != opp_top_num:
                return my_top_num > opp_top_num
            
            #highest priority color (0=red is best)
            my_max_cards = [(color, num) for (color, num) in palette if num == my_top_num]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_top_num]
            
            my_best_color = min([color for (color, _) in my_max_cards])
            opp_best_color = min([color for (color, _) in opp_max_cards])

            return my_best_color < opp_best_color

        
        elif self.current_rule == 2:  #most of one color
            my_counts = defaultdict(int)
            for (color, num) in palette:
                my_counts[color] += 1
            my_best = max(my_counts.values())
            
            opp_counts = defaultdict(int)
            for (color, num) in opp_palette:
                opp_counts[color] += 1
            opp_best = max(opp_counts.values())
            
            if my_best != opp_best:
                return my_best > opp_best
            
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
                return my_max_num > opp_max_num
            
            #highest priority color among those cards
            my_best_color = min([color for (color, num) in my_cards_in_top_colors if num == my_max_num])
            opp_best_color = min([color for (color, num) in opp_cards_in_top_colors if num == opp_max_num])
            
            return my_best_color < opp_best_color
        
        elif self.current_rule == 3:  #most even cards
            my_evens = sum(1 for (_, num) in palette if num % 2 == 0)
            opp_evens = sum(1 for (_, num) in opp_palette if num % 2 == 0)
            
            if my_evens != opp_evens:
                return my_evens > opp_evens
            
            #highest even card
            my_max_even = max([num for (_, num) in palette if num % 2 == 0], default=0)
            opp_max_even = max([num for (_, num) in opp_palette if num % 2 == 0], default=0)
            
            if my_max_even != opp_max_even:
                return my_max_even > opp_max_even
            
            #color priority among highest even cards
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_even]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_even]

            if len(my_max_cards) == 0:
                return False
            
            my_best_color = min([color for (color, _) in my_max_cards], default=7)
            opp_best_color = min([color for (color, _) in opp_max_cards], default=7)
            
            return my_best_color < opp_best_color
        
        elif self.current_rule == 4: #most different colors
            my_colors = len({color for (color, _) in palette})
            opp_colors = len({color for (color, _) in opp_palette})
            
            if my_colors != opp_colors:
                return my_colors > opp_colors
            
            #highest priority number
            my_max_val = max([num for (_, num) in palette])
            opp_max_val = max([num for (_, num) in opp_palette])
            
            if my_max_val != opp_max_val:
                return my_max_val > opp_max_val
                
            #highest priority color
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_val]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_val]
            
            my_best_color = min([color for (color, _) in my_max_cards])
            opp_best_color = min([color for (color, _) in opp_max_cards])
            return my_best_color < opp_best_color
        
        elif self.current_rule == 5:  #longest sequence
            def longest_sequence_info(cards):
                numbers = sorted({num for (_, num) in cards})  #unique numbers
                if not numbers:
                    return (0, 0, 0)  #(length, max_num, best_color)
                
                max_len = 1
                current_len = 1
                best_max_num = numbers[0]
                
                for i in range(1, len(numbers)):
                    if numbers[i] == numbers[i-1] + 1:
                        current_len += 1
                        if current_len >= max_len:
                            max_len = current_len
                            best_max_num = numbers[i]  #tracking the highest num in the longest seq
                    else:
                        current_len = 1
                
                #getting all cards in the longest sequence
                seq_cards = [(color, num) for (color, num) in cards 
                            if num >= best_max_num - max_len + 1 and num <= best_max_num]
                
                #highest priority color in the sequence
                best_color = min([color for (color, num) in seq_cards])
                return (max_len, best_max_num, best_color)
            
            my_len, my_max_num, my_color = longest_sequence_info(palette)
            opp_len, opp_max_num, opp_color = longest_sequence_info(opp_palette)
            
            #comparing sequence lengths
            if my_len != opp_len:
                return my_len > opp_len
            
            #comparing highest numbers in the sequence if len == 1
            if my_len == opp_len == 1:
                #highest priority number
                my_max_val = max([num for (_, num) in palette])
                opp_max_val = max([num for (_, num) in opp_palette])
            
                if my_max_val != opp_max_val:
                    return my_max_val > opp_max_val
                #highest priority color
                my_max_cards = [(color, num) for (color, num) in palette if num == my_max_val]
                opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_val]
                
                my_best_color = min([color for (color, _) in my_max_cards])
                opp_best_color = min([color for (color, _) in opp_max_cards])
                return my_best_color < opp_best_color
            
            #comparing highest numbers in the sequence
            if my_max_num != opp_max_num:
                return my_max_num > opp_max_num
            
            #comparing color priority of the highest sequence number
            return my_color < opp_color
        
        elif self.current_rule == 6:  #most cards less than 4
            my_lt4 = sum(1 for (_, num) in palette if num < 4)
            opp_lt4 = sum(1 for (_, num) in opp_palette if num < 4)
            
            if my_lt4 != opp_lt4:
                return my_lt4 > opp_lt4
            
            #highest card under 4
            my_max_lt4 = max([num for (_, num) in palette if num < 4], default=0)
            opp_max_lt4 = max([num for (_, num) in opp_palette if num < 4], default=0)
            
            if my_max_lt4 != opp_max_lt4:
                return my_max_lt4 > opp_max_lt4
            
            #color priority among highest cards < 4
            my_max_cards = [(color, num) for (color, num) in palette if num == my_max_lt4]
            opp_max_cards = [(color, num) for (color, num) in opp_palette if num == opp_max_lt4]

            if len(my_max_cards) == 0:
                return False
            
            my_best_color = min([color for (color, _) in my_max_cards], default=7)
            opp_best_color = min([color for (color, _) in opp_max_cards], default=7)
            
            return my_best_color < opp_best_color

#class that describes a node in the Monte Carlo Tree
class MCTSNode:
    def __init__(self, state, parent=None, move=None):
        self.state = state
        self.parent = parent
        self.move = move
        self.children = []
        self.wins = 0
        self.visits = 0
        self.untried_moves = state.generate_combinations()
        self.is_single_card_move = (move is None) or (move[0] is None) or (move[1] is None)
    
    #function that selects the best child node
    def select_child(self):
        """Select child node using UCT with preference for single-card moves"""
        if not self.children:
            return None
            
        exploration_weight = 1.4

        return max(self.children, key=lambda child: 
                  (child.wins / child.visits) + 
                  exploration_weight * math.sqrt(math.log(self.visits) / child.visits) +
                  (0.3 if child.is_single_card_move else 0))
    
    #function that expands the tree branches
    def expand(self):
        """Expand moves, preferring single-card moves first"""
        if not self.untried_moves:
            return None
        
        #sorting of the untried moves so single-card moves come first
        self.untried_moves.sort(key=lambda m: 0 if (m[0] is None or m[1] is None) else 1)
        
        move = self.untried_moves[0]
        self.untried_moves.remove(move)
        
        new_state = self.state.copy()
        result = new_state.apply_move(move)
        child_node = MCTSNode(new_state, self, move)
        self.children.append(child_node)
        return child_node
    
    #function that updates the numbers of wins/visits of the node
    def update(self, result):
        """Update node statistics"""
        self.visits += 1
        self.wins += result
    
    #function that checks if the branch is fully expanded
    def is_fully_expanded(self):
        return len(self.untried_moves) == 0
    
    #function that checks if the moves of a branch lead to losing
    def is_terminal(self):
        return self.state.done

#class that describes AI behaviour using MCTS
class MCTSAI:
    def __init__(self, iteration_limit=2000):
        self.iteration_limit = iteration_limit
    
    #function that chooses AI next move
    def get_move(self, state):
        root = MCTSNode(state)
        
        for _ in range(self.iteration_limit):
            node = root
            
            #selection
            while node.is_fully_expanded() and not node.is_terminal():
                child = node.select_child()
                if child is None:
                    break
                node = child
            
            #expansion
            if not node.is_terminal():
                child = node.expand()
                if child is not None:
                    node = child
            
            #simulation
            temp_state = node.state.copy()
            while not temp_state.done:
                possible_moves = temp_state.generate_combinations()
                if not possible_moves:
                    break
                move = random.choice(possible_moves)
                result = temp_state.apply_move(move)
                if result == -1: 
                    break
            
            #backpropagation
            result = 1 if temp_state.current_player != state.current_player else 0
            while node is not None:
                node.update(result)
                node = node.parent
        
        if not root.children:
            return (None, None)
        
        #choosing the move with highest visits, preferring single-card moves
        best_child = max(root.children, 
                        key=lambda child: (child.visits, child.is_single_card_move))
        return best_child.move
    
#class that describes the game itself
class Red7Game:
    def __init__(self):
        self.state = Red7State()
        self.ai = MCTSAI(iteration_limit=1000)
    
    def print_state(self):
        """Print the current game state"""
        print("\n" + "="*40)
        print(f"Current Rule: {self.get_rule_name(self.state.current_rule)}")
        print(f"Current Player: {'AI' if self.state.current_player == 0 else 'You'}")
        
        print("\nAI Palette:", self.format_cards(self.state.players[0]["palette"]))
        print("Your Palette:", self.format_cards(self.state.players[1]["palette"]))
        
        print("\nYour Hand:", self.format_cards(self.state.players[1]["hand"]))
        print("\nAI Hand:", self.format_cards(self.state.players[0]["hand"]))
    
    def get_rule_name(self, rule_num):
        rules = {
            0: "Highest Card",
            1: "Most of One Number",
            2: "Most of One Color",
            3: "Most Even Cards",
            4: "Most Different Colors",
            5: "Longest Sequence",
            6: "Most Cards < 4"
        }
        return rules.get(rule_num, "Unknown Rule")
    
    def format_cards(self, cards):
        color_names = ["Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet"]
        return [f"{color_names[c]}-{n}" for c, n in sorted(cards, key=lambda x: (x[0], x[1]))]
    
    #function that describes AI's turn
    def ai_turn(self):
        print("\nAI is thinking...")
        start_time = time.time()
        move = self.ai.get_move(self.state)
        end_time = time.time()
        print(f"AI thought for {end_time - start_time:.2f} seconds")
        
        if move == (None, None):
            print("AI has no valid moves and must pass")
            return move
            
        rule_card, play_card = move
        if rule_card:
            print(f"AI changes rule to {self.get_rule_name(rule_card[0])}")
        if play_card:
            print(f"AI plays {self.format_cards([play_card])[0]}")
        
        return move
    
    #function that describes human's turn
    def human_turn(self):
        self.print_state()
        
        while True:
            print("\nPossible moves:")
            moves = self.state.generate_combinations()
            
            if not moves:
                print("No cards left in your hand - you lose automatically!")
                return (None, None)
            
            for i, move in enumerate(moves):
                rule_card, play_card = move
                move_desc = []
                if rule_card:
                    move_desc.append(f"Change rule to {self.get_rule_name(rule_card[0])} ({self.format_cards([rule_card])[0]})")
                if play_card:
                    move_desc.append(f"Play {self.format_cards([play_card])[0]}")
                print(f"{i+1}: {' + '.join(move_desc) if move_desc else 'Pass'}")

            try:
                choice = int(input("\nEnter your move number: ")) - 1
                if 0 <= choice < len(moves):
                    return moves[choice]
                print("Invalid choice. Please try again.")
            except ValueError:
                print("Please enter a number.")

    #function that represents logic of players making moves
    def play(self):
        print("Welcome to Red7! You're playing against the AI.")
        
        while not self.state.done:
            if self.state.current_player == 0:  #AI's turn
                move = self.ai_turn()
            else:  #human's turn
                move = self.human_turn()
            
            result = self.state.apply_move(move)
            
            #checking if game ended due to empty hand
            if result == -2:
                loser = self.state.current_player
                winner = 1 - loser
                print(f"\n{'AI' if loser == 0 else 'You'} have no cards left!")
                print(f"Game over! {'AI' if winner == 0 else 'You'} won!")
                return
        
        #regular game over condition
        winner = 1 - self.state.current_player
        print(f"\nGame over! {'AI' if winner == 0 else 'You'} won!")
        self.print_state()

#running the game
if __name__ == "__main__":
    game = Red7Game()
    game.play()
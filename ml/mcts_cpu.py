import random
import time
import math
from collections import defaultdict
from enviroment import Red7Env, check_win, card_color, card_value, get_winning_moves

class MCTSNode:
    def __init__(self, env, parent=None, move=None):
        self.env = env.copy() if env else None
        self.parent = parent
        self.move = move
        self.children = []
        self.wins = 0
        self.visits = 0
        self.untried_moves = self._generate_combinations() if env else []
        self.is_single_card_move = (move is None) or (move[0] == 0) or (move[1] == 0)
    
    def _generate_combinations(self):
        """Generate all possible move combinations for current player."""
        hand = self.env.get_hand(self.env.current_player())
        combinations = []
        
        # Generate all possible rule changes (different from current rule)
        rule_cards = [card for card in hand if card_color(card) != self.env.rule]
        
        # Generate all possible play cards
        play_cards = hand.copy()
        
        # Move when only changing rule (play_card is 0)
        for rc in rule_cards:
            combinations.append((0, rc))
        
        # Move when only playing card (rule_card is 0)
        for pc in play_cards:
            combinations.append((pc, 0))
        
        # Move when both changing rule and playing card
        for rc in rule_cards:
            for pc in play_cards:
                if rc != pc:
                    combinations.append((pc, rc))
        
        return combinations
    
    def select_child(self):
        """Select child node using UCT with preference for single-card moves"""
        if not self.children:
            return None
            
        exploration_weight = 1.4

        return max(self.children, key=lambda child: 
                  (child.wins / child.visits) + 
                  exploration_weight * math.sqrt(math.log(self.visits) / child.visits) +
                  (0.3 if child.is_single_card_move else 0))
    
    def expand(self):
        """Expand moves, preferring single-card moves first"""
        if not self.untried_moves:
            return None
        
        # Sort untried moves so single-card moves come first
        self.untried_moves.sort(key=lambda m: 0 if (m[0] == 0 or m[1] == 0) else 1)
        
        move = self.untried_moves[0]
        self.untried_moves.remove(move)
        
        new_env = self.env.copy()
        _, reward, done, _ = new_env.step(move)
        child_node = MCTSNode(new_env, self, move)
        self.children.append(child_node)
        return child_node
    
    def update(self, result):
        """Update node statistics"""
        self.visits += 1
        self.wins += result
    
    def is_fully_expanded(self):
        return len(self.untried_moves) == 0
    
    def is_terminal(self):
        return self.env.done

class MCTSAI:
    def __init__(self, iteration_limit=2000):
        self.iteration_limit = iteration_limit
    
    def get_move(self, env):
        root = MCTSNode(env)
        
        for _ in range(self.iteration_limit):
            node = root
            
            # Selection
            while node.is_fully_expanded() and not node.is_terminal():
                child = node.select_child()
                if child is None:
                    break
                node = child
            
            # Expansion
            if not node.is_terminal():
                child = node.expand()
                if child is not None:
                    node = child
            
            # Simulation
            temp_env = node.env.copy()
            while not temp_env.done:
                possible_moves = node._generate_combinations()
                if not possible_moves:
                    break
                move = random.choice(possible_moves)
                _, _, done, _ = temp_env.step(move)
                if done: 
                    break
            
            # Backpropagation
            result = 1 if temp_env.current_player() != env.current_player() else 0
            while node is not None:
                node.update(result)
                node = node.parent
        
        if not root.children:
            return (0, 0)
        
        # Choose the move with highest visits, preferring single-card moves
        best_child = max(root.children, 
                        key=lambda child: (child.visits, child.is_single_card_move))
        return best_child.move

class Red7Game:
    def __init__(self):
        self.env = Red7Env(verbose=False)
        self.ai = MCTSAI(iteration_limit=1000)
    
    def print_state(self):
        """Print the current game state"""
        print("\n" + "="*40)
        print(f"Current Rule: {self.env.COLOR_NAMES[self.env.rule]}")
        print(f"Current Player: {'AI' if self.env.current_player() == 0 else 'You'}")
        
        print("\nAI Palette:", self.env._cards_to_str(self.env.get_palette(0)))
        print("Your Palette:", self.env._cards_to_str(self.env.get_palette(1)))
        
        print("\nYour Hand:", self.env._cards_to_str(self.env.get_hand(1)))
        print("\nAI Hand:", self.env._cards_to_str(self.env.get_hand(0)))
    
    def ai_turn(self):
        print("\nAI is thinking...")
        start_time = time.time()
        move = self.ai.get_move(self.env)
        end_time = time.time()
        print(f"AI thought for {end_time - start_time:.2f} seconds")
        
        if move == (0, 0):
            print("AI has no valid moves and must pass")
            return move
            
        play_card, rule_card = move
        if rule_card != 0:
            print(f"AI changes rule to {self.env.COLOR_NAMES[card_color(rule_card)]}")
        if play_card != 0:
            print(f"AI plays {self.env._color_str(play_card)}")
        
        return move
    
    def human_turn(self):
        self.print_state()
        
        while True:
            print("\nPossible moves:")
            moves = MCTSNode(self.env)._generate_combinations()
            
            if not moves:
                print("No cards left in your hand - you lose automatically!")
                return (0, 0)
            
            for i, move in enumerate(moves):
                play_card, rule_card = move
                move_desc = []
                if rule_card != 0:
                    move_desc.append(f"Change rule to {self.env.COLOR_NAMES[card_color(rule_card)]} ({self.env._color_str(rule_card)})")
                if play_card != 0:
                    move_desc.append(f"Play {self.env._color_str(play_card)}")
                print(f"{i+1}: {' + '.join(move_desc) if move_desc else 'Pass'}")

            try:
                choice = int(input("\nEnter your move number: ")) - 1
                if 0 <= choice < len(moves):
                    return moves[choice]
                print("Invalid choice. Please try again.")
            except ValueError:
                print("Please enter a number.")

    def play(self):
        print("Welcome to Red7! You're playing against the AI.")
        
        while not self.env.done:
            if self.env.current_player() == 0:  # AI's turn
                move = self.ai_turn()
            else:  # human's turn
                move = self.human_turn()
            
            _, reward, done, _ = self.env.step(move)
            
            # Checking if game ended due to empty hand
            if done:
                winner = self.env.get_winner()
                print(f"\nGame over! {'AI' if winner == 0 else 'You'} won!")
                self.print_state()
                return

if __name__ == "__main__":
    game = Red7Game()
    game.play()
import torch
import numpy as np
import random
from copy import deepcopy
"""
    MCTS tree node with GPU support for the Red7 game environment.
    
    Attributes:
        device (str): Computation device ('cuda'/'cpu')
        env_data (dict): Game state in GPU tensors
        parent (MCTSNodeGPU): Parent node reference
        action (tuple): Action that led to this node
        children (list): Child nodes
        visits (Tensor): Visit count
        value (Tensor): Accumulated value
        untried_actions (list): Unexplored actions
        is_terminal (bool): Terminal state flag
    
    Methods:
        __init__: Initializes the node with game state
        _convert_to_gpu: Converts data to GPU tensors
        is_fully_expanded: Checks if node is fully expanded
        select_child: Selects child using UCT formula
    """
class MCTSNodeGPU:
    """
        Initialize MCTS node.
        
        Args:
            env_data (dict): Game state dictionary
            parent (MCTSNodeGPU): Parent node reference
            action (tuple): Action tuple (card_to_palette, card_to_rule)
            device (str): Computation device
        """
    def __init__(self, env_data, parent=None, action=None, device='cuda'):
        self.device = device
        self.env_data = self._convert_to_gpu(env_data)
        self.parent = parent
        self.action = action
        self.children = []
        self.visits = torch.tensor(0, device=device)
        self.value = torch.tensor(0.0, device=device)
        self.untried_actions = None
        self.is_terminal = False
    """
        Convert numpy data to GPU tensors.
        
        Args:
            data (dict): Dictionary with numpy arrays/scalars
            
        Returns:
            dict: Dictionary with PyTorch GPU tensors
        """
    def _convert_to_gpu(self, data):
        gpu_data = {}
        for key, val in data.items():
            if isinstance(val, np.ndarray):
                gpu_data[key] = torch.from_numpy(val).float().to(self.device)
            else:
                gpu_data[key] = torch.tensor(val, device=self.device)
        return gpu_data
    """
        Check if node has no unexplored actions.
        
        Returns:
            bool: True if all actions explored
        """
    def is_fully_expanded(self):
        return len(self.untried_actions) == 0 if self.untried_actions is not None else False
    """
        Select child node using UCT (Upper Confidence Bound).
        
        Args:
            exploration (float): Exploration coefficient
            
        Returns:
            MCTSNodeGPU: Selected child node
        """
    def select_child(self, exploration=1.4):
        visits = torch.tensor([c.visits for c in self.children], device=self.device)
        values = torch.tensor([c.value for c in self.children], device=self.device)
        uct = values/(visits+1e-6) + exploration*torch.sqrt(torch.log(self.visits+1)/(visits+1e-6))
        return self.children[torch.argmax(uct).item()]


"""
    Monte Carlo Tree Search agent for Red7 game.
    
    Attributes:
        iterations (int): Number of MCTS iterations
        device (str): Computation device ('cuda'/'cpu')
    
    Methods:
        __init__: Initializes the agent
        get_action: Selects best action for current state
        _expand: Expands the search tree
        _apply_action: Applies action to game state
        _simulate: Performs game simulation (rollout)
        _select_best_action: Selects most visited action
    """
class MCTSAgent:
    """
        Initialize MCTS agent.
        
        Args:
            iterations (int): Number of search iterations
            device (str): Computation device
        """
    def __init__(self, iterations=1000, device='cuda'):
        self.iterations = iterations
        self.device = device
    """
        Select optimal action for current game state.
        
        Args:
            env_cpu (Red7Env): Game environment on CPU
            
        Returns:
            tuple: Optimal action (card_to_palette, card_to_rule)
        """
    def get_action(self, env_cpu):
        # 1. Подготовка данных CPU -> GPU
        env_data = {
            'player_hand': np.array(env_cpu.player1_hand if env_cpu.current_player() == 0 else env_cpu.player2_hand),
            'legal_actions': env_cpu.legal_actions_mask(),
            'done': env_cpu.done,
            'current_player': env_cpu.current_player(),
            'rule': env_cpu.rule
        }
        
        # 2. Запуск MCTS на GPU
        root = MCTSNodeGPU(env_data, device=self.device)
        for _ in range(self.iterations):
            node = root
            current_data = deepcopy(root.env_data)
            
            # Selection
            while node.is_fully_expanded() and not current_data['done']:
                node = node.select_child()
                current_data = self._apply_action(current_data, node.action)
            
            # Expansion
            if not current_data['done'] and not node.is_fully_expanded():
                node = self._expand(node, current_data)
            
            # Simulation
            reward = self._simulate(current_data)
            
            # Backpropagation
            while node is not None:
                node.visits += 1
                node.value += reward
                node = node.parent
                reward = -reward
        
        # 3. Возвращаем лучший action (автоматическая конвертация в CPU)
        return self._select_best_action(root).action
    """
        Expand tree by adding new node.
        
        Args:
            node (MCTSNodeGPU): Current node
            env_data (dict): Game state data
            
        Returns:
            MCTSNodeGPU: New child node
        """
    def _expand(self, node, env_data):
        if node.untried_actions is None:
            legal_actions = env_data['legal_actions'].cpu().numpy() if torch.is_tensor(env_data['legal_actions']) else env_data['legal_actions']
            node.untried_actions = list(zip(*np.where(legal_actions > 0)))

        if not node.untried_actions:
            return None
        
        action = node.untried_actions.pop()
        new_data = self._apply_action(deepcopy(env_data), action)
        child = MCTSNodeGPU(new_data, node, action, self.device)
        node.children.append(child)
        return child
    """
        Apply action to game state.
        
        Args:
            env_data (dict): Current game state
            action (tuple): Action to apply
            
        Returns:
            dict: Updated game state
        """
    def _apply_action(self, env_data, action):
        play_card, rule_card = action
        hand = env_data['player_hand']
        
        if isinstance(hand, torch.Tensor):
            hand = hand.cpu().numpy()
        
        new_hand = []
        played = False
        ruled = False
        
        for card in hand:
            if not played and play_card > 0 and card == play_card:
                played = True
                continue
            if not ruled and rule_card > 0 and card == rule_card and (play_card != rule_card or play_card == 0):
                ruled = True
                continue
            new_hand.append(card)
            
        env_data['player_hand'] = np.array(new_hand)
        
        if rule_card > 0 and (rule_card in hand or rule_card == 0):
            env_data['rule'] = (rule_card - 1) // 7
            
        return env_data
    """
        Simulate game from current state (rollout).
        
        Args:
            env_data (dict): Current game state
            
        Returns:
            Tensor: Simulation result (-1 to 1)
        """
    def _simulate(self, env_data):
        return torch.tensor(random.uniform(-1, 1), device=self.device)
    """
        Select action with highest visit count.
        
        Args:
            node (MCTSNodeGPU): Root node
            
        Returns:
            MCTSNodeGPU: Node with best action
        """
    def _select_best_action(self, node):
        if not node.children:
            return node
        visits = [c.visits.item() for c in node.children]
        return node.children[np.argmax(visits)]
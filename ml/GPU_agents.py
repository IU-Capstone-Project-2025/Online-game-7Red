import torch
import numpy as np
import random
from copy import deepcopy

class MCTSNodeGPU:
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

    def _convert_to_gpu(self, data):
        """Конвертирует CPU-данные в GPU-тензоры"""
        gpu_data = {}
        for key, val in data.items():
            if isinstance(val, np.ndarray):
                gpu_data[key] = torch.from_numpy(val).float().to(self.device)
            else:
                gpu_data[key] = torch.tensor(val, device=self.device)
        return gpu_data

    def is_fully_expanded(self):
        return len(self.untried_actions) == 0 if self.untried_actions is not None else False

    def select_child(self, exploration=1.4):
        visits = torch.tensor([c.visits for c in self.children], device=self.device)
        values = torch.tensor([c.value for c in self.children], device=self.device)
        uct = values/(visits+1e-6) + exploration*torch.sqrt(torch.log(self.visits+1)/(visits+1e-6))
        return self.children[torch.argmax(uct).item()]

class MCTSAgent:
    def __init__(self, iterations=1000, device='cuda'):
        self.iterations = iterations
        self.device = device
    
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

    def _expand(self, node, env_data):
        if node.untried_actions is None:
            # Исправление: переносим тензор на CPU перед np.where
            legal_actions = env_data['legal_actions'].cpu().numpy() if torch.is_tensor(env_data['legal_actions']) else env_data['legal_actions']
            node.untried_actions = list(zip(*np.where(legal_actions > 0)))

        if not node.untried_actions:
            return None
        
        action = node.untried_actions.pop()
        new_data = self._apply_action(deepcopy(env_data), action)
        child = MCTSNodeGPU(new_data, node, action, self.device)
        node.children.append(child)
        return child

    def _apply_action(self, env_data, action):
        """Обновляем состояние после действия"""
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

    def _simulate(self, env_data):
        """Упрощенная симуляция игры"""
        return torch.tensor(random.uniform(-1, 1), device=self.device)

    def _select_best_action(self, node):
        if not node.children:
            return node
        visits = [c.visits.item() for c in node.children]
        return node.children[np.argmax(visits)]
#Not use in final version
import os
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import random
import numpy as np
import matplotlib.pyplot as plt
from collections import deque
from environment import Red7Env, get_winning_moves

# Create directory for model persistence if it doesn't exist
os.makedirs('persistent_volume', exist_ok=True)
"""
    Deep Q-Network model for Red7 game with card embeddings and state processing.
    
    Attributes:
        embed (nn.Embedding): Card embedding layer (card_id -> vector)
        hand_fc (nn.Linear): Hand cards processing layer
        my_palette_fc (nn.Linear): Player palette processing layer  
        opp_palette_fc (nn.Linear): Opponent palette processing layer
        rule_fc (nn.Linear): Current rule processing layer
        numeric_fc (nn.Linear): Numeric features processing layer
        deck_fc (nn.Linear): Deck state processing layer
        fc1, fc2 (nn.Linear): Hidden layers
        fc_out (nn.Linear): Output layer for Q-values
    
    Methods:
        __init__: Initializes network architecture
        forward: Processes game state into Q-values
    """
class SafeDQNModel(nn.Module):
    """Neural network for Red7 DQN with card embeddings and game state processing"""
    def __init__(self, card_vocab_size=51, embed_dim=64, hidden_dim=128, max_hand_size=7):
        """Initializes embedding layers and fully connected networks"""
        super().__init__()
        self.embed = nn.Embedding(card_vocab_size, embed_dim, padding_idx=0)
        
        self.hand_fc = nn.Linear(embed_dim * max_hand_size, hidden_dim)
        self.my_palette_fc = nn.Linear(embed_dim * max_hand_size, hidden_dim)
        self.opp_palette_fc = nn.Linear(embed_dim * max_hand_size, hidden_dim)
        self.rule_fc = nn.Linear(embed_dim, hidden_dim)
        self.numeric_fc = nn.Linear(6, hidden_dim)
        self.deck_fc = nn.Linear(49, hidden_dim)

        self.fc1 = nn.Linear(hidden_dim * 6, hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, 256)
        self.fc_out = nn.Linear(256, 50 * 50)

    def forward(self, obs):
        """Processes game state into Q-values for all possible actions"""
        hand_emb = self.embed(obs['hand'])
        my_pal_emb = self.embed(obs['my_palette'])
        opp_pal_emb = self.embed(obs['opp_palette'])
        rule_emb = self.embed(obs['rule'].squeeze(-1))

        hand_flat = hand_emb.reshape(hand_emb.shape[0], -1)
        my_pal_flat = my_pal_emb.reshape(my_pal_emb.shape[0], -1)
        opp_pal_flat = opp_pal_emb.reshape(opp_pal_emb.shape[0], -1)

        h_hand = F.relu(self.hand_fc(hand_flat))
        h_my_palette = F.relu(self.my_palette_fc(my_pal_flat))
        h_opp_palette = F.relu(self.opp_palette_fc(opp_pal_flat))
        h_rule = F.relu(self.rule_fc(rule_emb))

        numeric_feats = torch.cat([
            obs['hand_len'], obs['my_palette_len'],
            obs['opp_hand_len'], obs['opp_palette_len'],
            torch.sum(obs['known_deck'], dim=1, keepdim=True),
            (obs['hand'] > 0).sum(dim=1, keepdim=True).float(),
        ], dim=1).float()

        h_numeric = F.relu(self.numeric_fc(numeric_feats))
        h_deck = F.relu(self.deck_fc(obs['known_deck']))

        h = torch.cat([h_hand, h_my_palette, h_opp_palette, h_rule, h_numeric, h_deck], dim=1)
        h = F.relu(self.fc1(h))
        h = F.relu(self.fc2(h))
        q_values = self.fc_out(h)
        return q_values.reshape(-1, 50, 50)

"""
    Deep Q-Learning agent with experience replay and target network.
    
    Attributes:
        model (SafeDQNModel): Online Q-network
        target_model (SafeDQNModel): Target Q-network  
        optimizer (optim.Adam): Model optimizer
        memory (deque): Experience replay buffer
        device (str): Computation device
        epsilon (float): Exploration rate
        gamma (float): Discount factor
        tau (float): Target network update rate
    
    Methods:
        select_action: Epsilon-greedy action selection
        store_transition: Stores experience in replay buffer  
        update: Performs Q-learning update
        soft_update_target: Updates target network
               save/load: Model persistence
    """
class DQNAgent:
    """Deep Q-Learning agent with experience replay and target network"""
    def __init__(self, model=None, device='cpu'):
        """Initializes agent with models, optimizer and hyperparameters"""
        self.device = device
        self.model = model.to(device) if model else SafeDQNModel().to(device)
        self.target_model = SafeDQNModel().to(device)
        self.target_model.load_state_dict(self.model.state_dict())
        self.optimizer = optim.Adam(self.model.parameters(), lr=1e-3)
        self.memory = deque(maxlen=100000)
        self.batch_size = 256
        self.gamma = 0.995
        self.epsilon = 1.0
        self.epsilon_min = 0.01
        self.epsilon_decay = 0.99995
        self.steps_done = 0
        self.tau = 0.005

    def select_action(self, obs, legal_mask):
        """Selects action using epsilon-greedy policy with legal moves"""
        self.steps_done += 1
        if random.random() < self.epsilon:
            legal_positions = np.argwhere(legal_mask > 0)
            return tuple(random.choice(legal_positions))

        self.model.eval()
        with torch.no_grad():
            obs_device = {k: v.to(self.device) for k, v in obs.items()}
            q_values = self.model(obs_device)[0].cpu().numpy()
        q_values[legal_mask == 0] = -np.inf
        return np.unravel_index(np.argmax(q_values), q_values.shape)

    def store_transition(self, obs, action, reward, next_obs, done, legal_mask):
        """Stores experience in replay memory buffer"""
        self.memory.append((obs, action, reward, next_obs, done, legal_mask))

    def update(self):
        """Performs DQN update using random batch from memory"""
        if len(self.memory) < self.batch_size:
            return

        batch = random.sample(self.memory, self.batch_size)
        obs_batch, action_batch, reward_batch, next_obs_batch, done_batch, legal_mask_batch = zip(*batch)

        def stack_obs(obs_list, key):
            return torch.cat([o[key] for o in obs_list], dim=0).to(self.device)

        obs_t = {key: stack_obs(obs_batch, key) for key in obs_batch[0].keys()}
        next_obs_t = {key: stack_obs(next_obs_batch, key) for key in next_obs_batch[0].keys()}

        actions_t = torch.tensor(action_batch, dtype=torch.long, device=self.device)
        rewards_t = torch.tensor(reward_batch, dtype=torch.float32, device=self.device)
        done_t = torch.tensor(done_batch, dtype=torch.float32, device=self.device)
        legal_mask_t = torch.tensor(np.array(legal_mask_batch), dtype=torch.float32, device=self.device)

        self.model.train()
        q_values = self.model(obs_t)
        q_value = q_values[range(self.batch_size), actions_t[:, 0], actions_t[:, 1]]

        with torch.no_grad():
            next_q_values = self.target_model(next_obs_t)
            next_q_values[legal_mask_t == 0] = -float('inf')
            next_q_value = next_q_values.view(self.batch_size, -1).max(dim=1)[0]

        expected_q_value = rewards_t + self.gamma * next_q_value * (1 - done_t)
        loss = F.mse_loss(q_value, expected_q_value)

        self.optimizer.zero_grad()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(self.model.parameters(), 1.0)
        self.optimizer.step()

        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    def soft_update_target(self):
        """Soft updates target network weights using Polyak averaging"""
        for target_param, param in zip(self.target_model.parameters(), self.model.parameters()):
            target_param.data.copy_(self.tau * param.data + (1.0 - self.tau) * target_param.data)

    def save(self, filename):
        """Saves model checkpoint to file"""
        path = os.path.join('persistent_volume', filename)
        torch.save({
            'model_state': self.model.state_dict(),
            'target_state': self.target_model.state_dict(),
            'optimizer_state': self.optimizer.state_dict(),
            'epsilon': self.epsilon
        }, path)

    def load(self, filename):
        """Loads model checkpoint from file"""
        path = os.path.join('persistent_volume', filename)
        checkpoint = torch.load(path)
        self.model.load_state_dict(checkpoint['model_state'])
        self.target_model.load_state_dict(checkpoint['target_state'])
        self.optimizer.load_state_dict(checkpoint['optimizer_state'])
        self.epsilon = checkpoint.get('epsilon', self.epsilon)

"""
    Trains agent against specified opponent type.
    
    Args:
        env (Red7Env): Game environment
        agent (DQNAgent): Learning agent
        opponent (DQNAgent): Optional opponent agent
        num_episodes (int): Training episodes
        mode (str): Training mode ('random', 'self', 'self_frozen')
        phase_name (str): Phase identifier
        
    Returns:
        list: Win history (1=agent win, 0=loss)
    """
def train_phase(env, agent, opponent=None, num_episodes=10000, mode='random', phase_name="Phase"):
    """Trains agent against specified opponent type"""
    win_history = []
    
    for episode in range(num_episodes):
        obs = env.reset()
        done = False
        episode_rewards = {0: 0, 1: 0}

        while not done:
            current_player = env.current_player()
            legal_mask = env.legal_actions_mask()

            if mode == 'random' and current_player == 1:
                rule_card = env.rule
                hand = env.player2_hand
                my_palette = env.player2_palette
                opp_palette = env.player1_palette
                winning_moves = get_winning_moves(rule_card, hand, my_palette, [opp_palette])

                if winning_moves:
                    move = random.choice(winning_moves)
                    env.apply_move(current_player, move)
                else:
                    env.done = True
                    break
            else:
                active_agent = agent if current_player == 0 else opponent
                action = active_agent.select_action(obs, legal_mask)
                next_obs, _, done, _ = env.step(action)
                
                step_reward = 0.1
                if done:
                    step_reward = 10.0 if env.get_winner() == current_player else -10.0
                
                active_agent.store_transition(obs, action, step_reward, next_obs, done, legal_mask)
                episode_rewards[current_player] += step_reward
                obs = next_obs

        agent.update()
        agent.soft_update_target()
        
        if opponent is not None and mode in ['self', 'self_frozen']:
            opponent.update()
            opponent.soft_update_target()

        win_history.append(int(env.get_winner() == 0))

        if (episode + 1) % 1000 == 0:
            win_rate = np.mean(win_history[-1000:]) * 100
            agent.save(f"{phase_name}_ep{episode+1}_win{win_rate:.1f}.pth")
    
    return win_history

"""
    Evaluates agent performance with verbose output.
    
    Args:
        env (Red7Env): Game environment
        agent (DQNAgent): Agent to evaluate
        num_games (int): Number of evaluation games
    """
def evaluate(env, agent, num_games=10):
    """Evaluates agent performance with verbose output"""
    print("\n=== Final Evaluation ===")
    agent.epsilon = 0.01
    
    for game in range(num_games):
        obs = env.reset()
        done = False
        print(f"\nGame {game + 1}:")
        
        while not done:
            env.render()
            current_player = env.current_player()
            legal_mask = env.legal_actions_mask()
            
            if current_player == 0:
                action = agent.select_action(obs, legal_mask)
                print(f"Agent plays: {action}")
            else:
                action = agent.select_action(obs, legal_mask)
                print(f"Opponent plays: {action}")
                
            obs, _, done, _ = env.step(action)
        
        winner = env.get_winner()
        print(f"Game finished! Winner: {'Agent' if winner == 0 else 'Opponent'}")

"""
    Plots training results with moving average.
    
    Args:
        win_history (list): Win/loss history
        title (str): Plot title
    """
def plot_results(win_history, title):
    """Plots training results with moving average"""
    plt.figure(figsize=(12, 6))
    smoothed = np.convolve(win_history, np.ones(500)/500, mode='valid')
    plt.plot(smoothed)
    plt.title(f"{title} (500-episode moving avg)")
    plt.xlabel("Episode")
    plt.ylabel("Win Rate")
    plt.grid()
    plt.show()


if __name__ == "__main__":
    env = Red7Env()
    device = 'cuda'
    
    # Phase 1: Training against random bot
    print("=== Phase 1: Training vs Random Bot ===")
    agent = DQNAgent(device=device)
    phase1_wins = train_phase(env, agent, num_episodes=60000, mode='random', phase_name="phase1_random")
    agent.save("phase1_final.pth")
    plot_results(phase1_wins, "Phase 1: vs Random Bot")

    # Phase 2: Training against frozen Phase 1 agent
    print("\n=== Phase 2: Self-play vs Frozen Phase 1 ===")
    frozen_phase1 = DQNAgent(device=device)
    frozen_phase1.load("phase1_final.pth")
    frozen_phase1.epsilon = 0.01
    
    phase2_wins = train_phase(env, agent, frozen_phase1, num_episodes=20000, 
                            mode='self_frozen', phase_name="phase2_vs_frozen1")
    agent.save("phase2_final.pth")
    plot_results(phase2_wins, "Phase 2: vs Frozen Phase 1")

    # Phase 3: Training against frozen Phase 2 agent
    print("\n=== Phase 3: Self-play vs Frozen Phase 2 ===")
    frozen_phase2 = DQNAgent(device=device)
    frozen_phase2.load("phase2_final.pth")
    frozen_phase2.epsilon = 0.01
    
    phase3_wins = train_phase(env, agent, frozen_phase2, num_episodes=20000, 
                            mode='self_frozen', phase_name="phase3_vs_frozen2")
    agent.save("phase3_final.pth")
    plot_results(phase3_wins, "Phase 3: vs Frozen Phase 2")

    # Phase 4: Mixed training against all opponents
    print("\n=== Phase 4: Mixed Training ===")
    opponents = [
        ('random', None),
        ('self_frozen', frozen_phase1),
        ('self_frozen', frozen_phase2)
    ]
    phase4_wins = []
    
    for ep in range(30000):
        mode, opponent = random.choice(opponents)
        wins = train_phase(env, agent, opponent, num_episodes=1, mode=mode)
        phase4_wins.extend(wins)
        
        if (ep + 1) % 5000 == 0:
            agent.save(f"phase4_interim_{ep+1}.pth")
    
    agent.save("phase4_final.pth")
    plot_results(phase4_wins, "Phase 4: Mixed Training")

    # Phase 5: Intensive self-play
    print("\n=== Phase 5: Hardcore Self-play ===")
    phase5_wins = train_phase(env, agent, agent, num_episodes=30000, 
                            mode='self', phase_name="phase5_selfplay")
    agent.save("phase5_final.pth")
    plot_results(phase5_wins, "Phase 5: Self-play")

    # Phase 6: Final tuning against all opponents
    print("\n=== Phase 6: Final Tuning ===")
    final_opponents = [
        ('random', None),
        ('self_frozen', frozen_phase1),
        ('self_frozen', frozen_phase2),
        ('self', agent)
    ]
    phase6_wins = []
    
    for ep in range(15000):
        mode, opponent = random.choice(final_opponents)
        wins = train_phase(env, agent, opponent, num_episodes=1, mode=mode)
        phase6_wins.extend(wins)
        
        if (ep + 1) % 2500 == 0:
            agent.save(f"phase6_interim_{ep+1}.pth")
    
    agent.save("final_agent.pth")
    plot_results(phase6_wins, "Phase 6: Final Tuning")

    # Final evaluation
    evaluate(env, agent)
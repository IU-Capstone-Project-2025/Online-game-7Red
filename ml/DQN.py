import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import random
import numpy as np
import matplotlib.pyplot as plt
from collections import deque
from enviroment import Red7Env, get_winning_moves


class SafeDQNModel(nn.Module):
    def __init__(self, card_vocab_size=51, embed_dim=64, hidden_dim=128, max_hand_size=7):
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

    def forward(self, obs, legal_mask=None):
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


class DQNAgent:
    def __init__(self, model=None, device='cuda' if torch.cuda.is_available() else 'cpu'):
        self.device = device
        self.model = model.to(device) if model else SafeDQNModel().to(device)
        self.target_model = SafeDQNModel().to(device)
        self.target_model.load_state_dict(self.model.state_dict())
        self.optimizer = optim.AdamW(self.model.parameters(), lr=3e-4, weight_decay=1e-5)
        self.memory = deque(maxlen=200000)
        self.batch_size = 256
        self.gamma = 0.9
        self.epsilon = 1
        self.epsilon_min = 0.05
        self.epsilon_decay = 0.999
        self.steps_done = 0
        self.target_update = 75
        self.warmup_steps = 1500

    def select_action(self, obs, legal_mask):
        self.steps_done += 1
        if random.random() < self.epsilon:
            legal_positions = np.argwhere(legal_mask > 0)
            return tuple(random.choice(legal_positions))

        self.model.eval()
        with torch.no_grad():
            obs_device = {k: v.to(self.device) for k, v in obs.items()}
            q_values = self.model(obs_device)[0].cpu().numpy()
        q_values[legal_mask == 0] = -np.inf
        if np.sum(legal_mask) == 0:
            return (0, 0)
        return np.unravel_index(np.argmax(q_values), q_values.shape)

    def store_transition(self, obs, action, reward, next_obs, done, legal_mask):
        self.memory.append((obs, action, reward, next_obs, done, legal_mask))

    def update(self):
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
            # Double DQN модификация:
            # 1. Выбираем действие через online-сеть с учетом легал маски
            next_q_values_online = self.model(next_obs_t)
            next_q_values_online[legal_mask_t == 0] = -float('inf')  # Маскируем нелегальные действия
            
            # Находим лучшее легальное действие
            best_actions = next_q_values_online.view(self.batch_size, -1).argmax(dim=1)
            
            # 2. Оцениваем выбранное действие через target-сеть
            next_q_values_target = self.target_model(next_obs_t)
            next_q_value = next_q_values_target.view(self.batch_size, -1).gather(1, best_actions.unsqueeze(1)).squeeze(1)

        expected_q_value = rewards_t + self.gamma * next_q_value * (1 - done_t)
        loss = F.mse_loss(q_value, expected_q_value)

        self.optimizer.zero_grad()
        loss.backward()
        
        # Gradient clipping для стабильности обучения
        torch.nn.utils.clip_grad_norm_(self.model.parameters(), 10.0)
        
        self.optimizer.step()

        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    def update_target(self):
        self.target_model.load_state_dict(self.model.state_dict())

    def save(self, path):
    # Сохраняем полное состояние агента
        torch.save({
            'model_state_dict': self.model.state_dict(),
            'target_state_dict': self.target_model.state_dict(),
            'optimizer_state_dict': self.optimizer.state_dict(),
            'epsilon': 0,
            'steps_done': self.steps_done
        }, path)

    def load(self, path):
        try:
            checkpoint = torch.load(path, map_location=self.device)
            # Проверяем наличие всех необходимых ключей
            required_keys = ['model_state_dict', 'target_state_dict', 'optimizer_state_dict']
            if not all(key in checkpoint for key in required_keys):
                raise ValueError("Checkpoint file is missing required keys")
                
            self.model.load_state_dict(checkpoint['model_state_dict'])
            self.target_model.load_state_dict(checkpoint['target_state_dict'])
            self.optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
            self.epsilon = checkpoint.get('epsilon', 1.0)
            self.steps_done = checkpoint.get('steps_done', 0)
        
            # Обновляем target модель
            self.update_target()
        except Exception as e:
            print(f"Error loading model: {e}")
            # Инициализируем модель с нуля при ошибке загрузки
            self.model = SafeDQNModel().to(self.device)
            self.target_model = SafeDQNModel().to(self.device)
            self.optimizer = optim.Adam(self.model.parameters(), lr=1e-2)



def train(env, agent_0, agent_1=None, num_episodes=5000, mode='random'):
    win_history = []

    for episode in range(num_episodes):
        obs = env.reset()
        done = False

        episode_memory_0 = []
        episode_memory_1 = []

        while not done:
            current_player = env.current_player()
            legal_mask = env.legal_actions_mask()

            if mode == 'random' and current_player == 1:
                # Random opponent logic
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
                    print("Random lose")
                    for obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_0:
                        agent_0.store_transition(obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem)
                    agent_0.update()
                    break

            else:
                # Self-play or vs fixed opponent
                if mode == 'self':
                    agent = agent_0
                elif mode == 'self_frozen':
                    agent = agent_0 if current_player == 0 else agent_1
                else:
                    agent = agent_0 if current_player == 0 else agent_1

                if agent is None:
                    break

                action = agent.select_action(obs, legal_mask)
                next_obs, _, done, _ = env.step(action)

                # Reward за каждый шаг (живой)
                step_reward = 0  # выжил = +0.1
                if done:
                    step_reward = -10.0 if env.get_winner() != current_player else 10.0

                if current_player == 0:
                    episode_memory_0.append((obs, action, step_reward, next_obs, done, legal_mask))
                else:
                    episode_memory_1.append((obs, action, step_reward, next_obs, done, legal_mask))

                obs = next_obs

        # Финальная запись опыта
        for obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_0:
            agent_0.store_transition(obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem)
        agent_0.update()
        agent_0.update_target()

        if mode == 'self' and agent_1 is not None:
            for obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_1:
                agent_1.store_transition(obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem)
            agent_1.update()
            agent_1.update_target()

        win = int(env.get_winner() == 0)
        win_history.append(win)

        if (episode+1) % 100 == 0:
            win_rate = np.mean(win_history[-100:]) * 100
            print(f"[Episode {episode}] Mode: {mode}, Win Rate (last 100): {win_rate:.2f}%, Epsilon: {agent_0.epsilon:.3f}")

    return win_history


def train_print(env, agent_0, agent_1=None, num_episodes=5000, mode='random'):
    win_history = []

    for episode in range(num_episodes):
        obs = env.reset()
        done = False

        episode_memory_0 = []
        episode_memory_1 = []

        print(f"Episode {episode} starting:")
        print("Player 0 hand:", obs['hand'][0].cpu().numpy() if torch.is_tensor(obs['hand']) else obs['hand'][0])
        print("Player 0 palette:", obs['my_palette'][0].cpu().numpy() if torch.is_tensor(obs['my_palette']) else obs['my_palette'][0])
        print("Player 1 palette:", obs['opp_palette'][0].cpu().numpy() if torch.is_tensor(obs['opp_palette']) else obs['opp_palette'][0])
        print("Current rule:", obs['rule'][0].cpu().numpy() if torch.is_tensor(obs['rule']) else obs['rule'][0])
        print('-' * 40)

        while not done:
            current_player = env.current_player()
            legal_mask = env.legal_actions_mask()

            if mode == 'random' and current_player == 1:
                # Случайный противник
                rule_card = env.rule
                hand = env.player2_hand
                my_palette = env.player2_palette
                opp_palette = env.player1_palette
                winning_moves = get_winning_moves(rule_card, hand, my_palette, [opp_palette])

                if winning_moves:
                    move = random.choice(winning_moves)
                    env.apply_move(current_player, move)
                    env.render()  # рендер случайного хода
                else:
                    env.done = True
                    print("Random lose")
                    final_reward = -10.0
                    for obs_mem, action_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_0:
                        agent_0.store_transition(obs_mem, action_mem, final_reward, next_obs_mem, done_mem, legal_mask_mem)
                    agent_0.update()
                    break

            else:
                # Выбираем агента в зависимости от игрока
                agent = agent_0 if current_player == 0 else agent_1

                if agent is None:
                    break

                action = agent.select_action(obs, legal_mask)
                next_obs, _, done, _ = env.step(action)
                env.render()  # рендер действия агента

                # Записываем переходы в память соответствующего агента
                if current_player == 0:
                    episode_memory_0.append((obs, action, next_obs, done, legal_mask))
                else:
                    episode_memory_1.append((obs, action, next_obs, done, legal_mask))

                obs = next_obs

        # По окончании эпизода даём награды и обновляем агентов
        winner = env.get_winner()

        final_reward_0 = 10.0 if winner == 0 else -10.0
        final_reward_1 = -final_reward_0

        for obs_mem, action_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_0:
            agent_0.store_transition(obs_mem, action_mem, final_reward_0, next_obs_mem, done_mem, legal_mask_mem)
        agent_0.update()
        agent_0.update_target()

        if agent_1 is not None:
            for obs_mem, action_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_1:
                agent_1.store_transition(obs_mem, action_mem, final_reward_1, next_obs_mem, done_mem, legal_mask_mem)
            agent_1.update()
            agent_1.update_target()

        win = int(winner == 0)
        win_history.append(win)

        if (episode+1) % 10 == 0:
            win_rate = np.mean(win_history[-10:]) * 10
            print(f"[Episode {episode}] Mode: {mode}, Win Rate (last 100): {win_rate:.2f}%, Epsilon Agent0: {agent_0.epsilon:.3f}")

    return win_history

def train_mcts(env, agent_0, agent_1=None, num_episodes=5000, mode='mcts'):
    win_history = []

    for episode in range(num_episodes):
        obs = env.reset()
        done = False

        episode_memory_0 = []
        episode_memory_1 = []

        while not done:
            current_player = env.current_player()
            legal_mask = env.legal_actions_mask()

            # Выбор агента
            if current_player == 0:
                agent = agent_0
                action = agent.select_action(obs, legal_mask)
            else:
                if mode == 'mcts' and agent_1 is not None:
                    action = agent_1.get_action(env)
                elif agent_1 is not None:
                    action = agent_1.select_action(obs, legal_mask)
                else:
                    raise ValueError("agent_1 must be provided for non-self mode")

            next_obs, _, done, _ = env.step(action)

            # Награда
            step_reward = 0  # выжил
            if done:
                step_reward = 10.0 if env.get_winner() == current_player else -10.0

            # Запись перехода
            if current_player == 0:
                episode_memory_0.append((obs, action, step_reward, next_obs, done, legal_mask))
            else:
                episode_memory_1.append((obs, action, step_reward, next_obs, done, legal_mask))

            obs = next_obs

        # Финальные записи
        for obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_0:
            agent_0.store_transition(obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem)
        agent_0.update()
        agent_0.update_target()

        if mode in ['self', 'self_frozen'] and agent_1 is not None:
            for obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem in episode_memory_1:
                agent_1.store_transition(obs_mem, action_mem, reward_mem, next_obs_mem, done_mem, legal_mask_mem)
            agent_1.update()
            agent_1.update_target()

        win = int(env.get_winner() == 0)
        win_history.append(win)

        if (episode + 1) % 100 == 0:
            win_rate = np.mean(win_history[-100:]) * 100
            print(f"[Episode {episode}] Mode: {mode}, Win Rate (last 100): {win_rate:.2f}%, Epsilon: {agent_0.epsilon:.3f}")

    return win_history


def plot_winrate(win_history, title="Win Rate"):
    win_rate_curve = np.convolve(win_history, np.ones(50)/50, mode='valid') * 100
    plt.figure(figsize=(10, 5))
    plt.plot(win_rate_curve, label=f"{title} (avg over 50 games)")
    plt.xlabel("Episode")
    plt.ylabel("Win Rate (%)")
    plt.title(title)
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.show()

def play_single_game():
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"\n=== Using device: {device} ===")
    
    env = Red7Env(verbose=True)
    agent = DQNAgent(device=device)
    
    try:
        agent.load("medium.pth")
        print("Model loaded successfully!")
    except Exception as e:
        print(f"\nError loading model: {e}")
        return
    
    def parse_card_input(card_str):
        """Конвертирует строку вида 'R3' в номер карты (1-49)"""
        if card_str == '0':
            return 0
        try:
            color = card_str[0].upper()
            value = int(card_str[1:])
            color_idx = env.COLORS.index(color)
            return color_idx * 7 + value
        except (ValueError, IndexError):
            return None

    agent.epsilon = 0.01
    obs = env.reset()
    env.render()
    
    while not env.done:
        if env.current_player() == 0:
            print("\nYour turn!")
            print("Current rule:", env.COLOR_NAMES[env.rule])
            print("Your hand:", env._cards_to_str(env.player1_hand))
            
            while True:
                try:
                    palette_input = input("Card to palette (e.g. R3 or 0 to skip): ").strip()
                    palette_card = parse_card_input(palette_input)
                    
                    rule_input = input("Card to change rule (e.g. B2 or 0 to skip): ").strip()
                    rule_card = parse_card_input(rule_input)
                    
                    if palette_card is None or rule_card is None:
                        print("Invalid format! Use format like 'R3' or '0'")
                        continue
                        
                    if (palette_card == 0 and rule_card == 0) or env.legal_actions_mask()[palette_card, rule_card] > 0:
                        break
                        
                    print("Invalid move! Check if cards are in your hand.")
                except:
                    print("Invalid input! Try again.")
            
            action = (palette_card, rule_card)
        else:
            print("\nAI thinking...")
            with torch.no_grad():
                obs_tensor = {k: v.to(device) for k, v in obs.items()}
                q_values = agent.model(obs_tensor)[0].cpu().numpy()
            
            legal_mask = env.legal_actions_mask()
            q_values[legal_mask == 0] = -np.inf
            action = np.unravel_index(np.argmax(q_values), q_values.shape)
            print(f"AI plays: {env._color_str(action[0])} to palette, {env._color_str(action[1])} as rule")
        
        obs, _, env.done, _ = env.step(action)
        env.render()
    
    print("\n=== Game Over ===")
    print("You won!" if env.get_winner() == 0 else "AI won!")

if __name__ == "__main__":
    print("=== Red7 Game vs AI ===")
    print("How to play:")
    print("1. Enter card for palette (e.g. R3, G5, B1)")
    print("2. Enter card to change rule (or 0 to keep current)")
    print("Examples:")
    print("- Play R3 to palette and keep rule: 'R3' then '0'")
    print("- Change rule to B2 without playing: '0' then 'B2'")
    print("- Concede: '0' then '0'")
    print("Available colors: R, O, Y, G, L, B, V (Red, Orange, Yellow, Green, LightBlue, Blue, Violet)\n")

    play_single_game()

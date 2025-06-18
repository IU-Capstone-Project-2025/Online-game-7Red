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

    def forward(self, obs):
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
    def __init__(self, model=None, device='cpu'):
        self.device = device
        self.model = model.to(device) if model else SafeDQNModel().to(device)
        self.target_model = SafeDQNModel().to(device)
        self.target_model.load_state_dict(self.model.state_dict())
        self.optimizer = optim.Adam(self.model.parameters(), lr=1e-4)
        self.memory = deque(maxlen=100000)
        self.batch_size = 128
        self.gamma = 0.995
        self.epsilon = 1.0
        self.epsilon_min = 0.05
        self.epsilon_decay = 0.9995
        self.steps_done = 0

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
        return np.unravel_index(np.argmax(q_values), q_values.shape)

    def store_transition(self, obs, action, reward, next_obs, done, legal_mask):
        bonus = 0.1 if reward > 0 else 0
        self.memory.append((obs, action, reward + bonus, next_obs, done, legal_mask))

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
            next_q_values = self.target_model(next_obs_t)
            next_q_values[legal_mask_t == 0] = -float('inf')
            next_q_value = next_q_values.view(self.batch_size, -1).max(dim=1)[0]

        expected_q_value = rewards_t + self.gamma * next_q_value * (1 - done_t)
        loss = F.mse_loss(q_value, expected_q_value)

        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    def update_target(self):
        self.target_model.load_state_dict(self.model.state_dict())

    def save(self, path):
        torch.save(self.model.state_dict(), path)

    def load(self, path):
        self.model.load_state_dict(torch.load(path))
        self.target_model.load_state_dict(self.model.state_dict())


def train(env, agent, num_episodes=5000, mode='random'):
    win_history = []

    for episode in range(num_episodes):
        obs = env.reset()
        done = False

        while not done:
            current_player = env.current_player()
            legal_mask = env.legal_actions_mask()

            # Выбор действия
            if mode == 'random' and current_player == 1:
                # Получаем данные игрока
                rule_card = env.rule
                if current_player == 0:
                    hand = env.player1_hand
                    my_palette = env.player1_palette
                    opp_palette = env.player2_palette
                else:
                    hand = env.player2_hand
                    my_palette = env.player2_palette
                    opp_palette = env.player1_palette

                # Вычисляем выигрышные ходы
                winning_moves = get_winning_moves(rule_card, hand, my_palette, [opp_palette])

                if winning_moves:
                    # Выбираем случайный выигрышный ход
                    move = random.choice(winning_moves)
                    env.apply_move(current_player, move)
                    env.render()
                    continue
                else:
                    env.done = True
                    print("Ai wins")
            else:
                # Обучающий агент действует
                action = agent.select_action(obs, legal_mask)

            # Совершаем шаг
            next_obs, reward, done, _ = env.step(action)
            env.render()

            # Обновление памяти и агента
            if current_player == 0:
                agent.store_transition(obs, action, reward, next_obs, done, legal_mask)
                agent.update()

            obs = next_obs

        agent.update_target()
        win = int(env.get_winner() == 0)
        win_history.append(win)

        if episode % 10 == 0:
            win_rate = np.mean(win_history[-100:]) * 100
            print(f"[Episode {episode}] Mode: {mode}, Win Rate (last 100): {win_rate:.2f}%, Epsilon: {agent.epsilon:.3f}")

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


if __name__ == "__main__":
    env = Red7Env()
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    model = SafeDQNModel()
    agent = DQNAgent(model, device=device)

    print("Training vs Random")
    rewards_random = train(env, agent, num_episodes=10, mode='random')

    print("Training Self Play")
    rewards_self_play = train(env, agent, num_episodes=0, mode='self')

    agent.save("checkpoint.pth")

    plot_winrate(rewards_random, "Agent vs Random Player")
    plot_winrate(rewards_self_play, "Agent Self-Play")

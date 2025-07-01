import torch
from DQN import DQNAgent
from enviroment import Red7Env

def validate_agent(model_path, num_games=100):
    env = Red7Env(verbose=False)
    agent = DQNAgent(device='cpu')
    agent.load(model_path)
    agent.epsilon = 0  

    wins = 0
    for _ in range(num_games):
        obs = env.reset()
        done = False
        while not done:
            legal_mask = env.legal_actions_mask()
            action = agent.select_action(obs, legal_mask)
            obs, reward, done, _ = env.step(action)
        if env.get_winner() == 0:
            wins += 1
    print(f"Win rate over {num_games} games: {wins / num_games * 100:.1f}%")

if __name__ == "__main__":
    validate_agent("ml/final_agent (4).pth", num_games=100)
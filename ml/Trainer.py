import numpy as np
import torch
import torch.optim as optim
from tqdm import tqdm
import matplotlib.pyplot as plt
from collections import deque
import random
from GPU_agents import MCTSAgent
from enviroment_legal import Red7Env
from DQN import DQNAgent, train, train_mcts
class Trainer:
    def __init__(self, env, device='cuda' if torch.cuda.is_available() else 'cpu'):
        self.env = env
        self.device = device
        self.dqn_agent = DQNAgent(device=device)
        self.mcts_agents = {
            30: MCTSAgent(iterations=30),
            100: MCTSAgent(iterations=100),
            200: MCTSAgent(iterations=200),
            300: MCTSAgent(iterations=300),
            500: MCTSAgent(iterations=500),
            800: MCTSAgent(iterations=800),
            1000: MCTSAgent(iterations=1000),
            2000: MCTSAgent(iterations=2000)
        }
        
    def train(self, total_episodes=3):
        """Основной цикл обучения"""
        if total_episodes == 3000:
            return self._micro_training()
        
        win_rates = []
        test_results = []
        
        # Функция для выполнения фазы обучения
        def run_phase(phase_name, mcts_iterations, num_episodes, test_iter, 
                    epsilon, lr, test_freq=100, save_name=None):
            print(f"\n=== {phase_name} ===")
            self.dqn_agent.epsilon = epsilon
            self.dqn_agent.optimizer = optim.AdamW(
                self.dqn_agent.model.parameters(), 
                lr=lr, 
                weight_decay=1e-5
            )
            
            phase_wins = []
            for ep in tqdm(range(num_episodes), desc=f"{phase_name} Training"):
                mcts_agent = self.mcts_agents[mcts_iterations]
                wins = train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
                phase_wins.append(wins)
                
                if (ep+1) % test_freq == 0:
                    self.dqn_agent.update_target()
                    
                    if test_iter and (ep+1) % test_iter == 0:
                        test_res = self.test_against(
                            mode='mcts', 
                            mcts_agent=self.mcts_agents[1000],
                            num_games=50
                        )
                        test_results.append((f'MCTS-1000 @{ep+1}', test_res))
                        print(f"Test vs MCTS-1000 at episode {ep+1}: {test_res['win_rate']:.1f}%")
            
            win_rates.extend(phase_wins)
            if save_name:
                self._save_model(save_name)
        
        # Фазы обучения (name, mcts_iter, episodes, test_iter, epsilon, lr, save_name)
        phases = [
            ("Phase 1: MCTS-100 Training", 100, 300, 300, 0.5, 3e-4, "red7_dqn_1.pth"),
            ("Phase 2: MCTS-500 Training", 500, 200, 200, 0.2, 3e-4, "red7_dqn_2.pth"),
            ("Phase 3: MCTS-1000 Training", 1000, 200, 200, 0.2, 3e-4, "red7_dqn_3.pth"),
        ]
        
        for phase in phases:
            run_phase(*phase)
        
        # Фаза 4: Random Opponent
        print("\n=== Phase 4: Random Opponent Training ===")
        self.dqn_agent.epsilon = 0.2
        self.dqn_agent.optimizer = optim.AdamW(
            self.dqn_agent.model.parameters(), 
            lr=1e-4, 
            weight_decay=1e-5
        )
        
        phase_wins = train(self.env, self.dqn_agent, num_episodes=5000, mode='random')
        win_rates.extend(phase_wins)
        self._save_model("red7_dqn_4.pth")
        
        # Тестирование после фазы 4
        test_res = self.test_against(mode='random', num_games=100)
        test_results.append(('Random', test_res))
        print(f"Test vs Random: {test_res['win_rate']:.1f}%")
        
        # Фаза 5: Mixed MCTS
        print("\n=== Phase 5: Mixed MCTS Training ===")
        self.dqn_agent.epsilon = 0.2
        self.dqn_agent.optimizer = optim.AdamW(
            self.dqn_agent.model.parameters(), 
            lr=1e-4, 
            weight_decay=1e-5
        )
        
        for ep in tqdm(range(300), desc="Mixed MCTS Training"):
            mcts_iter = random.choice([200, 500, 800, 1000])
            mcts_agent = self.mcts_agents[mcts_iter]
            train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
            
            if (ep+1) % 300 == 0:
                self.dqn_agent.update_target()
                
            if (ep+1) % 300 == 0:
                test_res = self.test_against(
                    mode='mcts', 
                    mcts_agent=self.mcts_agents[1000],
                    num_games=50
                )
                test_results.append((f'MCTS-1000 @{ep+1}', test_res))
                print(f"Test vs MCTS-1000 at episode {ep+1}: {test_res['win_rate']:.1f}%")
        
        self._save_model("red7_dqn_5.pth")
        
        # Финальные фазы
        print("\n=== Phase 6: Hardcore Self-play ===")
        self.dqn_agent.epsilon = 0.2
        self.dqn_agent.optimizer = optim.AdamW(
            self.dqn_agent.model.parameters(), 
            lr=2e-4, 
            weight_decay=1e-5
        )
        train(self.env, self.dqn_agent, num_episodes=5000, mode='self')
        self._save_model("phase5_final.pth")
        
        # Загрузка frozen агента
        frozen_agent = DQNAgent(device=self.device)
        frozen_agent.load("phase5_final.pth")
        frozen_agent.epsilon = 0
        
        print("\n=== Phase 7: Final Tuning ===")
        final_opponents = [
            ('random', None),
            ('MCTS 100', MCTSAgent(iterations=200)),
            ('MCTS 200', MCTSAgent(iterations=500)),
            ('MCTS 500', MCTSAgent(iterations=800)),
            ('MCTS 1000', MCTSAgent(iterations=1000)),
            ('Frozen', frozen_agent),
            ('self', self.dqn_agent)
        ]
        
        self.dqn_agent.epsilon = 0.2
        self.dqn_agent.optimizer = optim.AdamW(
            self.dqn_agent.model.parameters(), 
            lr=1e-4, 
            weight_decay=1e-5
        )
        
        for ep in range(500):
            mode, opponent = random.choice(final_opponents)
            if mode.startswith('MCTS'):
                train_mcts(self.env, self.dqn_agent, opponent, num_episodes=1)
            else:
                train(self.env, self.dqn_agent, num_episodes=1, mode=mode)
        
        self._save_model("final_agent.pth")
        
        # Финальное тестирование
        final_tests = []
        mcts_iter = 2000
        test_res = self.test_against(
            mode='mcts', 
            mcts_agent=MCTSAgent(iterations=mcts_iter), 
            num_games=50
        )
        final_tests.append((f'MCTS-{mcts_iter}', test_res))
        print(f"Final Test vs MCTS-{mcts_iter}: {test_res['win_rate']:.1f}%")
        
        return {
        'win_rates': win_rates,
        'test_results': test_results,
        'final_tests': final_tests if 'final_tests' in locals() else []
        }

    
    def _micro_training(self):
        # """Микро обучение для тестирования (3000 эпизодов)"""
        # print("\n=== Micro Training (3000 episodes) ===")
        win_rates = []
        
        # 1000 эпизодов против случайного агента
        
        for ep in range(200):
            mcts_agent = self.mcts_agents[100]
            phase_wins = train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
            win_rates.extend(phase_wins)
            if (ep+1) % 200 == 0:
                print(f"Episode {ep+1}: Training with MCTS-100, Winrate:{np.mean(win_rates[:-100]):.2f}, Epsilon: {self.dqn_agent.epsilon:.2f}")
                self.dqn_agent.update_target()
        test_res = self.test_against(mode='mcts', mcts_agent=self.mcts_agents[100], num_games=100)
        print(f"Test vs MCTS-100: {test_res['win_rate']:.1f}%")
        self.dqn_agent.save("red7_dqn_1.pth")


        self.dqn_agent.epsilon = 0.3  # Уменьшаем epsilon для более стабильного обучения
        for ep in range(200):
            mcts_agent = self.mcts_agents[300]
            phase_wins = train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
            win_rates.extend(phase_wins)
            if (ep+1) % 200 == 0:
                print(f"Episode {ep+1}: Training with MCTS-300, Winrate:{np.mean(win_rates[:-100]):.2f}, Epsilon: {self.dqn_agent.epsilon:.2f}")
                self.dqn_agent.update_target()
        test_res = self.test_against(mode='mcts', mcts_agent=self.mcts_agents[300], num_games=100)
        print(f"Final Test vs MCTS-300: {test_res['win_rate']:.1f}%")
        self.dqn_agent.save("red7_dqn_2.pth")



        self.dqn_agent.epsilon = 0.2  # Уменьшаем epsilon для более стабильного обучения
        for ep in range(100):
            mcts_agent = self.mcts_agents[1000]
            phase_wins = train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
            win_rates.extend(phase_wins)
            if (ep) % 100 == 0 and ep > 0:
                print(f"Episode {ep+1}: Training with MCTS-1000, Winrate:{np.mean(win_rates[:-100]):.2f}, Epsilon: {self.dqn_agent.epsilon:.2f}")
                self.dqn_agent.update_target()
        test_res = self.test_against(mode='mcts', mcts_agent=self.mcts_agents[1000], num_games=20)
        print(f"Final Test vs MCTS-1000: {test_res['win_rate']:.1f}%")
        self.dqn_agent.save("red7_dqn_3.pth")

        phase_wins = train(self.env, self.dqn_agent, num_episodes=1000, mode='random')
        win_rates.extend(phase_wins)
        
        test_res = self.test_against(mode='random', num_games=100)
        print(f"Test vs Random: {test_res['win_rate']:.1f}%")
        self.dqn_agent.epsilon = 0.2  # Уменьшаем начальное значение epsilon для более агрессивного обучения

        for ep in tqdm(range(100), desc="Mixed MCTS Training"):
            mcts_iter = random.choice([200, 500, 800, 1000])
            mcts_agent = self.mcts_agents[mcts_iter]
            train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
          
            if (ep+1) % 100 == 0:
                self.dqn_agent.update_target()
                
            if (ep+1) % 100 == 0:
                print(f"Final Test vs MCTS-1000: {test_res['win_rate']:.1f}%")
                test_res = self.test_against(
                    mode='mcts', 
                    mcts_agent=self.mcts_agents[1000],
                    num_games=20
                )
        self.dqn_agent.save("red7_dqn_5.pth")
        print("\n=== Phase 6: Hardcore Self-play ===")
        self.dqn_agent.epsilon = 0.3
        self.dqn_agent.optimizer = optim.AdamW(
            self.dqn_agent.model.parameters(), 
            lr=3e-4, 
            weight_decay=1e-5
        )
        train(self.env, self.dqn_agent, num_episodes=1000, mode='self')
        self.dqn_agent.save("red7_dqn_6.pth")


        self.dqn_agent.epsilon = 0.2  # Уменьшаем начальное значение epsilon для более агрессивного обучения
        print("\n===Phase 7 Mixed MCTS Training ===")
        for ep in tqdm(range(100), desc="Mixed MCTS Training"):
            mcts_iter = random.choice([200, 500, 800, 1000])
            mcts_agent = self.mcts_agents[mcts_iter]
            train_mcts(self.env, self.dqn_agent, mcts_agent, num_episodes=1)
          
            if (ep+1) % 100 == 0:
                self.dqn_agent.update_target()
                
            if (ep) % 100 == 0 and ep > 0 :
                print(f"Final Test vs MCTS-1000: {test_res['win_rate']:.1f}%")
                test_res = self.test_against(
                    mode='mcts', 
                    mcts_agent=self.mcts_agents[1000],
                    num_games=20
                )
        self.dqn_agent.save("red7_dqn_7.pth")
        print("\n===Phase 8 Frozen_train ===")
        agent = DQNAgent(device='cuda')
        agent.load("red7_dqn_7.pth")
        agent.epsilon = 0.01
        self.dqn_agent.epsilon = 0.2
        train(self.env, self.dqn_agent, agent, num_episodes=1000, mode="self_frozen")

        self.dqn_agent.save("red7_dqn_8.pth")

        frozen_agent = DQNAgent(device=self.device)
        frozen_agent.load("red7_dqn_8.pth")
        frozen_agent.epsilon = 0

        print("\n=== Phase 9: Final Tuning ===")
        final_opponents = [
            ('random', None),
            ('MCTS 200', MCTSAgent(iterations=200)),
            ('MCTS 500', MCTSAgent(iterations=500)),
            ('MCTS 800', MCTSAgent(iterations=800)),
            ('MCTS 1000', MCTSAgent(iterations=1000)),
            ('MCTS 2000', MCTSAgent(iterations=2000)),
            ('Frozen', frozen_agent),
            ('self', self.dqn_agent)
        ]
        
        self.dqn_agent.epsilon = 0.05
        self.dqn_agent.optimizer = optim.AdamW(
            self.dqn_agent.model.parameters(), 
            lr=1e-4, 
            weight_decay=1e-5
        )
        
        for ep in range(100):
            mode, opponent = random.choice(final_opponents)
            if mode.startswith('MCTS'):
                train_mcts(self.env, self.dqn_agent, opponent, num_episodes=1)
            else:
                train(self.env, self.dqn_agent, num_episodes=1, mode=mode)
        
        self.dqn_agent.save("final_agent.pth")
        


        return win_rates
    
    def _train_with_mcts(self, mcts_agent, episodes=1, mcts_ratio=0.8):
        """Один шаг обучения с MCTS агентом"""
        wins = 0
        for _ in range(episodes):
            obs = self.env.reset()
            done = False
            
            while not done:
                legal_mask = self.env.legal_actions_mask()
                
                # С вероятностью mcts_ratio используем MCTS для выбора действия
                use_mcts = random.random() < mcts_ratio
                if use_mcts:
                    action = mcts_agent.get_action(self.env)
                else:
                    action = self.dqn_agent.select_action(obs, legal_mask)
                
                next_obs, reward, done, _ = self.env.step(action)
                next_legal_mask = self.env.legal_actions_mask()
                
                self.dqn_agent.store_transition(obs, action, reward, next_obs, done, legal_mask)
                self.dqn_agent.update()
                
                obs = next_obs
                
                if done and self.env.get_winner() == 0:
                    wins += 1
        self._save_model("red7_dqn_final.pth")
        return wins / episodes if episodes > 0 else 0
    
    def test_against(self, mode='random', mcts_agent=None, num_games=100):
        """Тестирование модели против указанного оппонента"""
        self.dqn_agent.model.eval()
        results = {'wins': 0, 'losses': 0, 'draws': 0}
        
        for _ in range(num_games):
            obs = self.env.reset()
            done = False
            
            while not done:
                current_player = self.env.current_player()
                legal_mask = self.env.legal_actions_mask()
                
                if current_player == 0:  # DQN агент
                    with torch.no_grad():
                        obs_tensor = {k: v.to(self.device) for k, v in obs.items()}
                        q_values = self.dqn_agent.model(obs_tensor)[0].cpu().numpy()
                    
                    q_values[legal_mask == 0] = -np.inf
                    action = np.unravel_index(np.argmax(q_values), q_values.shape)
                else:  # Оппонент
                    if mode == 'random':
                        legal_positions = np.argwhere(legal_mask > 0)
                        action = tuple(random.choice(legal_positions))
                    elif mode == 'mcts' and mcts_agent:
                        action = mcts_agent.get_action(self.env)
                    else:
                        raise ValueError("Invalid test mode")
                
                obs, _, done, _ = self.env.step(action)
            
            winner = self.env.get_winner()
            if winner == 0:
                results['wins'] += 1
            elif winner == 1:
                results['losses'] += 1
            else:
                results['draws'] += 1
        
        results['win_rate'] = results['wins'] / num_games * 100
        return results
    
    def _save_model(self, path):
        """Сохранить модель"""
        torch.save({
            'model_state_dict': self.dqn_agent.model.state_dict(),
            'target_state_dict': self.dqn_agent.target_model.state_dict(),
            'optimizer_state_dict': self.dqn_agent.optimizer.state_dict(),
            'epsilon': self.dqn_agent.epsilon,
            'steps_done': self.dqn_agent.steps_done
        }, path)
    
    def _plot_results(self, win_rates, test_results, final_tests):
        """Визуализация результатов обучения"""
        plt.figure(figsize=(15, 10))
        
        # График win rate во время обучения
        plt.subplot(2, 2, 1)
        window = 100
        smooth_rates = np.convolve(win_rates, np.ones(window)/window, mode='valid')
        plt.plot(smooth_rates)
        plt.title('Training Win Rate (Smoothed)')
        plt.xlabel('Episodes')
        plt.ylabel('Win Rate')
        
        # График тестирования против MCTS
        plt.subplot(2, 2, 2)
        mcts_tests = [x for x in test_results if x[0].startswith('MCTS')]
        iterations = [int(x[0].split('-')[1].split()[0]) if '@' not in x[0] 
                     else int(x[0].split('-')[1].split('@')[0]) for x in mcts_tests]
        win_rates = [x[1]['win_rate'] for x in mcts_tests]
        plt.plot(iterations, win_rates, 'o-')
        plt.title('Test Performance vs MCTS')
        plt.xlabel('MCTS Iterations')
        plt.ylabel('Win Rate (%)')
        
        # Финальные тесты
        plt.subplot(2, 2, 3)
        labels = [x[0] for x in final_tests]
        values = [x[1]['win_rate'] for x in final_tests]
        plt.bar(labels, values)
        plt.title('Final Test Performance')
        plt.ylabel('Win Rate (%)')
        
        plt.tight_layout()
        plt.savefig('training_results.png')
        plt.show()

if __name__ == "__main__":
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")
    
    env = Red7Env()
    trainer = Trainer(env, device)
    #win_rates = trainer._micro_training()
    # Для полного обучения:
    #trainer.train(total_episodes=30000)
    
    # Для микро обучения (тестирование):
    win_rates = trainer.train(total_episodes=3000)

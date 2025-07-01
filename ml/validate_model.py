from DQN import DQNAgent
from enviroment import Red7Env
from mcts_cpu import MCTSAI

def test_against_mcts(model_path, mcts_iterations, num_games=100):
    env = Red7Env(verbose=False)
    dqn_agent = DQNAgent(device='cpu')
    dqn_agent.load(model_path)
    dqn_agent.epsilon = 0 
    
    mcts_agent = MCTSAI(iteration_limit=mcts_iterations)
    
    dqn_wins = 0
    mcts_wins = 0
    
    for _ in range(1, num_games + 1):
        agents = {0: mcts_agent, 1: dqn_agent}
            
        obs = env.reset()
        done = False
        
        while not done:
            current_player = env.current_player()
            agent = agents[current_player]
            
            if agent == dqn_agent:
                legal_mask = env.legal_actions_mask()
                action = dqn_agent.select_action(obs, legal_mask)
            else:
                action = mcts_agent.get_move(env)
                
            obs, reward, done, _ = env.step(action)
        
        winner = env.get_winner()
        if winner == 1:
            dqn_wins += 1
        else:
            mcts_wins += 1
    
    print("\n=== Final Results ===")
    print(f"DQN Agent vs MCTS-{mcts_iterations}")
    print(f"DQN Wins: {dqn_wins}/{num_games} ({dqn_wins/num_games*100:.1f}%)")
    print(f"MCTS Wins: {mcts_wins}/{num_games} ({mcts_wins/num_games*100:.1f}%)")
    return dqn_wins / num_games

if __name__ == "__main__":
    model_path = "ml/final_agent (4).pth"
    
    print("Testing against MCTS-500...")
    win_rate_500 = test_against_mcts(model_path, 500, num_games=100)
    
    print("\nTesting against MCTS-1000...")
    win_rate_1000 = test_against_mcts(model_path, 1000, num_games=100)
    
    print("\n=== Summary ===")
    print(f"DQN Win Rate vs MCTS-500: {win_rate_500*100:.1f}%")
    print(f"DQN Win Rate vs MCTS-1000: {win_rate_1000*100:.1f}%")
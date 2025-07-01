import torch
import numpy as np
from enviroment_legal import Red7Env  # Убедитесь, что environment.py в той же директории
from DQN import DQNAgent         # Убедитесь, что DQN.py в той же директории

def test_specific_ai_decision():
    # Инициализация
    device = torch.device('cpu')
    agent = DQNAgent(device=device)
    
    try:
        agent.load("final_agent (4).pth")  # Укажите ваш путь к модели
    except Exception as e:
        print(f"Ошибка загрузки модели: {e}")
        return
    
    env = Red7Env(verbose=False)
    
    # 1. ЗАДАЙТЕ КОНКРЕТНУЮ СИТУАЦИЮ ЗДЕСЬ:
    env.player1_hand = [8, 17, 22]    # Например: O1, Y1, G1
    env.player1_palette = []          # Палитра ИИ
    env.player2_palette = [2, 9]      # Палитра противника (R2, O2)
    env.rule = 0                      # Текущее правило (0=Red)
    env._current_player = 0           # Ход ИИ
    
    # 2. Получаем решение ИИ
    obs = env._get_obs()
    legal_mask = env.legal_actions_mask()
    
    with torch.no_grad():
        q_values = agent.model({k: v.to(device) for k, v in obs.items()})[0].cpu().numpy()
    q_values[legal_mask == 0] = -np.inf
    
    chosen_action = np.unravel_index(np.argmax(q_values), q_values.shape)
    
    # 3. Выводим результат
    print("\nSimulated game state:")
    print(f"AI hand: {env._cards_to_str(env.player1_hand)}")
    print(f"AI palette: {env._cards_to_str(env.player1_palette)}")
    print(f"Opponent palette: {env._cards_to_str(env.player2_palette)}")
    print(f"Current rule: {env.COLOR_NAMES[env.rule]}")

    print("\nSelected AI action:")
    if chosen_action[0] == 0:
        print("Palette: PASS")
    else:
        print(f"Card to palette: {env._color_str(chosen_action[0])}")
    if chosen_action[1] == 0:
        print("Change rule: PASS")
    else:
        print(f"Card for rule: {env._color_str(chosen_action[1])}")

if __name__ == "__main__":
    test_specific_ai_decision()
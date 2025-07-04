from fastapi import APIRouter, Body, HTTPException
import uuid
import numpy as np
from ml.DQN import DQNAgent, Red7Env

router = APIRouter(prefix="/bot", tags=["bot"])

sessions = {}

def to_native(val):
    if isinstance(val, np.integer):
        return int(val)
    elif isinstance(val, np.floating):
        return float(val)
    elif isinstance(val, np.ndarray):
        return val.tolist()
    elif isinstance(val, dict):
        return {k: to_native(v) for k, v in val.items()}
    elif isinstance(val, (list, tuple)):
        return [to_native(v) for v in val]
    elif hasattr(val, "tolist"):  
        return val.tolist()
    elif hasattr(val, "item"):   
        return val.item()
    else:
        return val

COLORS = ["R", "O", "Y", "G", "B", "I", "V"]

def decode_card(idx):
    if idx == 50:
        return "R0"
    elif idx == 0:
        return
    color = (idx - 1) // 7
    value = (idx - 1) % 7 + 1
    return f"{COLORS[color]}{value}"

def encode_card(card_str: str) -> int:
    """Convert card string back to numerical index (e.g., 'R1' → 1, 'R0' → 50)"""
    if card_str == "R0":
        return 50
    
    color_char = card_str[0]  # First character (R,O,Y,G,B,I,V)
    value = int(card_str[1:])         # Remaining characters (number)
    
    color_idx = COLORS.index(color_char)
    
    return color_idx * 7 + value

def create_new_session():
    env = Red7Env(verbose=False)
    agent = DQNAgent(device='cpu')
    session_id = str(uuid.uuid4())
    sessions[session_id] = {"env": env, "agent": agent}
    return session_id

@router.post("/start")
async def start_bot_game():
    session_id = create_new_session()
    env = sessions[session_id]["env"]
    obs = env.reset()
    obs = to_native(obs)

    hand = obs.get("hand", [[]])[0]
    my_palette = obs.get("my_palette", [[]])[0]
    opp_palette = obs.get("opp_palette", [[]])[0]
    rule = obs.get("rule", [[]])[0]

    obs["hand_human"] = [decode_card(idx) for idx in hand]
    obs["my_palette_human"] = [decode_card(idx) for idx in my_palette if idx != 0]
    obs["opp_palette_human"] = [decode_card(idx) for idx in opp_palette if idx != 0]
    obs["rule_human"] = "R0" if rule else ""
    return {"session_id": session_id, "obs": obs}

def enrich_obs(obs, rule_card):
    obs = to_native(obs)
    hand = obs.get("hand", [[]])[0]
    my_palette = obs.get("my_palette", [[]])[0]
    opp_palette = obs.get("opp_palette", [[]])[0]
    rule = obs.get("rule", [[]])[0]

    obs["hand_human"] = [decode_card(idx) for idx in hand]
    obs["my_palette_human"] = [decode_card(idx) for idx in my_palette if idx != 0]
    obs["opp_palette_human"] = [decode_card(idx) for idx in opp_palette if idx != 0]
    obs["rule_human"] = rule_card if rule_card != 0 else ""
    return obs

@router.post("/move")
async def bot_move(session_id: str = Body(...), action: list = Body(...)):
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    env = sessions[session_id]["env"]
    agent = sessions[session_id]["agent"]

    obs, reward, done, _ = env.step(tuple(action))

    rule_card = decode_card(action[1]) if action[1] != 0 else 0
    obs = enrich_obs(obs, rule_card)

    if done:
        return {"obs": obs, "done": True, "winner": env.get_winner()}

    legal_mask = env.legal_actions_mask()
    bot_action = agent.select_action(obs, legal_mask)
    obs, reward, done, _ = env.step(bot_action)
    bot_rule_card = decode_card(bot_action[1]) if bot_action[1] != 0 else 0
    obs = enrich_obs(obs, bot_rule_card)
    
    # Convert bot_action to native Python type if it's a numpy type
    if isinstance(bot_action, (np.integer, np.floating)):
        bot_action = to_native(bot_action)
    elif isinstance(bot_action, (list, tuple, np.ndarray)):
        bot_action = [to_native(x) for x in bot_action]
    
    return {
        "obs": obs,
        "done": done,
        "bot_action": bot_action,
        "winner": to_native(env.get_winner()) if done else None
    }
# Import necessary libraries
from fastapi import APIRouter, Body, HTTPException
import uuid
import numpy as np
from ml.DQN import DQNAgent, Red7Env
import torch

# Create FastAPI router for bot endpoints
router = APIRouter(prefix="/bot", tags=["bot"])

# Dictionary to store active game sessions
sessions = {}

def to_native(val):
    """
    Convert numpy data types to native Python data types for JSON serialization.
    
    Args:
        val: Value to convert (can be of various types)
        
    Returns:
        Native Python version of the input value
    """
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

# Constants for card colors in Red7
COLORS = ["R", "O", "Y", "G", "B", "I", "V"]

def decode_card(idx):
    """
    Convert card index to human-readable format (e.g., 1 → 'R1').
    
    Args:
        idx: Card index (1-49 for regular cards, 50 for R0)
        
    Returns:
        String representation of card
    """
    if idx == 50:
        return "R0"
    elif idx == 0:
        return
    color = (idx - 1) // 7
    value = (idx - 1) % 7 + 1
    return f"{COLORS[color]}{value}"

def encode_card(card_str: str) -> int:
    """
    Convert card string back to numerical index (e.g., 'R1' → 1, 'R0' → 50).
    
    Args:
        card_str: String representation of a card (e.g. 'R1')
        
    Returns:
        Integer index of the card
    """
    if card_str == "R0":
        return 50
    
    color_char = card_str[0]  # First character (R,O,Y,G,B,I,V)
    value = int(card_str[1:])  # Remaining characters (number)
    
    color_idx = COLORS.index(color_char)
    
    return color_idx * 7 + value

def create_new_session():
    """
    Create a new game session with environment and agent.
    
    Returns:
        String: New session ID
    """
    env = Red7Env(verbose=False)
    agent = DQNAgent(device='cpu')
    agent.load("ml/final_agent (4).pth")
    session_id = str(uuid.uuid4())
    sessions[session_id] = {"env": env, "agent": agent}
    return session_id

@router.post("/start")
async def start_bot_game():
    """
    API endpoint to start a new game with the bot.
    
    Returns:
        Dictionary with session ID and initial observation
    """
    session_id = create_new_session()
    env = sessions[session_id]["env"]
    obs = env.reset()
    obs = to_native(obs)

    # Extract information from observation
    hand = obs.get("hand", [[]])[0]
    my_palette = obs.get("my_palette", [[]])[0]
    opp_palette = obs.get("opp_palette", [[]])[0]
    rule = obs.get("rule", [[]])[0]

    # Add human-readable versions of the cards
    obs["hand_human"] = [decode_card(idx) for idx in hand]
    obs["my_palette_human"] = [decode_card(idx) for idx in my_palette if idx != 0]
    obs["opp_palette_human"] = [decode_card(idx) for idx in opp_palette if idx != 0]
    obs["rule_human"] = "R0" if rule else ""
    return {"session_id": session_id, "obs": obs}

def enrich_obs(obs, rule_card):
    """
    Add human-readable card information to observation.
    
    Args:
        obs: Raw observation from environment
        rule_card: Current rule card
        
    Returns:
        Enriched observation with human-readable card info
    """
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
    """
    API endpoint to perform a player move and get the bot's response.
    
    Args:
        session_id: ID of the current game session
        action: Player's action as a list
        
    Returns:
        Dictionary with updated observation, bot's action, and game state
    """
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    env = sessions[session_id]["env"]
    agent = sessions[session_id]["agent"]

    # Process player's move
    obs, reward, done, _ = env.step(tuple(action))

    rule_card = decode_card(action[1]) if action[1] != 0 else 0
    obs = enrich_obs(obs, rule_card)

    # If game is over after player's move
    if done:
        return {"obs": obs, "done": True, "winner": env.get_winner()}

    # Get bot's move
    legal_mask = env.legal_actions_mask()
    
    # Convert observations to proper tensor types
    obs_tensor = {
        'hand': torch.tensor(obs['hand'], dtype=torch.long),  # Changed to long for embedding
        'my_palette': torch.tensor(obs['my_palette'], dtype=torch.long),  # Changed to long
        'opp_palette': torch.tensor(obs['opp_palette'], dtype=torch.long),  # Changed to long
        'rule': torch.tensor(obs['rule'], dtype=torch.long),  # Changed to long
        'hand_len': torch.tensor(obs['hand_len'], dtype=torch.float32),
        'my_palette_len': torch.tensor(obs['my_palette_len'], dtype=torch.float32),
        'opp_hand_len': torch.tensor(obs['opp_hand_len'], dtype=torch.float32),
        'opp_palette_len': torch.tensor(obs['opp_palette_len'], dtype=torch.float32),
        'known_deck': torch.tensor(obs['known_deck'], dtype=torch.float32)
    }
    
    # Move tensors to the same device as the model
    device = next(agent.model.parameters()).device
    obs_tensor = {k: v.to(device) for k, v in obs_tensor.items()}
    
    bot_action = agent.select_action(obs_tensor, legal_mask)
    obs, reward, done, _ = env.step(bot_action)
    bot_rule_card = decode_card(bot_action[1]) if bot_action[1] != 0 else 0
    obs = enrich_obs(obs, bot_rule_card)
    

    # Convert bot_action to native Python type for JSON serialization
    if isinstance(bot_action, (np.integer, np.floating)):
        bot_action = int(bot_action) if isinstance(bot_action, np.integer) else float(bot_action)
    elif isinstance(bot_action, np.ndarray):
        bot_action = bot_action.tolist()
    elif isinstance(bot_action, (list, tuple)):
        bot_action = [int(x) if isinstance(x, np.integer) else float(x) if isinstance(x, np.floating) else x for x in bot_action]
    
    return {
        "obs": obs,
        "done": done,
        "bot_action": bot_action,
        "winner": int(env.get_winner()) if done else None
    }
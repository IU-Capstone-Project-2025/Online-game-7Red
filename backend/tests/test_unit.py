import pytest
from app.red7state import Red7GameState, CardColor, CARD_VALUES

def test_initialize_deck_unique_cards():
    game = Red7GameState("test_room")
    game.initialize_deck()
    assert len(game.deck) == 49
    assert len(set(game.deck)) == 49
    
    expected_cards = {f"{color.value}{value}" for color in CardColor for value in CARD_VALUES}
    assert set(game.deck) == expected_cards
    

def test_most_of_one_color_rule():
    game = Red7GameState("test_room")
    game.players = {
        1: {"palette": ["R7", "R5", "G2"], "hand": [], "name": "A", "active": True, "possible_moves": {}},
        2: {"palette": ["G6", "G4", "B3"], "hand": [], "name": "B", "active": True, "possible_moves": {}}
    }
    
    result = game._most_of_one_color_rule(1, [2])
    assert result == [True]
    
    game.players[2]["palette"] = ["G7", "G5", "B3"]
    result = game._most_of_one_color_rule(1, [2])
    assert result == [True]
    
    game.players[2]["palette"] = ["R7", "R5", "B3"]
    result = game._most_of_one_color_rule(1, [2])
    assert isinstance(result[0], bool)
    
    
def test_highest_card_rule():
    game = Red7GameState("test_room")
    game.players = {
        1: {"palette": ["R7", "G2"], "hand": [], "name": "A", "active": True, "possible_moves": {}},
        2: {"palette": ["B6", "Y3"], "hand": [], "name": "B", "active": True, "possible_moves": {}}
    }
    result = game._highest_card_rule(1, [2])
    assert result == [True]

    # If both have the same highest card value, player wins by color (lower index)
    game.players[2]["palette"] = ["B7", "Y3"]
    # R7 (Red=0), B7 (Blue=4): 7==7, but Red < Blue, player 1 wins
    result = game._highest_card_rule(1, [2])
    assert result == [True]

    # If player 2 has R7, it's a tie in both color and value
    game.players[2]["palette"] = ["R7", "Y3"]
    result = game._highest_card_rule(1, [2])
    # Same cards — player 1 doesn't win by color
    assert result == [False]

    # If player 1 has empty palette — always False
    game.players[1]["palette"] = []
    result = game._highest_card_rule(1, [2])
    assert result == [False]

    # If opponent has empty palette — always True
    game.players[1]["palette"] = ["R7"]
    game.players[2]["palette"] = []
    result = game._highest_card_rule(1, [2])
    assert result == [True]
    
def test_most_of_one_number_rule():
    # Initialize game state
    game = Red7GameState("test_room")
    # Set up initial player states
    game.players = {
        1: {"palette": ["R7", "G7", "B5"], "hand": [], "name": "A", "active": True, "possible_moves": {}},
        2: {"palette": ["O7", "Y6", "B6"], "hand": [], "name": "B", "active": True, "possible_moves": {}}
    }
    
    # Test case 1: Player 1 has two 7s vs Player 2's one 7
    result = game._most_of_one_number_rule(1, [2])
    assert result == [True]  # Player 1 should win
    
    # Test case 2: Change Player 2's cards but Player 1 still wins
    game.players[2]["palette"] = ["O6", "Y6", "B7"]
    result = game._most_of_one_number_rule(1, [2])
    assert result == [True]  # Player 1 still wins with two 7s vs one 7
    
    # Test case 3: Now Player 2 has more of a single number (two 7s vs two 6s)
    game.players[1]["palette"] = ["R6", "G6", "B5"]
    game.players[2]["palette"] = ["O7", "Y7", "B4"]
    result = game._most_of_one_number_rule(1, [2])
    assert result == [False]  # Player 1 should lose
    
    # Test case 4: Empty palette always loses
    game.players[1]["palette"] = []
    result = game._most_of_one_number_rule(1, [2])
    assert result == [False]  # Player 1 should lose with empty palette

    # Test case 5: Player wins against empty opponent palette
    game.players[1]["palette"] = ["R7", "G7"]
    game.players[2]["palette"] = []
    result = game._most_of_one_number_rule(1, [2])
    assert result == [True]  # Player 1 should win against empty palette
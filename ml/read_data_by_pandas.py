import pandas as pd

columns = [
    "gameNumber",
    "roundNumber",
    "playerNumber",
    "ruleCardBinary",
    "handBinary",
    "paletteBinary",
    "otherPalettesBinary",
    "deckBinary",
    "eliminatedFlag",
    "winFlag"
]

df = pd.read_csv("dataset.txt", header=None, names=columns)

print(df.head(5)['deckBinary'])

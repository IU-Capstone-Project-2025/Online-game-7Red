/*
    Red7 Simulation and Data Generation Tool

    Описание(ru):
    Этот файл реализует симуляцию карточной игры Red7 с целью генерации обучающих данных
    для машинного обучения. Каждое состояние игры кодируется в виде строки бинарных признаков,
    включающих информацию о текущем правиле, руке игрока, палитрах, оставшихся в колоде картах,
    а также флагах "выбыл" и "победил".

    Основные компоненты:
    - enum Color: перечисление цветов, соответствующих правилам Red7.
    - class Card: класс для представления карты (цвет + значение).
    - comparison_*: функции сравнения палитр по правилам каждого цвета.
    - getWinningMoves: генерация всех возможных выигрышных ходов игрока.
    - cardsToBinaryArray / ruleCardToBinary / otherPalettesToBinary / deckCardsToBinary:
        функции для кодирования состояния игры в бинарные строки.
    - playFullGame: симулирует полную игру, записывая состояния в файл dataset.txt.

        Формат выходных данных (одна строка на ход активного игрока):
        [0]  gameNumber         — номер симулируемой игры (целое число начиная с 0)
        [1]  roundNumber        — номер раунда в игре (целое число начиная с 1)
        [2]  playerNumber       — номер игрока (целое число, начиная с 1)
        [3]  ruleBinary         — 50 бит (std::string), где только один бит установлен в 1,
                                  указывая на текущую карту-правило (по позиции в массиве из 50 карт)
        [4]  handBinary         — 50 бит, где 1 на позиции i означает, что карта с индексом i находится в руке игрока
        [5]  paletteBinary      — 50 бит, палитра (открытые карты перед игроком); аналогично handBinary
        [6]  otherPalettesBinary — 50 бит, палитры всех других игроков
        [7]  deckBinary         — 50 бит, оставшиеся в колоде карты (1 = есть в колоде, 0 = отсутствует)
        [8]  eliminatedFlag     — 1 бит (0 = игрок активен, 1 = выбыл)
        [9]  winFlag            — 1 бит (0 = игрок проиграл, 1 = игрок победил к концу игры)

    Описание битовых полей:
    - Каждое поле длиной 50 бит соответствует полному множеству возможных карт Red7.
      Индексы карт задаются в диапазоне [0..49], включая особую карту "красная 0" (index 49),
      которая не входит в колоду, но может использоваться как начальное правило.
    - Только один бит в ruleBinary может быть равен 1 (однозначно указывает на текущую карту-правило).
    - В остальных бинарных масках значение 1 означает наличие карты в соответствующем месте (руке, палитре и т.п.).

        Использование:
    - Запускается симуляция N игр (playFullGame), каждая игра записывает все состояния активного игрока.
    - Выход сохраняется в файл dataset.txt (каждая строка — один ход).

    Зависимости:
    - Стандартная библиотека C++ (iostream, vector, map, array, string, fstream, random, и др.)

    /*
    Red7 Simulation and Data Generation Tool

    Description(eng):
    This file implements a simulation of the Red7 card game to generate training data.
    for machine learning purposes. Each game state is encoded as a string of binary features.
    This includes information about the current rule, the player's hand, palettes and the remaining cards in the deck,
    as well as the 'eliminated' and 'won' flags.

    Main components:
    - enum Color: An enumeration of colours that conform to the Red7 rules.
    - class Card: A class for representing a card (colour + value).
    - comparison_*: Functions for comparing palettes according to the rules of each colour.
    - getWinningMoves: Generates all possible winning moves for the player.
    - cardsToBinaryArray, ruleCardToBinary, otherPalettesToBinary and deckCardsToBinary:
        Functions for encoding the game state into binary strings.
    - playFullGame: Simulates a full game by writing states to the dataset.txt file.

    The output data format is one line per turn of the active player.
    [0] GameNumber: the number of the simulated game (an integer starting from 0).
    [1] RoundNumber: The number of the round in the game (an integer starting from 1).
    [2] PlayerNumber: the player's number (an integer starting from 1).
    [3] RuleBinary — a 50-bit string, where only one bit is set to 1. This indicates the current card rule by position in an array of 50 cards.
    [4] HandBinary: 50 bits, where 1 at position i indicates that the card with index i is in the player's hand.
    [5] PaletteBinary — 50-bit palette (open cards in front of the player); similar to HandBinary.
    [6] OtherPalettesBinary: 50 bits representing the palettes of all the other players.
    [7] DeckBinary — 50 bits representing the remaining cards in the deck (1 = present, 0 = missing).
    [8] EliminatedFlag: 1 bit (0 = player is active; 1 = player has been eliminated).
    [9] WinFlag: 1 bit (0 = player lost; 1 = player won by the end of the game).

    Description of the bit fields:
    - Each 50-bit field corresponds to the full set of possible Red7 cards.
    - The indexes of the cards are set in the range [0..49], including the special card 'Red 0' (index 49),
    - This card is not included in the deck but can be used as an initial rule.
    - Only one bit in RuleBinary can be equal to 1 (this unambiguously indicates the current rule card).
    - In other binary masks, a value of 1 indicates that the card is in the correct position (in the hand, on the palette, etc.).

    Usage:
    A simulation of N games (playFullGame) runs, with each game recording all the states of the active player.
    The output is saved to a file called dataset.txt (each line represents one move).

    Dependencies:
    Standard C++ library (iostream, vector, map, array, string, fstream, random, etc.).
*/

#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <stdexcept>
#include <tuple>
#include <set>
#include <algorithm>
#include <chrono>
#include <ctime>
#include <random>
#include <array>
#include <fstream>
#include <sstream> 
using namespace std;

enum Color {
    Red = 0,
    Orange = 1,
    Yellow = 2,
    Green = 3,
    LightBlue = 4,
    Blue = 5,
    Violet = 6
};

string getColorName(Color color) {
    switch (color) {
        case Red:    return "Red";
        case Orange: return "Orange";
        case Yellow: return "Yellow";
        case Green:  return "Green";
        case LightBlue: return "LightBlue";
        case Blue: return "Blue";
        case Violet: return "Violet";
        default:     return "Unknown";
    }
}

class Card {
public:
    Card(Color c, int v) : color(c), value(v) {}
    Card() : color(Red), value(0) {} 

    int getValue() const { return value; }
    Color getColor() const { return color; }

    string toString() const {
        return getColorName(color) + " " + to_string(value);
    }

    bool operator<(const Card& other) const {
        if (value != other.value)
            return value < other.value;
        return color > other.color;
    }

private:
    Color color;
    int value;
};

Card findMaxCard(const vector<Card>& cards) {
    if (cards.empty()) {
        throw runtime_error("Пустой вектор карт");
    }

    Card maxCard = cards[0];
    for (const Card& c : cards) {
        if (maxCard < c) {
            maxCard = c;
        }
    }
    return maxCard;
}

bool comparison_red(const vector<Card>& hand1, const vector<Card>& hand2) {
    if (hand1.empty() || hand2.empty()) {
        return false;
    }
    return findMaxCard(hand1) < findMaxCard(hand2);
}

tuple<int, Card> comparison_orange(const vector<Card>& cards) {
    if (cards.empty()) {
        throw runtime_error("Пустой вектор карт");
    }

    map<int, vector<Card>> groups;
    for (const Card& c : cards) {
        groups[c.getValue()].push_back(c);
    }

    int maxCount = 0;
    Card maxCard = cards[0];

    for (const auto& [value, group] : groups) {
        int count = (int)group.size();
        Card localMax = findMaxCard(group);

        if (count > maxCount || (count == maxCount && maxCard < localMax)) {
            maxCount = count;
            maxCard = localMax;
        }
    }

    return make_tuple(maxCount, maxCard);
}

tuple<int, Card> comparison_yellow(const vector<Card>& cards) {
    if (cards.empty()) {
        throw runtime_error("Пустой вектор карт");
    }

    map<Color, vector<Card>> groups;
    for (const Card& c : cards) {
        groups[c.getColor()].push_back(c);
    }

    int maxCount = 0;
    Card maxCard = cards[0];

    for (const auto& [color, group] : groups) {
        int count = (int)group.size();
        Card localMax = findMaxCard(group);

        if (count > maxCount || (count == maxCount && maxCard < localMax)) {
            maxCount = count;
            maxCard = localMax;
        }
    }

    return make_tuple(maxCount, maxCard);
}

tuple<int, Card> comparison_green(const vector<Card>& cards) {
    vector<Card> filtered;
    for (const Card& c : cards) {
        if (c.getValue() % 2 == 0) {
            filtered.push_back(c);
        }
    }
    if (filtered.empty()) {
        throw runtime_error("Нет чётных карт");
    }

    return make_tuple((int)filtered.size(), findMaxCard(filtered));
}

tuple<int, Card> comparison_lightblue(const vector<Card>& cards) {
    set<Color> uniqueColors;
    for (const Card& c : cards) {
        uniqueColors.insert(c.getColor());
    }
    return make_tuple((int)uniqueColors.size(), findMaxCard(cards));
}

tuple<int, Card> comparison_blue(const vector<Card>& cards) {
    if (cards.empty()) {
        throw runtime_error("Пустой вектор карт");
    }

    vector<int> values;
    for (const Card& c : cards) {
        values.push_back(c.getValue());
    }

    sort(values.begin(), values.end());

    int maxLen = 1, curLen = 1;
    int maxEndValue = values[0];

    for (size_t i = 1; i < values.size(); ++i) {
        if (values[i] == values[i - 1] + 1) {
            ++curLen;
            if (curLen > maxLen) {
                maxLen = curLen;
                maxEndValue = values[i];
            }
        } else if (values[i] != values[i - 1]) {
            curLen = 1;
        }
    }

    Card maxCard = cards[0];
    bool found = false;

    for (const Card& c : cards) {
        if (c.getValue() == maxEndValue) {
            if (!found || maxCard < c) {
                maxCard = c;
                found = true;
            }
        }
    }

    return make_tuple(maxLen, maxCard);
}

tuple<int, Card> comparison_violet(const vector<Card>& cards) {
    vector<Card> filtered;
    for (const Card& c : cards) {
        if (c.getValue() < 4) {
            filtered.push_back(c);
        }
    }

    if (filtered.empty()) {
        throw runtime_error("Нет карт с номиналом меньше 4");
    }

    return make_tuple((int)filtered.size(), findMaxCard(filtered));
}

vector<tuple<Card, vector<Card>, vector<Card>>> getWinningMoves(
    Card ruleCard,
    const vector<Card>& hand,
    const vector<Card>& myPalette,
    const vector<vector<Card>>& otherPalettes
) {
    vector<tuple<Card, vector<Card>, vector<Card>>> results;

    Color currentRule = ruleCard.getColor();

    auto checkWin = [&](const vector<Card>& me, Color ruleColor) {
        try {
            tuple<int, Card> myResult;

            if (ruleColor == Red)            myResult = make_tuple(1, findMaxCard(me));
            else if (ruleColor == Orange)    myResult = comparison_orange(me);
            else if (ruleColor == Yellow)    myResult = comparison_yellow(me);
            else if (ruleColor == Green)     myResult = comparison_green(me);
            else if (ruleColor == LightBlue) myResult = comparison_lightblue(me);
            else if (ruleColor == Blue)      myResult = comparison_blue(me);
            else if (ruleColor == Violet)    myResult = comparison_violet(me);

            for (const auto& opp : otherPalettes) {
                if (opp.empty()) continue;

                tuple<int, Card> oppResult;

                if (ruleColor == Red)            oppResult = make_tuple(1, findMaxCard(opp));
                else if (ruleColor == Orange)    oppResult = comparison_orange(opp);
                else if (ruleColor == Yellow)    oppResult = comparison_yellow(opp);
                else if (ruleColor == Green)     oppResult = comparison_green(opp);
                else if (ruleColor == LightBlue) oppResult = comparison_lightblue(opp);
                else if (ruleColor == Blue)      oppResult = comparison_blue(opp);
                else if (ruleColor == Violet)    oppResult = comparison_violet(opp);

                if (myResult < oppResult) return false;
            }

            return true;
        } catch (...) {
            return false;
        }
    };

    // 1. Одинарный ход — в палитру
    for (size_t i = 0; i < hand.size(); ++i) {
        vector<Card> newPalette = myPalette;
        newPalette.push_back(hand[i]);

        if (checkWin(newPalette, currentRule)) {
            vector<Card> newHand = hand;
            newHand.erase(newHand.begin() + i);
            results.push_back(make_tuple(ruleCard, newHand, newPalette));
        }
    }

    // 2. Одинарный ход — смена правила
    for (size_t i = 0; i < hand.size(); ++i) {
        Color newRule = hand[i].getColor();
        Card newRuleCard = hand[i];
        vector<Card> newHand = hand;
        newHand.erase(newHand.begin() + i);

        if (checkWin(myPalette, newRule)) {
            results.push_back(make_tuple(newRuleCard, newHand, myPalette));
        }
    }

    // 3. Двойной ход — и в палитру, и смена правила
    for (size_t i = 0; i < hand.size(); ++i) {
        for (size_t j = 0; j < hand.size(); ++j) {
            if (i == j) continue;

            vector<Card> newPalette = myPalette;
            newPalette.push_back(hand[i]);
            Color newRule = hand[j].getColor();
            Card newRuleCard = hand[j];

            vector<Card> newHand = hand;
            if (i > j) {
                newHand.erase(newHand.begin() + i);
                newHand.erase(newHand.begin() + j);
            } else {
                newHand.erase(newHand.begin() + j);
                newHand.erase(newHand.begin() + i);
            }

            if (checkWin(newPalette, newRule)) {
                results.push_back(make_tuple(newRuleCard, newHand, newPalette));
            }
        }
    }

    return results;
}

vector<Card> createFullDeck() {
    vector<Card> deck;
    for (int color = 0; color <= 6; ++color) {
        for (int value = 1; value <= 7; ++value) {
            deck.emplace_back(static_cast<Color>(color), value);
        }
    }
    return deck;
}

unsigned int getSeedFromTime() {
    auto now = chrono::system_clock::now();
    time_t now_time_t = chrono::system_clock::to_time_t(now);
    tm local_tm = *localtime(&now_time_t);

    // Суммируем часы, минуты, секунды, день, месяц, год
    unsigned int seed = local_tm.tm_hour + local_tm.tm_min + local_tm.tm_sec +
                        local_tm.tm_mday + (local_tm.tm_mon + 1) + (local_tm.tm_year + 1900);
    return seed;
}

vector<vector<Card>> dealCards(int numPlayers) {
    vector<Card> deck = createFullDeck();
    unsigned int seed = getSeedFromTime();

    mt19937 gen(seed);
    shuffle(deck.begin(), deck.end(), gen);

    vector<vector<Card>> hands(numPlayers);

    int cardsPerPlayer = 7;

    for (int player = 0; player < numPlayers; ++player) {
        hands[player].assign(deck.begin() + player * cardsPerPlayer, deck.begin() + (player + 1) * cardsPerPlayer);
    }

    return hands;
}
int getCardIndex(const Card& card) {
    if (card.getColor() == Red && card.getValue() == 0) {
        return 49;
    } else {
        return static_cast<int>(card.getColor()) * 7 + card.getValue() - 1;
    }
}

// Бинарный вектор из 50 битов: 49 обычных карт + красная 0
string cardsToBinaryArray(const vector<Card>& cards) {
    array<int, 50> presence = {0};
    for (const auto& c : cards) {
        presence[getCardIndex(c)] = 1;
    }
    string result;
    for (int i = 0; i < 50; ++i) {
        result += presence[i] ? '1' : '0';
    }
    return result;
}

string ruleCardToBinary(const Card& ruleCard) {
    array<int, 50> presence = {0};
    presence[getCardIndex(ruleCard)] = 1;
    string result;
    for (int i = 0; i < 50; ++i) {
        result += presence[i] ? '1' : '0';
    }
    return result;
}

string otherPalettesToBinary(const vector<vector<Card>>& palettes, int currentPlayer, const vector<bool>& active) {
    array<int, 50> presence = {0};
    for (int i = 0; i < (int)palettes.size(); ++i) {
        if (i != currentPlayer && active[i]) {
            for (const auto& c : palettes[i]) {
                presence[getCardIndex(c)] = 1;
            }
        }
    }
    string result;
    for (int i = 0; i < 50; ++i) {
        result += presence[i] ? '1' : '0';
    }
    return result;
}

string deckCardsToBinary(const vector<vector<Card>>& hands, const vector<vector<Card>>& palettes, const vector<bool>& active) {
    array<int, 50> presence = {0};

    // Изначально все обычные карты в колоде (0–48), красная 0 (49) не входит
    for (int i = 0; i < 49; ++i) {
        presence[i] = 1;
    }

    for (int i = 0; i < (int)hands.size(); ++i) {
        if (active[i]) {
            for (const auto& c : hands[i]) {
                presence[getCardIndex(c)] = 0;
            }
            for (const auto& c : palettes[i]) {
                presence[getCardIndex(c)] = 0;
            }
        }
    }

    string result;
    for (int i = 0; i < 50; ++i) {
        result += presence[i] ? '1' : '0';
    }
    return result;
}

void playFullGame(int gameNumber, int numPlayers) {
    ofstream out("dataset.txt", ios::app);
    if (!out.is_open()) {
        cerr << "Не удалось открыть файл dataset.txt для записи\n";
        return;
    }

    auto hands = dealCards(numPlayers);
    vector<vector<Card>> palettes(numPlayers);
    Card ruleCard = Card(Red, 0); // красная 0 - начальное правило
    vector<bool> active(numPlayers, true);
    int finalWinner = -1;
    int round = 1;
    mt19937 rng(getSeedFromTime());

    struct MoveInfo {
        string line;
        int playerIndex;
    };
    vector<MoveInfo> allMoves;

    while (true) {
        int activeCount = count(active.begin(), active.end(), true);

        if (activeCount == 1) {
            for (int i = 0; i < numPlayers; ++i) {
                if (active[i]) {
                    finalWinner = i;
                    break;
                }
            }

            for (auto& move : allMoves) {
                if (move.playerIndex == finalWinner)
                    move.line += ",1\n";  // победил
                else
                    move.line += ",0\n";  // не победил
                out << move.line;
            }

            return;
        }

        for (int i = 0; i < numPlayers; ++i) {
            if (!active[i]) continue;

            vector<vector<Card>> otherPalettes;
            for (int j = 0; j < numPlayers; ++j) {
                if (j != i && active[j]) {
                    otherPalettes.push_back(palettes[j]);
                }
            }

            auto moves = getWinningMoves(ruleCard, hands[i], palettes[i], otherPalettes);

            stringstream ss;
            ss << gameNumber << "," << round << "," << (i + 1) << ",";

            if (moves.empty()) {
    int stillActive = count(active.begin(), active.end(), true);
    if (stillActive == 1) {
        // последний игрок не может сделать ход — но он побеждает
        finalWinner = i;
        ss << ruleCardToBinary(ruleCard) << ",";
        ss << cardsToBinaryArray(hands[i]) << ",";
        ss << cardsToBinaryArray(palettes[i]) << ",";
        ss << otherPalettesToBinary(palettes, i, active) << ",";
        ss << deckCardsToBinary(hands, palettes, active);
        ss << ",0"; // не выбыл
        allMoves.push_back({ss.str(), i});

        for (auto& move : allMoves) {
            if (move.playerIndex == finalWinner)
                move.line += ",1\n";  // победил
            else
                move.line += ",0\n";  // не победил
            out << move.line;
        }

        return;
    }

    // обычный случай: игрок выбывает
    active[i] = false;
    ss << ruleCardToBinary(ruleCard) << ",";
    ss << cardsToBinaryArray(hands[i]) << ",";
    ss << cardsToBinaryArray(palettes[i]) << ",";
    ss << otherPalettesToBinary(palettes, i, active) << ",";
    ss << deckCardsToBinary(hands, palettes, active);
    ss << ",1"; // выбыл
    allMoves.push_back({ss.str(), i});
    continue;
}

            // обычный случай: игрок делает ход
            uniform_int_distribution<int> dist(0, (int)moves.size() - 1);
            auto& [newRuleCard, newHand, newPalette] = moves[dist(rng)];

            ruleCard = newRuleCard;
            hands[i] = newHand;
            palettes[i] = newPalette;

            ss << ruleCardToBinary(ruleCard) << ",";
            ss << cardsToBinaryArray(hands[i]) << ",";
            ss << cardsToBinaryArray(palettes[i]) << ",";
            ss << otherPalettesToBinary(palettes, i, active) << ",";
            ss << deckCardsToBinary(hands, palettes, active);
            ss << ",0"; // не выбыл
            allMoves.push_back({ss.str(), i});
            continue;
        }

        ++round;
    }
}



int main() {
    std::ofstream out("dataset.txt");
    if (!out.is_open()) {
        std::cerr << "Не удалось открыть dataset.txt для записи\n";
        return 1;
    }
    out.close();
    int numGames = 10000;
    int numPlayers = 2;
    for (int i = 0; i < numGames; ++i) {
        if (i % 1000 == 0) {
            cout << "Симуляция игры " << (i + 1) << " из " << numGames << endl;
        }
        playFullGame(i, numPlayers);
    }
    return 0;
}



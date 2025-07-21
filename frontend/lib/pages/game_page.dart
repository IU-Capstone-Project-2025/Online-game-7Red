import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../customWidgets/cards.dart';
import '../socket/web_socket.dart';
import '../data/player.dart';
import '../data/urls.dart';
import '../customWidgets/ruleDialog.dart';
import 'package:frontend/providers/provider.dart';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

// Controllers for countdown timers of 2-4 players
final _countDownControllerDown = CountDownController();
final _countDownControllerRight = CountDownController();
final _countDownControllerUp = CountDownController();
final _countDownControllerLeft = CountDownController();


class _GameRoomPageState extends State<GameRoomPage> {
  String? roomID;
  int? userID;
  String serverUrl = '?';

  int gamemode = 4;

  late GameWebSocket _webSocket;
  List<String> _myHand = [];
  List<Player> _players = [];
  List<String> _pallete = [];
  List<int> _activePlayers = [];
  String _ruleCard = 'R0';
  int _currentPlayerId = -1;
  int _nextLose = 0;
  Timer? _turnTimer;
  int _timeLeft = 60;
  String my_pallete_ch = '';

  Player? playerUp;
  Player? playerLeft;
  Player? playerRight;

  Timer? _allTimeTimer;
  int _allTime = 0;

  bool myTurn = false;
  bool myAllTurn = false;
  bool ruleChanged = true;
  bool palleteChanged = true;

  bool youLose = false;

  List<CountDownController> timers = [];
  int currTimerIndex = 0;
  List<CountDownController> timersDied = [];

  int myPlace = 0;

  bool aiGame = false;

  Timer? _delayTimer;
  Timer? _delayTimerWin;
  int delay = 5;
  int delayWin = 5;

  bool exited = false;

  Color ringColorUp = greyTimerColor;
  Color ringColorLeft = greyTimerColor;
  Color ringColorRight = greyTimerColor;
  Color ringColorDown = greyTimerColor;

  int myTimerDuration = 60;
  bool isReverseAnimationDown = true;
  Color MyTimerColor = greenTimerColor;

  Image? _downloadedAvatarUp;
  Image? _downloadedAvatarLeft;
  Image? _downloadedAvatarRight;
  Image? _downloadedAvatarDown;

  @override
  void initState() {
    super.initState();
    // connect to web socket immediately
    _connectToWebSocket(); 
  }

  void _connectToWebSocket() async{
    try {
      // Get info about user from WaitingRoomPage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      roomID = await prefs.getString('roomId');
      userID = await prefs.getInt('myID');
      aiGame = await prefs.getBool('aiGame') ?? false;
      gamemode = aiGame ? 2 : await prefs.getInt('playerNum') ?? 2; //⭐️
      // Choose the mode of the game in case of AI or 2-4 players
      if (aiGame) {
        serverUrl = '$serverUrlPartUrl/ai_game/$userID';
      } else {
        serverUrl = '$serverUrlPartUrl/game/$roomID/ws?player_id=$userID';
      }
      print(serverUrl);
      // Connect to web socket
      _webSocket = GameWebSocket(
        serverUrl: serverUrl,
        onMessageReceived: _handleMessage,
        onConnectionClosed: _onDisconnected,
      );
      _webSocket.connect();
    } catch (e) {
      // If an error occurs, print the error message in the console
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка подключения: $e')),
      );
    }
  }

  /// Handles messages from the server.
  ///
  /// The message is a Json object containing a 'type' key that
  /// determines how the message is handled. The possible types are:
  ///
  /// - 'initialized': The game has started and the player's hand is being
  ///     sent.
  /// - 'wrong_turn': The current player made an invalid move.
  /// - 'right_turn': The current player made a valid move.
  /// - 'change_turn': The turn has been changed to the next player. 
  void _handleMessage(dynamic message) {
    switch (message['type']) {
      case 'initialized':
        _handleInitialized(message);
        break;
      case 'wrong_turn':
        _handleWrongTurn(message);
        break;
      case 'right_turn':
        _handleRightTurn();
        break;
      case 'change_turn':
        if (!exited) {
          _handleChangeTurn(message);
        } 
        break;
    }
  }

  void _handleInitialized(Map<String, dynamic> message) {
    setState(() {
      // Get cards that player has
      _myHand = List<String>.from(message['my_hand']);
      // Get player's info (name, id)
      _players = List.generate(
        message['names'].length,
        (index) => Player(
          id: message['id'][index],
          name: message['names'][index],
          isMe: message['id'][index] == userID,
        ),
      );
      // Array for active players
      _activePlayers = message['id'];
      // Current player is first in array
      _currentPlayerId = message['id'][0];

      final player = _players.firstWhere((p) => p.id == _activePlayers[0]);
      // Check if first turn is for this user
      if (player.isMe) {
        myTurn = true;
        palleteChanged = false;
        ruleChanged = false;
        my_pallete_ch = "";
        myAllTurn = true;
      }
      // Check game mode (gamemode = 2 for 2 players, gamemode = 3 for 3 players, gamemode = 4 for 4 players)
      if (gamemode == 2) {
        // Set playerUp and animated timers
        if (_players.length == 1) {
          playerUp = player;
        } else {
          if (player.isMe == false ) {
            playerUp = player;
            timers = [_countDownControllerDown, _countDownControllerUp];
            _fetchAvatar(_activePlayers[0], "up");
            _fetchAvatar(_activePlayers[1], "down");
          } else {
            playerUp = _players.firstWhere((p) => p.id == _activePlayers[1]);
            _fetchAvatar(_activePlayers[1], "up");
            _fetchAvatar(_activePlayers[0], "down");
            timers = [_countDownControllerUp, _countDownControllerDown];
          }
        }
      } else if (gamemode == 3) {
        // Set playerRight, playerLeft
        final myIndex = _players.indexOf(_players.firstWhere((p) => p.id == userID));
        playerRight = _players[(myIndex + 1) % _players.length];
        playerLeft = _players[(myIndex + 2) % _players.length];
        _fetchAvatar(_activePlayers[myIndex], "down");
        _fetchAvatar(_activePlayers[(myIndex + 1) % _players.length], "right");
        _fetchAvatar(_activePlayers[(myIndex + 2) % _players.length], "left");
        // Set animated timers
        timers = [_countDownControllerDown, _countDownControllerDown, _countDownControllerDown,];
        timers[(myIndex + 1) % _players.length] = _countDownControllerDown;
        timers[(myIndex + 2) % _players.length] = _countDownControllerRight;
        timers[(myIndex + 3) % _players.length] = _countDownControllerLeft;
      } else if (gamemode == 4) {
        // Set playerRight, playerUp, playerLeft
        final myIndex = _players.indexOf(_players.firstWhere((p) => p.id == userID));
        playerRight = _players[(myIndex + 1) % _players.length];
        playerUp = _players[(myIndex + 2) % _players.length];
        playerLeft = _players[(myIndex + 3) % _players.length];
        _fetchAvatar(_activePlayers[myIndex], "down");
        _fetchAvatar(_activePlayers[(myIndex + 1) % _players.length], "right");
        _fetchAvatar(_activePlayers[(myIndex + 2) % _players.length], "up");
        _fetchAvatar(_activePlayers[(myIndex + 3) % _players.length], "left");
        // Set animated timers
        timers = [_countDownControllerDown, _countDownControllerDown, _countDownControllerDown, _countDownControllerDown];
        timers[(myIndex + 1) % _players.length] = _countDownControllerDown;
        timers[(myIndex + 2) % _players.length] = _countDownControllerRight;
        timers[(myIndex + 3) % _players.length] = _countDownControllerUp;
        timers[(myIndex + 4) % _players.length] = _countDownControllerLeft;
      }
      // Start timer for counting Total Time of game
      _allTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _allTime++;
      });
      // Start turn
      _startTurnTimer();
    });
  }

  void _handleWrongTurn(Map<String, dynamic> message) {
    setState(() {
      // Return the card to my hand fron pallete
      if (message['my_pallete_ch'] != null) {
        _pallete.remove(message['my_pallete_ch']);
        _myHand.add(message['my_pallete_ch']);
      }
      // Return the card to my hand fron rule
      if (message['rule_ch'] != null) {
        _myHand.add(message['rule_ch']);
      }
      // Return old rule
      _ruleCard = message['old_rule'];
      // Rreturn turn privilegies to do the turn
      myTurn = true;
      palleteChanged = false;
      ruleChanged = false;
      myAllTurn = true;
    });
  }

  void _handleRightTurn() {
    // Stop turn timer
    _turnTimer?.cancel();
    // Reset turn privilegies
    setState(() {
      myTurn = false;
      ruleChanged = true;
      palleteChanged = true;
      myAllTurn = false;
    });
  }

  void _handleChangeTurn(Map<String, dynamic> message) {
    setState(() {
      // find player that made the move
      final player = _players.firstWhere((p) => p.id == message['id_did']);

      // Check if player lose 
      if (message['lose'] == 1) {
        // If he lose his pallete will be empty
        if (gamemode == 2 && _activePlayers.length != 2) {
          if (player.id == playerUp!.id) {
            playerUp!.pallete = [];
            ringColorUp = redCard;
          }
        } else if (gamemode == 3 && _activePlayers.length != 2) {
          if (player.id == playerRight!.id) {
            playerRight!.pallete = [];
            ringColorRight = redCard;
          } else if (player.id == playerLeft!.id) {
            playerLeft!.pallete = [];
            ringColorLeft = redCard;
          }
        } else if (gamemode == 4 && _activePlayers.length != 2) {
          if (player.id == playerRight!.id) {
            playerRight!.pallete = [];
            ringColorRight = redCard;
          } else if (player.id == playerUp!.id) {
            playerUp!.pallete = [];
            ringColorUp = redCard;
          } else if (player.id == playerLeft!.id) {
            playerLeft!.pallete = [];
            ringColorLeft = redCard;
          }
        }
        // Remove player from active players, kill his timer
        _players[_players.indexOf(player)].place = _activePlayers.length;
        _activePlayers.remove(message['id_did']);
        timersDied.add(timers[(_players.indexOf(player) + 1) % _players.length]);
      } else {
        // Add card to player pallete
        if (message['his_pallete_ch'] != null) {
          if (gamemode == 2) {
            if (player.id == playerUp!.id) {
              playerUp!.pallete.add(message['his_pallete_ch']);
              playerUp!.numOfCards--;
            }
          } else if (gamemode == 3) {
            if (player.id == playerRight!.id) {
              playerRight!.pallete.add(message['his_pallete_ch']);
              playerRight!.numOfCards--;
            } else if (player.id == playerLeft!.id) {
              playerLeft!.pallete.add(message['his_pallete_ch']);
              playerLeft!.numOfCards--;
            }
          } else if (gamemode == 4) {
            if (player.id == playerRight!.id) {
              playerRight!.pallete.add(message['his_pallete_ch']);
              playerRight!.numOfCards--;
            } else if (player.id == playerUp!.id) {
              playerUp!.pallete.add(message['his_pallete_ch']);
              playerUp!.numOfCards--;
            } else if (player.id == playerLeft!.id) {
              playerLeft!.pallete.add(message['his_pallete_ch']);
              playerLeft!.numOfCards--;
            }
          }
        }
      }
      // Update rule after change
      if (message['rule_ch'] != null) {
        _ruleCard = message['rule_ch'];
        if (gamemode == 2) {
          if (player.id == playerUp!.id) {
            playerUp!.numOfCards--;
          }
        } else if (gamemode == 3) {
          if (player.id == playerRight!.id) {
            playerRight!.numOfCards--;
          } else if (player.id == playerLeft!.id) {
            playerLeft!.numOfCards--;
          }
        } else if (gamemode == 4) {
          if (player.id == playerRight!.id) {
            playerRight!.numOfCards--;
          } else if (player.id == playerUp!.id) {
            playerUp!.numOfCards--;
          } else if (player.id == playerLeft!.id) {
            playerLeft!.numOfCards--;
          }
        }
      }
      // Check if the next player lose
      _nextLose = message['next_lose'];
      // Update current player
      _currentPlayerId = nextPlayerId(_currentPlayerId);

      // Check if game is over
      if (_activePlayers.length == 1) {
        _turnTimer?.cancel();
        for (var timer in timers) {
          timer.reset();
        }
        _allTimeTimer?.cancel();
        // set a place for the winner
        _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = 1;

        if (youLose == false) {
          myPlace = 1;
          // Анимация выигрыша (Фиолетовый кружочек), а оставшемуся красный кружочек
          setState(() {
            // myTimerDuration = 5;
            isReverseAnimationDown = false;
            ringColorDown = violetCard;
            MyTimerColor = greyTimerColor;
            if (gamemode == 2) {
              ringColorUp = redCard;
            } else if (gamemode == 3) {
              if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerRight) {
              ringColorRight = redCard;
              } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerLeft) {
                ringColorLeft = redCard;
              }
            } else if (gamemode == 4) {
              if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerRight) {
              ringColorRight = redCard;
              } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerUp) {
                ringColorUp = redCard;
              } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerLeft) {
                ringColorLeft = redCard;
              }
            }
          });
          _countDownControllerDown.restart(duration: 5);
        } else {
          // Анимация проигрыша (Красный кружочек), а оставшемуся фиолетовый кружочек
          if (_players.firstWhere((p) => p.id == userID).place == 2) {
            setState(() {
              // myTimerDuration = 5;
              isReverseAnimationDown = false;
              ringColorDown = redCard;
              MyTimerColor = greyTimerColor;
            });
            _countDownControllerDown.restart(duration: 5);
          }
          if (gamemode == 2) {
            ringColorUp = violetCard;
          } else if (gamemode == 3) {
            if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerRight) {
            ringColorRight = redCard;
            } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerLeft) {
              ringColorLeft = redCard;
            }
            if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 1)) + 1) % _players.length] == _countDownControllerRight) {
            ringColorRight = violetCard;
            } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 1)) + 1) % _players.length] == _countDownControllerLeft) {
              ringColorLeft = violetCard;
            }
          } else if (gamemode == 4) {
            if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerRight) {
            ringColorRight = redCard;
            } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerUp) {
              ringColorUp = redCard;
            } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 2)) + 1) % _players.length] == _countDownControllerLeft) {
              ringColorLeft = redCard;
            }
            if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 1)) + 1) % _players.length] == _countDownControllerRight) {
            ringColorRight = violetCard;
            } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 1)) + 1) % _players.length] == _countDownControllerUp) {
              ringColorUp = violetCard;
            } else if (timers[(_players.indexOf(_players.firstWhere((p) => p.place == 1)) + 1) % _players.length] == _countDownControllerLeft) {
              ringColorLeft = violetCard;
            }
          }
        }
        _webSocket.disconnect();
        // Win
        // ScaffoldMessenger.of(
        //     context,
        //   ).showSnackBar(SnackBar(content: Text(Provider.of<GameProvider>(context).localizations!.getString('game_over', Provider.of<GameProvider>(context).languageCode), textAlign: TextAlign.center,)));
        delayWin = 5;
        _delayTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (delayWin > 0) {
            setState(() => delayWin--);
          } else {
            timer.cancel();
            setState(() {
              _pallete = [];
              _myHand = [];
            });
            goToResults();
          }
        });
        return;
      }

      // check if the next player is me
      if (_players.firstWhere((p) => p.id == _currentPlayerId).isMe) {
        // Check if this user lose
        if (_nextLose == 1 && _activePlayers.length != 2) {
          _turnTimer?.cancel();
          youLose = true;
          myPlace = _activePlayers.length;
          // set a place for the looser
          _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = _activePlayers.length;
          // Loose
          // Анимация проигрыша (Красный кружочек)
          setState(() {
            // myTimerDuration = 5;
            isReverseAnimationDown = false;
            ringColorDown = redCard;
            MyTimerColor = greyTimerColor;
          });
          _countDownControllerDown.restart(duration: 5);
          // ScaffoldMessenger.of(
          //   context,
          // ).showSnackBar(SnackBar(content: Text(Provider.of<GameProvider>(context).localizations!.getString('game_lose', Provider.of<GameProvider>(context).languageCode), textAlign: TextAlign.center,)));
          delay = 5;
          _delayTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            if (delay > 0) {
              setState(() => delay--);
            } else {
              timer.cancel();
              setState(() {
                _pallete = [];
                _myHand = [];
              });
              loosing();
            }
          });
          return;
        } else if (_nextLose == 1 && _activePlayers.length == 2) {
          _turnTimer?.cancel();
          youLose = true;
          myPlace = _activePlayers.length;
          // set a place for the looser
          _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = _activePlayers.length;
        } else {
          // Start my turn
          myTurn = true;
          palleteChanged = false;
          ruleChanged = false;
          my_pallete_ch = "";
          myAllTurn = true;
        }
      }
      // Start turn timer
      _startTurnTimer();
    });
  }

  void _startTurnTimer() {
    // Cancel previous timer
    _turnTimer?.cancel();
    // Change animated timer to the next
    nextTimer();
    if (!youLose) {
      setState(() => _timeLeft = 60);
      _turnTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          timer.cancel();
          // If time is over and it is turn of this player — senf timeout to Backend
          if (myAllTurn) {
            _submitTurnTimeout(true);
          }
        }
      });
    }
  }

  // Change animated timer
  void nextTimer() {
    // Cancel previous timer
    timers[currTimerIndex].reset();
    // Change animated timer to the next
    currTimerIndex = (currTimerIndex + 1) % timers.length;
    // Check if all timers are dead
    if (timers.length != timersDied.length) {
      // Find the first timer that is not dead
      while (true) {
        if (timersDied.contains(timers[currTimerIndex]) == false) {
          timers[currTimerIndex].restart();
          break;
        } else {
          currTimerIndex = (currTimerIndex + 1) % timers.length;
        }
      }
    }
  }


  /// Sends a message to the server with the player's move.
  ///
  /// The message contains the player's ID, room ID, changed palette, changed rule,
  /// current hand and current palette.
  ///
  /// The message is sent only if the player has changed palette or rule.
  ///
  /// The player's turn is ended and the player's variables are reset after sending
  /// the message.
  void _submitTurn() {

    setState(() {
      myTurn = false;
      myAllTurn = true;
    });

    var message = {
      'type': 'my_turn',
      'my_id': userID ?? null,
      'my_room': roomID ?? null,
      'my_pallete_ch': palleteChanged ? my_pallete_ch : null,
      'rule_ch': ruleChanged ? _ruleCard : null,
      'my_hand': _myHand,
      'pallete': _pallete,
    };

    setState(() {
      palleteChanged = true;
      ruleChanged = true;
    });

    _webSocket.sendMessage(message);
  }

  /// Sends a message to the server that the player's turn has timed out.
  ///
  /// Cancels the turn timer, resets the player's variables and sends a message
  /// to the server with the type 'time_out'.
  ///
  /// The message is sent only if the player's turn has timed out.
  ///
  /// The server then handles the message and sends a response to all the players
  /// in the room.
  void _submitTurnTimeout(bool isTimeOut) {
    _turnTimer?.cancel();

    setState(() {
      _myHand = [];
      _pallete = [];
      myTurn = false;
      myAllTurn = false;
      youLose = true;
      myPlace = _activePlayers.length;
      _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = _activePlayers.length;
      // Loose
      if (isTimeOut) {
        loosing();
      }
    });

    final message = {
      'type': 'time_out',
      'my_id': userID,
      'my_room': null,
      'my_pallete_ch': null,
      'rule_ch': null,
      'my_hand': null,
      'pallete': null,
    };

    _webSocket.sendMessage(message);
  }

  // Returns the ID of the next player that is active
  int nextPlayerId(int currID) {
    final index = _players.indexOf(_players.firstWhere((p) => p.id == currID));
    int nextIndex = (index + 1) % _players.length;
    while (true) {
      if (_activePlayers.contains(_players[nextIndex].id)) {
        return _players[nextIndex].id;
      } else {
        nextIndex = (nextIndex + 1) % _players.length;
      }
    }
  }

  void _onDisconnected() {}

  @override
  void dispose() {
    _turnTimer?.cancel();
    _webSocket.disconnect();
    super.dispose();
  }

  // Returns the icon for the number of cards
  IconData getNumOfCardsIcon(int numberOfCards) {
    if (numberOfCards == 0) {
      return Icons.filter_none;
    } else if (numberOfCards == 1) {
      return Icons.filter_1;
    } else if (numberOfCards == 2) {
      return Icons.filter_2;
    } else if (numberOfCards == 3){
      return Icons.filter_3;
    } else if (numberOfCards == 4){
      return Icons.filter_4;
    } else if (numberOfCards == 5){
      return Icons.filter_5;
    } else if (numberOfCards == 6){
      return Icons.filter_6;
    } else {
      return Icons.filter_7;
    }
  }

  // Dialog for loosing
  void loosing() {
    showDialog(
      barrierDismissible: false, 
      context: context, 
      builder: (context) {
        return Dialog(
          child: Container(
            width: 427,
            height: 384,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/background.jpg'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: grey3A3A3AColor, width: 0.1),
            ),
            child:
              Container(
                width: 427,
                height: 384,
                decoration: BoxDecoration(
                  color: backInvisColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: grey3A3A3AColor, width: 0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(flex: 1, child: Text(""),), 
                    Text(myPlace == 1 ? Provider.of<GameProvider>(context).localizations!.getString('game_first_place', Provider.of<GameProvider>(context).languageCode)
                        : (myPlace == 2 ? Provider.of<GameProvider>(context).localizations!.getString('game_second_place', Provider.of<GameProvider>(context).languageCode) 
                        : (myPlace == 3 ? Provider.of<GameProvider>(context).localizations!.getString('game_third_place', Provider.of<GameProvider>(context).languageCode)  
                        : Provider.of<GameProvider>(context).localizations!.getString('game_fourth_place', Provider.of<GameProvider>(context).languageCode)  )), style: resLoseStyleBig),
                    Text(Provider.of<GameProvider>(context).localizations!.getString('game_place', Provider.of<GameProvider>(context).languageCode)  , style: resLoseStyle,),
                    Expanded(flex: 1, child: Text(""),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: Provider.of<GameProvider>(context).languageCode == 'en' ? 114 : 122,
                          height: Provider.of<GameProvider>(context).languageCode == 'en' ? 114 : 122,
                          child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                buttonColor,
                              ),
                              textStyle: WidgetStateProperty.all<TextStyle>(
                                buttonTextStyle,
                              ),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                grey3A3A3AColor,
                              ),
                              shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              side: WidgetStateProperty.all<BorderSide>(
                                BorderSide(color: grey3A3A3AColor, width: 1),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Column(
                              children: [
                                const Expanded(flex: 1, child: Text(""),),
                                Icon(Icons.remove_red_eye_outlined, size: 70),
                                const Expanded(flex: 1, child: Text(""),),
                                Text(Provider.of<GameProvider>(context).localizations!.getString('game_spectator', Provider.of<GameProvider>(context).languageCode)  , style: buttonTextStyle, textAlign: TextAlign.center,),
                                const Expanded(flex: 1, child: Text(""),),
                              ],
                            ),
                          ),
                        ),
                        Padding(padding: const EdgeInsets.only(left: 40)),
                        SizedBox(
                          width: Provider.of<GameProvider>(context).languageCode == 'en' ? 114 : 122,
                          height: Provider.of<GameProvider>(context).languageCode == 'en' ? 114 : 122,
                          child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                buttonColor,
                              ),
                              textStyle: WidgetStateProperty.all<TextStyle>(
                                buttonTextStyle,
                              ),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                grey3A3A3AColor,
                              ),
                              shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              side: WidgetStateProperty.all<BorderSide>(
                                BorderSide(color: grey3A3A3AColor, width: 1),
                              ),
                            ),
                            onPressed: () async {
                              _allTimeTimer?.cancel();
                              if (!aiGame) {
                                 await leaveRoom(userID!, roomID!);
                              }
                              for (var timer in timers) {
                                timer.reset();
                              }
                              _turnTimer?.cancel();
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.remove('roomId');
                              await prefs.remove('roomPassword');
                              await prefs.remove('aiGame');
                              await prefs.remove('playerNum');
                              _webSocket.disconnect();
                              Navigator.of(context).pop();
                              Navigator.pushNamed(context, '/mainmenu');
                            },
                            child: Column(
                              children: [
                                const Expanded(flex: 1, child: Text(""),),
                                Icon(Icons.door_back_door_outlined, size: 70),
                                const Expanded(flex: 1, child: Text(""),),
                                Text(Provider.of<GameProvider>(context).localizations!.getString('room_leave', Provider.of<GameProvider>(context).languageCode)  , style: buttonTextStyle, textAlign: TextAlign.center,),
                                const Expanded(flex: 1, child: Text(""),),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(flex: 1, child: Text(""),),
                  ],
                ),
              ),
          )
        );
      }
    );
  }

  // dialog to confirm exit
  void confirmExit() {
    showDialog(
      context: context, 
      builder: (context) {
        return Dialog(
          child: Container(
            width: 468,
            height: 293,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/background.jpg'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: grey3A3A3AColor, width: 0.1),
            ),
            child:
              Container(
                width: 468,
                height: 293,
                decoration: BoxDecoration(
                  color: backInvisColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: grey3A3A3AColor, width: 0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(flex: 1, child: Text(""),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(Provider.of<GameProvider>(context).localizations!.getString('game_confirm_exit', Provider.of<GameProvider>(context).languageCode)  , style: confirmExitStyle, textAlign: TextAlign.center,),
                      ],
                    ),
                    Expanded(flex: 1, child: Text(""),),
                    SizedBox(
                      width: 114,
                      height: 114,
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(
                            buttonColor,
                          ),
                          textStyle: WidgetStateProperty.all<TextStyle>(
                            buttonTextStyle,
                          ),
                          foregroundColor: WidgetStateProperty.all<Color>(
                            grey3A3A3AColor,
                          ),
                          shape:
                            WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          side: WidgetStateProperty.all<BorderSide>(
                            BorderSide(color: grey3A3A3AColor, width: 1),
                          ),
                        ),
                        onPressed: () async {
                          _turnTimer!.cancel();
                          _allTimeTimer?.cancel();
                          exited = true;
                          if (myAllTurn) {
                            _submitTurnTimeout(false);    // При выходе во время своего хода отправляю таймаут
                            // _webSocket.disconnect();   // Если сразу закрываю вебсокет — другие игроки не видят ход и ждут бескоенечно
                          } else {
                            _exit();                      // При выходе вне своего хода. Тут пофиг, оно всегда работает
                          }
                          if (!aiGame) {
                            await leaveRoom(userID!, roomID!);  // выхожу из комнаты через http
                          }
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.remove('roomId');
                          await prefs.remove('roomPassword');
                          await prefs.remove('aiGame');
                          await prefs.remove('playerNum');
                          _webSocket.disconnect();        // Если закрываю вебсокет спустя кучу времени — оно успевает прислать мне всё, что
                                                          // было после моего выхода (как я проиграл и тд), но тут уже у челика могут быть 
                                                          // проблемы с тем, что он в главном меню, а его перекидывает в страничку с результатами 
                                                          // (если это была игра 1 на 1)
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/mainmenu');
                        },
                        child: Column(
                          children: [
                            const Expanded(flex: 1, child: Text(""),),
                            Icon(Icons.door_back_door_outlined, size: 70),
                            const Expanded(flex: 1, child: Text(""),),
                            Text(Provider.of<GameProvider>(context).localizations!.getString('room_leave', Provider.of<GameProvider>(context).languageCode)  , style: buttonTextStyle, textAlign: TextAlign.center,),
                            const Expanded(flex: 1, child: Text(""),),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Text(""),),
                  ],
                ),
              ),
          )
        );
      }
    );
  }

  Future<void> leaveRoom(int id, String room_id) async {
    final url = Uri.parse('$leaveRoomUrl');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
        'assigned_id': room_id,
      })
    );
  }

   void _exit() {
    final message = {
      'type': 'exit',
      'my_id': userID,
    };
    _webSocket.sendMessage(message);
  }

  void goToResults() async{
    List<String> places = [];
    for (int i = 0; i < _players.length; i++) {
      for (int j = 0; j < _players.length; j++) {
        if (_players[j].place == i + 1) {
          places.add(_players[j].name);
        }
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('myPlace', myPlace);
    await prefs.setInt('totalTime', _allTime);
    await prefs.setStringList('placesNames', places);
    Navigator.pushNamed(context, '/result');
  }

  Future<void> _fetchAvatar(int id, String position) async {
    final uri = Uri.parse("$fetchImageUrl$id");

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          if (position == 'left') {
            _downloadedAvatarLeft = Image.memory(response.bodyBytes, fit: BoxFit.cover);
          } else if (position == 'right') {
            _downloadedAvatarRight = Image.memory(response.bodyBytes, fit: BoxFit.cover);
          } else if (position == 'up') {
            _downloadedAvatarUp = Image.memory(response.bodyBytes, fit: BoxFit.cover);
          } else if (position == 'down') {
            _downloadedAvatarDown = Image.memory(response.bodyBytes, fit: BoxFit.cover);
          }
        });
      } else {
        print("Аватар не был загружен до этого");
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }


  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
//--------------------UPBAR----------------------------------------------------------------------------------------------------------
              Padding(padding: const EdgeInsets.only(top: 13)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        confirmExit();                        
                      },
                      icon: const Icon(Icons.door_back_door_outlined, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  if (gamemode == 2 || gamemode == 4)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularCountDownTimer(
                      controller: _countDownControllerUp,
                      duration: 60,
                      isReverse: true,
                      fillColor: greenTimerColor,
                      height: 67,
                      width: 67,
                      strokeWidth: 7,
                      onComplete: () {
                        // later
                      },
                      strokeCap: StrokeCap.round,
                      isReverseAnimation: true,
                      ringColor: ringColorUp,
                      autoStart: false,
                      textStyle: invisTextStyle,
                      ),
                      _downloadedAvatarUp != null
                        ? SizedBox(
                          width: 59,
                          height: 59,
                          child: ClipOval(
                            child: _downloadedAvatarUp
                          ),
                        )
                        : Icon(Icons.account_circle, size: 72, color: grey3A3A3AColor,),
                    ],
                  ),
                  if (gamemode == 2 || gamemode == 4)
                  Padding(padding: const EdgeInsets.only(right: 13),),
                  if (gamemode == 2 || gamemode == 4)
                  Column(
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 36)),
                      Row(
                        children: [
                          Icon(playerUp != null ? getNumOfCardsIcon(playerUp!.numOfCards) : Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text(playerUp?.name ?? gameProvider.localizations!.getString("waiting", gameProvider.languageCode), style: buttonTextStyle),
                        ],
                      )
                    ]
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Padding(padding: const EdgeInsets.only(left: 95)),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 5)),
//--------------------PALLETES----------------------------------------------------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
//--------------------LEFT-PLAYER----------------------------------------------------------------------------------------------------------
                  if (gamemode == 3 || gamemode == 4)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularCountDownTimer(
                          controller: _countDownControllerLeft,
                          duration: 60,
                          isReverse: true,
                          fillColor: greenTimerColor,
                          height: 67,
                          width: 67,
                          strokeWidth: 8,
                          onComplete: () {
                            // later
                          },
                          strokeCap: StrokeCap.round,
                          isReverseAnimation: true,
                          ringColor: ringColorLeft,
                          autoStart: false,
                          textStyle: invisTextStyle,
                          ),
                          _downloadedAvatarLeft != null
                            ? SizedBox(
                              width: 59,
                              height: 59,
                              child: ClipOval(
                                child: _downloadedAvatarLeft
                              ),
                            )
                            : Icon(Icons.account_circle, size: 72, color: grey3A3A3AColor,),
                            ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(playerLeft != null ? getNumOfCardsIcon(playerLeft!.numOfCards) : Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text(playerLeft?.name ?? gameProvider.localizations!.getString("waiting", gameProvider.languageCode), style: buttonTextStyle),
                        ],
                      )
                  ]),
                  if (gamemode == 3 || gamemode == 4)
                  Padding(padding: const EdgeInsets.only(right: 30)),
                  if (gamemode == 3 || gamemode == 4)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 27)),
                      for (int i = 0; i < (playerLeft != null ? playerLeft!.pallete.length : 0); i++)
                        Column(
                          children: [
                            LeftCardWidget(card: playerLeft!.pallete[i]),
                            Padding(padding: const EdgeInsets.only(top: 8)),
                          ],
                        ),
                      for (int i = playerLeft != null ? playerLeft!.pallete.length : 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              height: 54,
                              width: 76,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(top: 8)),
                          ],
                        ),
                      Padding(padding: const EdgeInsets.only(bottom: 19)),
                    ],
                  ),
//--------------------CENTER-PLAYERS----------------------------------------------------------------------------------------------------------
                  Padding(padding: const EdgeInsets.only(right: 44)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (gamemode == 2)
                        Padding(padding: const EdgeInsets.only(top: 18)),
                      if (gamemode == 3)
                        Padding(padding: const EdgeInsets.only(top: 90)),
                      if (gamemode == 2 || gamemode == 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < (playerUp != null ? playerUp!.pallete.length : 0); i++)
                                Row(
                                  children: [
                                    CentralCardWidget(card: playerUp!.pallete[i]),
                                    Padding(padding: const EdgeInsets.only(left: 16)),
                                  ],
                                ),
                          for (int i = playerUp != null ? playerUp!.pallete.length : 0; i < 7; i++)
                            Row(
                              children: [
                                Container(
                                  height: 76,
                                  width: 54,
                                  decoration:  BoxDecoration(
                                    color: invisColor,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(left: 16)),
                              ],
                            )
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 74)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage(gameProvider.languageCode == 'en' ? 'lib/assets/rules_pallete.png' : 'lib/assets/rules_pallete_ru.png'),
                            width: 330,
                            height: 161,
                          ),
                          Padding(padding: const EdgeInsets.only(left: 29)),
                          DragTarget<String>(
                            onWillAcceptWithDetails: (data) {
                              return !ruleChanged;
                            },
                            onAcceptWithDetails: (data) {
                              setState(() {
                                _ruleCard = data.data;
                                ruleChanged = true;
                                _myHand.remove(data.data);
                              });
                            },
                            builder: (context, candidateItems, rejectedItems) {
                              return CentralCardWidget(card: _ruleCard);
                            }
                          ),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 74)),
                      DragTarget<String>(
                        onWillAcceptWithDetails: (data) {
                          return !palleteChanged;
                        },
                        onAcceptWithDetails: (data) {
                          setState(() {
                            _pallete.add(data.data);
                            palleteChanged = true;
                            my_pallete_ch = data.data;
                            _myHand.remove(data.data);
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < _pallete.length; i++)
                                Row(
                                  children: [
                                    CentralCardWidget(card: _pallete[i]),
                                    Padding(padding: const EdgeInsets.only(left: 16)),
                                  ],
                                ),
                              for (int i = _pallete.length; i < 7; i++)
                                Row(
                                  children: [
                                    Container(
                                      height: 76,
                                      width: 54,
                                      decoration:  BoxDecoration(
                                        color: invisColor,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                      ),
                                    ),
                                    Padding(padding: const EdgeInsets.only(left: 16)),
                                  ],
                                )
                            ],
                          );
                        },
                      )
                    ],
                  ),
//--------------------RIGHT-PLAYERS----------------------------------------------------------------------------------------------------------
                  Padding(padding: const EdgeInsets.only(right: 44)),
                  if (gamemode == 3 || gamemode == 4)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 27)),
                      for (int i = 0; i < (playerRight != null ? playerRight!.pallete.length : 0); i++)
                        Column(
                          children: [
                            RightCardWidget(card: playerRight!.pallete[i]),
                            Padding(padding: const EdgeInsets.only(top: 8)),
                          ],
                        ),
                      for (int i = playerRight != null ? playerRight!.pallete.length : 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              height: 54,
                              width: 76,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(top: 8)),
                          ],
                        ),
                      Padding(padding: const EdgeInsets.only(bottom: 19)),
                    ],
                  ),
                  if (gamemode == 3 || gamemode == 4)
                  Padding(padding: const EdgeInsets.only(right: 30)),
                  if (gamemode == 3 || gamemode == 4)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularCountDownTimer(
                          controller: _countDownControllerRight,
                          duration: 60,
                          isReverse: true,
                          fillColor: greenTimerColor,
                          height: 67,
                          width: 67,
                          strokeWidth: 7,
                          onComplete: () {
                            // later
                          },
                          strokeCap: StrokeCap.round,
                          isReverseAnimation: true,
                          ringColor: ringColorRight,
                          autoStart: false,
                          textStyle: invisTextStyle,
                          ),
                          _downloadedAvatarRight != null
                            ? SizedBox(
                              width: 59,
                              height: 59,
                              child: ClipOval(
                                child: _downloadedAvatarRight
                              ),
                            )
                            : Icon(Icons.account_circle, size: 72, color: grey3A3A3AColor,),
                            ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(playerRight != null ? getNumOfCardsIcon(playerRight!.numOfCards) : Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text(playerRight?.name ?? gameProvider.localizations!.getString("waiting", gameProvider.languageCode), style: buttonTextStyle),
                        ],
                      )
                  ]),
                ],
              ),
//--------------------HAND----------------------------------------------------------------------------------------------------------
              // Expanded(flex: 1, child: Text("")),
              Padding(padding: const EdgeInsets.only(top: 10)),
              Expanded(
                // flex: 17,
                child: Container(
                  height: 155,
                  decoration:  BoxDecoration(
                    color: handInvisColor,
                  ),
                  child: Column(
                    children: [
                      Expanded(flex: 1, child: Text("")),
                      Expanded(
                        flex: 7,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(padding: const EdgeInsets.only(right: 55), child: Text(""),),
                            Expanded(flex: 1, child: Text("")),
                            Column(
                              children: [
                                Padding(padding: const EdgeInsets.only(top: 10)),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularCountDownTimer(
                                    controller: _countDownControllerDown,
                                    duration: myTimerDuration,
                                    isReverse: true,
                                    fillColor: MyTimerColor,
                                    height: 67,
                                    width: 67,
                                    strokeWidth: 7,
                                    onComplete: () {
                                      // later
                                    },
                                    strokeCap: StrokeCap.round,
                                    isReverseAnimation: isReverseAnimationDown,
                                    ringColor: ringColorDown,
                                    autoStart: false,
                                    textStyle: invisTextStyle,
                                    ),
                                    _downloadedAvatarDown != null
                                      ? SizedBox(
                                        width: 59,
                                        height: 59,
                                        child: ClipOval(
                                          child: _downloadedAvatarDown
                                        ),
                                      )
                                      : Icon(Icons.account_circle, size: 72, color: grey3A3A3AColor,),
                                  ],
                                ),
                              ],
                            ),
                            Padding(padding: const EdgeInsets.only(left: 29)),
                            for (int i = 0; i < _myHand.length; i++)
                              Row(
                                children: [
                                  Draggable<String>(
                                    data: _myHand[i],
                                    feedback: CentralCardWidget(card: _myHand[i]),
                                    childWhenDragging: Container(
                                      height: 95,
                                      width: 64,
                                      decoration:  BoxDecoration(
                                        color: invisColor,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                      ),
                                    ),
                                    child: HandCardWidget(card: _myHand[i]),
                                  ),
                                  Padding(padding: const EdgeInsets.only(left: 16)),
                                ],
                              ),
                            for (int i = _myHand.length; i < 7; i++)
                              Row(
                                children: [
                                  Container(
                                    height: 95,
                                    width: 64,
                                    decoration:  BoxDecoration(
                                      color: invisColor,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                    ),
                                  ),
                                  Padding(padding: const EdgeInsets.only(left: 16)),
                                ],
                              ),
                            Padding(padding: const EdgeInsets.only(left: 11)),
                            if (myAllTurn)
                              Column(
                                children: [
                                  Padding(padding: const EdgeInsets.only(top: 20)),
                                  SizedBox(
                                    width: 115,
                                    height: 50,
                                    child: 
                                    ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all<Color>(myTurn ? buttonColor : greyButtonColor),
                                        textStyle: WidgetStateProperty.all<TextStyle>(myTurn ? buttonTextStyle : buttonWhiteTextStyle),
                                        foregroundColor: WidgetStateProperty.all<Color>(myTurn ? grey3A3A3AColor : Colors.white),
                                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),),),
                                        side: WidgetStateProperty.all<BorderSide>(BorderSide(color: grey3A3A3AColor, width: 1),),
                                      ),
                                      onPressed: () {
                                        if (myAllTurn && myTurn) {
                                          _submitTurn();
                                        }
                                      },
                                    child: Text(
                                      gameProvider.localizations!.getString("game_submit", gameProvider.languageCode),),
                                    ),
                                  ),
                                ],
                              )
                            else 
                              Column(
                                children: [
                                  SizedBox(
                                    height: 115,
                                    width: 50,
                                    child: Text(''),
                                  ),
                                ],
                              ),
                            Expanded(flex: 1, child: Text("")),
                            IconButton(
                              icon: Icon(Icons.help_outline, size: 40, color: grey3A3A3AColor,),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => RuleDialog(),
                                );
                              },
                            ),
                            Padding(padding: const EdgeInsets.only(right: 15), child: Text(""),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

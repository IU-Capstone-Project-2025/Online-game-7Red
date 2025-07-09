import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../data/styles.dart';
import '../providers/provider.dart';
import '../customWidgets/cards.dart';
import '../socket/web_socket.dart';
import '../data/player.dart';
import '../data/urls.dart';
import '../customWidgets/ruleDialog.dart';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

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

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  void _connectToWebSocket() async{
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      roomID = await prefs.getString('roomId');
      userID = await prefs.getInt('myID');
      aiGame = await prefs.getBool('aiGame') ?? false;
      gamemode = aiGame ? 2 : await prefs.getInt('playerNum') ?? 2; //⭐️
      if (aiGame) {
        serverUrl = '$serverUrlPartUrl/ai_game/$userID';
      } else {
        serverUrl = '$serverUrlPartUrl/game/$roomID/ws?player_id=$userID';
      }
      print(serverUrl);
      _webSocket = GameWebSocket(
        serverUrl: serverUrl,
        onMessageReceived: _handleMessage,
        onConnectionClosed: _onDisconnected,
      );
      _webSocket.connect();
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка подключения: $e')),
    );
  }
  }

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
        _handleChangeTurn(message);
        break;
    }
  }

  void _handleInitialized(Map<String, dynamic> message) {
    setState(() {
      _myHand = List<String>.from(message['my_hand']);
      _players = List.generate(
        message['names'].length,
        (index) => Player(
          id: message['id'][index],
          name: message['names'][index],
          isMe: message['id'][index] == userID,
        ),
      );
      _activePlayers = message['id'];
      _currentPlayerId = message['id'][0];


      final player = _players.firstWhere((p) => p.id == _activePlayers[0]);
      
      if (player.isMe) {
        myTurn = true;
        palleteChanged = false;
        ruleChanged = false;
        my_pallete_ch = "";
        myAllTurn = true;
      }
      
      if (gamemode == 2) {
        if (_players.length == 1) {
          playerUp = player;
        } else {
          if (player.isMe == false ) {
            playerUp = player;
            timers = [_countDownControllerDown, _countDownControllerUp];
          } else {
            playerUp = _players.firstWhere((p) => p.id == _activePlayers[1]);
            timers = [_countDownControllerUp, _countDownControllerDown];
          }
        }
      } else if (gamemode == 3) {
        final myIndex = _players.indexOf(_players.firstWhere((p) => p.id == userID));
        playerRight = _players[(myIndex + 1) % _players.length];
        playerLeft = _players[(myIndex + 2) % _players.length];
        timers = [_countDownControllerDown, _countDownControllerDown, _countDownControllerDown,];
        timers[(myIndex + 1) % _players.length] = _countDownControllerDown;
        timers[(myIndex + 2) % _players.length] = _countDownControllerRight;
        timers[(myIndex + 3) % _players.length] = _countDownControllerLeft;
      } else if (gamemode == 4) {
        final myIndex = _players.indexOf(_players.firstWhere((p) => p.id == userID));
        playerRight = _players[(myIndex + 1) % _players.length];
        playerUp = _players[(myIndex + 2) % _players.length];
        playerLeft = _players[(myIndex + 3) % _players.length];
        timers = [_countDownControllerDown, _countDownControllerDown, _countDownControllerDown, _countDownControllerDown];
        timers[(myIndex + 1) % _players.length] = _countDownControllerDown;
        timers[(myIndex + 2) % _players.length] = _countDownControllerRight;
        timers[(myIndex + 3) % _players.length] = _countDownControllerUp;
        timers[(myIndex + 4) % _players.length] = _countDownControllerLeft;
      }
      
      _allTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _allTime++;
      });
      _startTurnTimer();
    });
  }

  void _handleWrongTurn(Map<String, dynamic> message) {
    setState(() {
      if (message['my_pallete_ch'] != null) {
        _pallete.remove(message['my_pallete_ch']);
        _myHand.add(message['my_pallete_ch']);
      }
      if (message['rule_ch'] != null) {
        _myHand.add(message['rule_ch']);
      }
      _ruleCard = message['old_rule'];
      myTurn = true;
      palleteChanged = false;
      ruleChanged = false;
      myAllTurn = true;
    });
  }

  void _handleRightTurn() {
    _turnTimer?.cancel();
    setState(() {
      myTurn = false;
      ruleChanged = true;
      palleteChanged = true;
      myAllTurn = false;
    });
  }

  void _handleChangeTurn(Map<String, dynamic> message) {
    setState(() {
      final player = _players.firstWhere((p) => p.id == message['id_did']);

      if (message['lose'] == 1) {
        if (gamemode == 2) {
          if (player.id == playerUp!.id) {
            playerUp!.pallete = [];
          }
        } else if (gamemode == 3) {
          if (player.id == playerRight!.id) {
            playerRight!.pallete = [];
          } else if (player.id == playerLeft!.id) {
            playerLeft!.pallete = [];
          }
        } else if (gamemode == 4) {
          if (player.id == playerRight!.id) {
            playerRight!.pallete = [];
          } else if (player.id == playerUp!.id) {
            playerUp!.pallete = [];
          } else if (player.id == playerLeft!.id) {
            playerLeft!.pallete = [];
          }
        }
        _players[_players.indexOf(player)].place = _activePlayers.length;
        _activePlayers.remove(message['id_did']);
        timersDied.add(timers[_players.indexOf(player) + 1]);
      } else {
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
      _nextLose = message['next_lose'];
      _currentPlayerId = nextPlayerId(_currentPlayerId);

      if (_activePlayers.length == 1) {
        _turnTimer?.cancel();
        // youLose = false;
        // _pallete = [];
        // _myHand = [];
        for (var timer in timers) {
          timer.reset();
        }
        _allTimeTimer?.cancel();
        if (youLose == false) {
          myPlace = 1;
        }
        _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = 1;
        // Win
        goToResults();
        return;
      }

      if (_players.firstWhere((p) => p.id == _currentPlayerId).isMe) {
        if (_nextLose == 1) {
          _turnTimer?.cancel();
          _pallete = [];
          _myHand = [];
          youLose = true;
          // for (var timer in timers) {
          //   timer.reset();
          // }
          // _allTimeTimer?.cancel();
          myPlace = _activePlayers.length;
          _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = _activePlayers.length;
          // Loose
          loosing();
          return;
          
        }
        myTurn = true;
        palleteChanged = false;
        ruleChanged = false;
        my_pallete_ch = "";
        myAllTurn = true;
      }
      
      _startTurnTimer();
    });
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    nextTimer();
    if (!youLose) {
      setState(() => _timeLeft = 60);
      _turnTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          timer.cancel();
          if (myAllTurn) {
            _submitTurnTimeout();
          }
        }
      });
    }
  }

  void nextTimer() {
    timers[currTimerIndex].reset();
    currTimerIndex = (currTimerIndex + 1) % timers.length;
    if (timers.length != timersDied.length) {
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

  void _submitTurn() {
    // _turnTimer?.cancel();

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

  void _submitTurnTimeout() {
    _turnTimer?.cancel();

    setState(() {
      _myHand = [];
      _pallete = [];
      myTurn = false;
      myAllTurn = false;
      youLose = true;
      // for (var timer in timers) {
      //   timer.reset();
      // }
      // _allTimeTimer?.cancel();
      myPlace = _activePlayers.length;
      _players[_players.indexOf(_players.firstWhere((p) => p.id == _currentPlayerId))].place = _activePlayers.length;
      // Loose
      loosing();
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

  void _onDisconnected() {
    // Обработка разрыва соединения
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Соединение с сервером потеряно')),
    // );
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _webSocket.disconnect();
    super.dispose();
  }

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
                    Text(myPlace == 1 ? "1st" : (myPlace == 2 ? "2nd" : (myPlace == 3 ? "3rd" : "4th") ), style: resLoseStyleBig),
                    Text("place", style: resLoseStyle,),
                    Expanded(flex: 1, child: Text(""),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Column(
                              children: [
                                const Expanded(flex: 1, child: Text(""),),
                                Icon(Icons.remove_red_eye_outlined, size: 70),
                                const Expanded(flex: 1, child: Text(""),),
                                Text("Spectator", style: buttonTextStyle, textAlign: TextAlign.center,),
                                const Expanded(flex: 1, child: Text(""),),
                              ],
                            ),
                          ),
                        ),
                        Padding(padding: const EdgeInsets.only(left: 40)),
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
                                Text("Leave the room", style: buttonTextStyle, textAlign: TextAlign.center,),
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
                        Text("Are you sure you want to exit?\nYou will not be able to return to\nthe game", style: confirmExitStyle, textAlign: TextAlign.center,),
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
                          if (myAllTurn) {
                            _submitTurnTimeout();
                          } else {
                            _exit();
                          }
                          if (!aiGame) {
                            await leaveRoom(userID!, roomID!);
                          }
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
                            Text("Leave the room", style: buttonTextStyle, textAlign: TextAlign.center,),
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
    final response = await http.post(
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
              Padding(padding: const EdgeInsets.only(top: 15)),
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
                      height: 74,
                      width: 74,
                      strokeWidth: 8,
                      onComplete: () {
                        // later
                      },
                      strokeCap: StrokeCap.round,
                      isReverseAnimation: true,
                      ringColor: greyTimerColor,
                      autoStart: false,
                      textStyle: invisTextStyle,
                      ),
                      Icon(Icons.account_circle, size: 80, color: grey3A3A3AColor,),
                    ],
                  ),
                  if (gamemode == 2 || gamemode == 4)
                  Padding(padding: const EdgeInsets.only(right: 15),),
                  if (gamemode == 2 || gamemode == 4)
                  Column(
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 40)),
                      Row(
                        children: [
                          Icon(playerUp != null ? getNumOfCardsIcon(playerUp!.numOfCards) : Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text(playerUp?.name ?? "Waiting...", style: buttonTextStyle),
                        ],
                      )
                    ]
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Padding(padding: const EdgeInsets.only(left: 95)),
                ],
              ),
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
                          height: 74,
                          width: 74,
                          strokeWidth: 8,
                          onComplete: () {
                            // later
                          },
                          strokeCap: StrokeCap.round,
                          isReverseAnimation: true,
                          ringColor: greyTimerColor,
                          autoStart: false,
                          textStyle: invisTextStyle,
                          ),
                          Icon(Icons.account_circle, size: 80, color: grey3A3A3AColor,),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(playerLeft != null ? getNumOfCardsIcon(playerLeft!.numOfCards) : Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text(playerLeft?.name ?? "Waiting...", style: buttonTextStyle),
                        ],
                      )
                  ]),
                  if (gamemode == 3 || gamemode == 4)
                  Padding(padding: const EdgeInsets.only(right: 30)),
                  if (gamemode == 3 || gamemode == 4)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 30)),
                      for (int i = 0; i < (playerLeft != null ? playerLeft!.pallete.length : 0); i++)
                        Column(
                          children: [
                            LeftCardWidget(card: playerLeft!.pallete[i]),
                            Padding(padding: const EdgeInsets.only(top: 9)),
                          ],
                        ),
                      for (int i = playerLeft != null ? playerLeft!.pallete.length : 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              height: 60,
                              width: 84,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(top: 9)),
                          ],
                        ),
                      Padding(padding: const EdgeInsets.only(bottom: 21)),
                    ],
                  ),
//--------------------CENTER-PLAYERS----------------------------------------------------------------------------------------------------------
                  Padding(padding: const EdgeInsets.only(right: 44)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (gamemode == 2)
                        Padding(padding: const EdgeInsets.only(top: 20)),
                      if (gamemode == 3)
                        Padding(padding: const EdgeInsets.only(top: 100)),
                      if (gamemode == 2 || gamemode == 4)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < (playerUp != null ? playerUp!.pallete.length : 0); i++)
                                Row(
                                  children: [
                                    CentralCardWidget(card: playerUp!.pallete[i]),
                                    Padding(padding: const EdgeInsets.only(left: 18)),
                                  ],
                                ),
                          for (int i = playerUp != null ? playerUp!.pallete.length : 0; i < 7; i++)
                            Row(
                              children: [
                                Container(
                                  height: 84,
                                  width: 60,
                                  decoration:  BoxDecoration(
                                    color: invisColor,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(left: 18)),
                              ],
                            )
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 75)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('lib/assets/rules_pallete.png'),
                            width: 345,
                            height: 179,
                          ),
                          Padding(padding: const EdgeInsets.only(left: 32)),
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
                      Padding(padding: const EdgeInsets.only(top: 75)),
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
                                    Padding(padding: const EdgeInsets.only(left: 18)),
                                  ],
                                ),
                              for (int i = _pallete.length; i < 7; i++)
                                Row(
                                  children: [
                                    Container(
                                      height: 84,
                                      width: 60,
                                      decoration:  BoxDecoration(
                                        color: invisColor,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                      ),
                                    ),
                                    Padding(padding: const EdgeInsets.only(left: 18)),
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
                      Padding(padding: const EdgeInsets.only(top: 30)),
                      for (int i = 0; i < (playerRight != null ? playerRight!.pallete.length : 0); i++)
                        Column(
                          children: [
                            RightCardWidget(card: playerRight!.pallete[i]),
                            Padding(padding: const EdgeInsets.only(top: 9)),
                          ],
                        ),
                      for (int i = playerRight != null ? playerRight!.pallete.length : 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              height: 60,
                              width: 84,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(top: 9)),
                          ],
                        ),
                      Padding(padding: const EdgeInsets.only(bottom: 21)),
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
                          height: 74,
                          width: 74,
                          strokeWidth: 8,
                          onComplete: () {
                            // later
                          },
                          strokeCap: StrokeCap.round,
                          isReverseAnimation: true,
                          ringColor: greyTimerColor,
                          autoStart: false,
                          textStyle: invisTextStyle,
                          ),
                          Icon(Icons.account_circle, size: 80, color: grey3A3A3AColor,),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(playerRight != null ? getNumOfCardsIcon(playerRight!.numOfCards) : Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text(playerRight?.name ?? "Waiting...", style: buttonTextStyle),
                        ],
                      )
                  ]),
                ],
              ),
//--------------------HAND----------------------------------------------------------------------------------------------------------
              Expanded(flex: 1, child: Text("")),
              Container(
                height: 155,
                decoration:  BoxDecoration(
                  color: handInvisColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(flex: 1, child: Text("")),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularCountDownTimer(
                        controller: _countDownControllerDown,
                        duration: 60,
                        isReverse: true,
                        fillColor: greenTimerColor,
                        height: 74,
                        width: 74,
                        strokeWidth: 8,
                        onComplete: () {
                          // later
                        },
                        strokeCap: StrokeCap.round,
                        isReverseAnimation: true,
                        ringColor: greyTimerColor,
                        autoStart: false,
                        textStyle: invisTextStyle,
                        ),
                        Icon(Icons.account_circle, size: 80, color: grey3A3A3AColor,),
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
                              height: 106,
                              width: 71,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            child: HandCardWidget(card: _myHand[i]),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 18)),
                        ],
                      ),
                    for (int i = _myHand.length; i < 7; i++)
                      Row(
                        children: [
                          Container(
                            height: 106,
                            width: 71,
                            decoration:  BoxDecoration(
                              color: invisColor,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: grey3A3A3AColor, width: 1.5),
                            ),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 18)),
                        ],
                      ),
                    Padding(padding: const EdgeInsets.only(left: 11)),
                    if (myAllTurn)
                      SizedBox(
                        width: 105,
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
                        child: Text('SUBMIT'),
                        ),
                      )
                    else 
                      SizedBox(
                        height: 105,
                        width: 50,
                        child: Text(''),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}

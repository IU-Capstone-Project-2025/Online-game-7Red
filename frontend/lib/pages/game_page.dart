import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles.dart';
import '../providers/provider.dart';
import '../data/cards.dart';
import '../socket/web_socket.dart';
import '../data/player.dart';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  String? roomID;
  int? userID;
  String serverUrl = '?';

  int gamemode = 2;

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

  bool myTurn = false;
  bool myAllTurn = false;
  bool ruleChanged = true;
  bool palleteChanged = true;

  // List<String> myPallete = ["R7", "O6", "Y5", "G4", "B3"];
  // List<String> myHand = ["G4", "B3", "I2", "V1"];
  // String currRuleCard = "R0";
  

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  void _connectToWebSocket() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roomID = await prefs.getString('roomId');
    userID = await prefs.getInt('myID');
    serverUrl = 'ws://localhost:8000/game/$roomID/ws?player_id=$userID';
    _webSocket = GameWebSocket(
      serverUrl: serverUrl,
      onMessageReceived: _handleMessage,
      onConnectionClosed: _onDisconnected,
    );
    _webSocket.connect();
  }

  void _handleMessage(dynamic message) {  //мб тут не так будет соо отправляться (не то передаю)
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
          } else {
            playerUp = _players.firstWhere((p) => p.id == _activePlayers[1]);
          }
        }
      }
      
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
    });
  }

  void _handleRightTurn() {
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
        }
        _activePlayers.remove(message['id_did']);
        if (_activePlayers.length == 1) {
          // TODO: Закончить игру с победой
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Вы победили!')),
          );
        }
      } else {
        if (message['his_pallete_ch'] != null) {
          if (gamemode == 2) {
            if (player.id == playerUp!.id) {
              playerUp!.pallete.add(message['his_pallete_ch']);
            }
          }
        }
      }
      if (message['rule_ch'] != null) {
        _ruleCard = message['rule_ch'];
      }
      _nextLose = message['next_lose'];
      _currentPlayerId = nextPlayerId(_currentPlayerId);
      if (_players.firstWhere((p) => p.id == _currentPlayerId).isMe) {
        if (_nextLose == 1) {
          //TODO: Закончить игру c поражением
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Вы проиграли!')),
          );
          _pallete = [];
          _myHand = [];
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
    setState(() => _timeLeft = 60);
    _turnTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        if (myTurn) {
          _submitTurnTimeout();
        }
      }
    });
  }

  void _submitTurn() {
    _turnTimer?.cancel();

    setState(() {
      myTurn = false;
    });

    final message = {
      'type': 'my_turn',
      'my_id': userID,
      'my_room': roomID,
      'my_pallete_ch': palleteChanged ? my_pallete_ch : null,
      'rule_ch': ruleChanged ? _ruleCard : null,
      'my_hand': _myHand,
      'pallete': _pallete,
    };

    _webSocket.sendMessage(message);
  }

  void _submitTurnTimeout() {
    _turnTimer?.cancel();

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

    setState(() {
      _myHand = [];
      _pallete = [];
      myTurn = false;
      //TODO: выйти из игры
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Время вышло, вы проиграли!')),
      );
    });
  }

  int nextPlayerId(int currID) {
    final index = _activePlayers.indexOf(currID);
    return _activePlayers[(index + 1) % _activePlayers.length];
  }

  void _onDisconnected() {
    // Обработка разрыва соединения
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Соединение с сервером потеряно')),
    );
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _webSocket.disconnect();
    super.dispose();
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
                        // do alert
                        // send http-request
                        // delete data
                        // pass to main menu
                        Navigator.pushNamed(context, '/mainmenu');
                      },
                      icon: const Icon(Icons.door_back_door_outlined, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                  ),
                  Padding(padding: const EdgeInsets.only(right: 15),),
                  Column(
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 40)),
                      Row(
                        children: [
                          Icon(Icons.filter_7, size: 24, color: grey3A3A3AColor,),
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
                      Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text("Player_123", style: buttonTextStyle),
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
                      for (int i = 0; i < 7; i++)
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
                      for (int i = 0; i < 7; i++)
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
                      Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text("Player_XXX", style: buttonTextStyle),
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
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
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
                    SizedBox(
                      width: 100,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(myAllTurn ? (myTurn ? buttonColor : greyButtonColor) : invisColor,),
                          textStyle: WidgetStateProperty.all<TextStyle>(myAllTurn ? (myTurn ? buttonTextStyle : buttonWhiteTextStyle)  : buttonInvisTextStyle),
                          foregroundColor: WidgetStateProperty.all<Color>(myAllTurn ? (myTurn ? grey3A3A3AColor : Colors.white) : invisColor,),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),),),
                          side: WidgetStateProperty.all<BorderSide>(BorderSide(color: myAllTurn ?  grey3A3A3AColor : invisColor, width: 1),),
                        ),
                        onPressed: () {
                          if (myAllTurn && myTurn) {
                            _submitTurn();
                          }
                        },
                      child: Text('SUBMIT'),
                      ),
                    ),
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

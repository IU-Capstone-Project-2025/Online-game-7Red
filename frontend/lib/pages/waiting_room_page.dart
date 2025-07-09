import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles.dart';
import 'package:frontend/providers/provider.dart';
import '../data/urls.dart';


class WaitingRoomPage extends StatefulWidget {
  const WaitingRoomPage({super.key});

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {

  bool logSuccess = false;

  String room_id = '';
  String room_password = '';

  Future<String> assigned_room = Future.value('');

  List<String> players = [];
  List<String> ready_players = [];

  Timer? _pollingTimer;

  bool ready = false;

  @override
  void initState() {
    super.initState();
    // For the first time
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Function for polling backend for room state (what players are in the room, they are ready or not)
  void _startPolling() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // await assigned_room = Future.value(prefs.getString('roomId') ?? '00000');
    room_id = prefs.getString('roomId') ?? '00000';
    ready = prefs.getBool('ready') ?? false;

    await _fetchPlayers();
    
    // Затем повторяем каждые 2 секунды
    _pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) async{
      _fetchPlayers();
    });
  }

/// Fetches the list of players and their ready status from the server for the current room.
/// 
/// Sends a POST request to retrieve the room state. If successful, updates the `players`
/// and `ready_players` lists based on the response. If all players are ready and there are
/// at least two players, navigates to the game room and cancels the polling timer.
  Future<void> _fetchPlayers() async {
    final url = Uri.parse('$roomStateUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'assigned_id': room_id,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      setState(() async {
        players = List<String>.from(responseBody['players']);
        ready_players = List<String>.from(responseBody['ready_players']);
        // Check if all players are ready and there are at least two players to navigate to the game room
        if (ready_players.length == players.length && ready_players.length >= 2) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('ready');
          await prefs.setInt('playerNum', ready_players.length);
          Navigator.pushNamed(context, '/gameroom');
          _pollingTimer?.cancel();
        }
      });
    } else {
      setState(() {
        players = [];
        ready_players = [];
      });
    }
  }

  /// Sends a request to the server to mark the player as ready in the waiting room.
  ///
  /// If the request is successful (200 or 201), sets `logSuccess` to true and `ready`
  /// to true. Otherwise, sets them to false.
  Future<void> sendReady(int my_id, String room_id) async {
    final url = Uri.parse('$roomReadyUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': my_id,
        'assigned_id': room_id,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        logSuccess = true;
        ready = true;
      });
    } else {
      setState(() {
        ready = false;
        logSuccess = false;
      });
    }
  }

  /// Sends a request to the server to mark the player as not ready in the waiting room.
  ///
  /// If the request is successful (200 or 201), sets `logSuccess` to true and `ready`
  /// to false. Otherwise, sets them to false.
  Future<void> sendNotReady(int my_id, String room_id) async {
    final url = Uri.parse('$roomNotReadyUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': my_id,
        'assigned_id': room_id,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        logSuccess = true;
        ready = false;
      });
    } else {
      setState(() {
        ready = true;
        logSuccess = false;
      });
    }
  }

  /// Sends a request to the server to leave a game room.
  ///
  /// If the request is successful (200), sets `logSuccess` to true. Otherwise,
  /// sets it to false.
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

    if (response.statusCode == 200) {
      setState(() {
        logSuccess = true;
      });
    } else {
      setState(() {
        logSuccess = false;
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    // Load the room information from the provider
    gameProvider.loadRoomInfo();

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
              Padding(padding: const EdgeInsets.only(top: 15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  // Button to return to MainMenuPage and leave the room
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () async {
                        setState(() {
                          logSuccess = false;
                        });
                        // Send http-request to the Backend to leave the room
                        await leaveRoom(gameProvider.myID, gameProvider.roomId);
                        // If the http-request was successful, navigate to MainMenuPage
                        if (logSuccess) {
                          gameProvider.clearRoomInfo();
                          gameProvider.clearReady();
                          Navigator.pushNamed(context, '/mainmenu');
                          _pollingTimer?.cancel();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                ],
              ),
              // Display the room information
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    image: AssetImage('lib/assets/logo.png'),
                    width: 160,
                    height: 160,
                  ),
                  Padding(padding: const EdgeInsets.only(left: 35)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Room", style: boldTextStyle),
                      SelectableText(room_id, style: bigNumberStyle),
                      Padding(padding: const EdgeInsets.only(top: 10)),
                      Text("Password", style: boldTextStyle),
                      SelectableText(gameProvider.roomPassword, style: bigNumberStyle),
                    ],
                  )
                ],
              ),
              const Expanded(flex: 1, child: Text("")),
              // Display the players in the room
              for (int i = 0; i < players.length; i++)
                Column(
                  children: [
                    Container(
                      width: 350,
                      height: 65,
                      decoration:  BoxDecoration(
                        color: whiteInvisColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                      child: Row(
                        children: [
                          Padding(padding: const EdgeInsets.only(left: 20)),
                          Icon(Icons.account_circle, size: 50),
                          Padding(padding: const EdgeInsets.only(left: 20)),
                          Text(players[i], style: basicTextStyle),
                          Expanded(flex: 1, child: Text("")),
                          ready_players.contains(players[i]) ? Icon(Icons.check_rounded, color: Colors.green, size: 50) : Text(""),
                          Padding(padding: const EdgeInsets.only(right: 20)),
                        ]
                      )
                    ),
                    Padding(padding: const EdgeInsets.only(top: 20)),
                  ],
                ),
              // Display empty containers for places of players that are not in the room
              for (int i = players.length; i < 4; i++)
                Column(
                  children: [
                    Container(
                      width: 350,
                      height: 65,
                      decoration:  BoxDecoration(
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: whiteInvisColor, width: 3.5),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 20)),
                ]),
              const Expanded(flex: 1, child: Text("")),
              // Button to get ready/unready
              SizedBox(
                width: 315,
                height: 65,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(ready ? cancelRedButtonColor : buttonColor),
                    textStyle: WidgetStateProperty.all<TextStyle>(buttonTextStyleBig,),
                    foregroundColor: WidgetStateProperty.all<Color>(grey3A3A3AColor,),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),),
                    side: WidgetStateProperty.all<BorderSide>(BorderSide(color: grey3A3A3AColor, width: 1),),
                  ),
                  onPressed: () async{
                    // Reset logSuccess
                    setState(() {
                      logSuccess = false;
                    });
                    if (!ready) {
                      // Send http-request to the Backend to get ready
                      await sendReady(gameProvider.myID, gameProvider.roomId);
                    } else {
                      // Send http-request to the Backend to unready
                      await sendNotReady(gameProvider.myID, gameProvider.roomId);
                    }
                    // If the http-request was successful, update the ready state
                    if (logSuccess) {
                      setState(() {
                        gameProvider.ready = ready;
                      });
                      gameProvider.saveReady();
                      
                    }
                },
                child: ready ? const Text('UNREADY') : const Text('GET READY'),
                ),
              ),
              const Expanded(flex: 3, child: Text("")),
            ],
          ),
        ),
      ),
    );
  }
}

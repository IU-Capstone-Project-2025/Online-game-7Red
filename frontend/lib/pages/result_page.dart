import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles.dart';
import '../data/urls.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool aiGame = false;
  List<String>? placesNames;
  int? totalTime;
  int? myPlace;
  int? userID;
  String? roomID;


  @override
  void initState() {
    super.initState();
    // Get results of the game from GamePage
    getData();
  }

  // Function to get results of the game from GamePage
  void getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    aiGame = await prefs.getBool('aiGame') ?? false;
    placesNames = await prefs.getStringList('placesNames') ?? [];
    totalTime = await prefs.getInt('totalTime') ?? 0;
    myPlace = await prefs.getInt('myPlace') ?? 0;
    userID = await prefs.getInt('myID');
    roomID = await prefs.getString('roomId');
    setState(() {});
  }

  // Function to leave the room
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

  // Function to format time in minutes and seconds
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(flex: 3, child: Text("")),
              // Winner's place for first 3 places
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (placesNames != null)
                        if (placesNames!.length > 2)
                          Icon(Icons.account_circle, size: 48, color: grey3A3A3AColor,),
                      Text(placesNames != null ? (placesNames!.length > 2 ? placesNames![2] : "") : "Loading...", style: basicTextStyle,),
                      Padding(padding: const EdgeInsets.only(top: 10)),
                      Container(
                        width: 90,
                        height: 60,
                        decoration: BoxDecoration(
                          color: whiteInvisColor,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.only(left: 20)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.account_circle, size: 48, color: grey3A3A3AColor,),
                      Text(placesNames != null ? placesNames![0] : "Loading...", style: basicTextStyle,),
                      Padding(padding: const EdgeInsets.only(top: 10)),
                      Container(
                        width: 90,
                        height: 180,
                        decoration: BoxDecoration(
                          color: whiteInvisColor,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.only(left: 20)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.account_circle, size: 48, color: grey3A3A3AColor,),
                      Text(placesNames != null ? placesNames![1] : "Loading...", style: basicTextStyle,),
                      Padding(padding: const EdgeInsets.only(top: 10)),
                      Container(
                        width: 90,
                        height: 120,
                        decoration: BoxDecoration(
                          color: whiteInvisColor,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                    ],
                  ),
                ]
              ),
              Expanded(flex: 1, child: Text("")),
              // Container with player's actual place and all time of the game
              Container(
                width: 370,
                height: 90,
                decoration: BoxDecoration(
                  color: whiteInvisColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: grey3A3A3AColor, width: 2),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(flex: 1, child: Text("")),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Place", style: resLitleStyle,),
                          Text(myPlace.toString() ?? "Loading...", style: resBigStyle,)
                        ],
                      ),
                      Expanded(flex: 2, child: Text("")),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Time", style: resLitleStyle,),
                          Text(formatTime(totalTime!) ?? "Loading...", style: resBigStyle,)
                        ],
                      ),
                      Expanded(flex: 1, child: Text("")),
                    ],
                  )
                ),
              ),
              Expanded(flex: 2, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        side: WidgetStateProperty.all<BorderSide>(
                          BorderSide(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                      onPressed: () async{
                        // Play again function 
                      },
                      child: Column(
                        children: [
                          const Expanded(flex: 1, child: Text(""),),
                          Icon(Icons.refresh, size: 70),
                          const Expanded(flex: 1, child: Text(""),),
                          Text("Play again", style: buttonTextStyle, textAlign: TextAlign.center,),
                          const Expanded(flex: 1, child: Text(""),),
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 40)),
                  SizedBox(
                    width: 118,
                    height: 118,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        side: WidgetStateProperty.all<BorderSide>(
                          BorderSide(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                      onPressed: () async{
                        // Leave the room with deleting all data about this room
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        if (!aiGame) {
                          await leaveRoom(userID!, roomID!);
                        }
                        await prefs.remove('aiGame');
                        await prefs.remove('playerNum');
                        await prefs.remove('roomId');
                        await prefs.remove('roomPassword');
                        await prefs.remove('myPlace');
                        await prefs.remove('totalTime');
                        await prefs.remove('placesNames');
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
              Expanded(flex: 4, child: Text("")),
            ],
          ),
        ),
      ),
    );
  }
}
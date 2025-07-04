import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../data/styles.dart';
import '../providers/provider.dart';
import '../customWidgets/connectDialog.dart';
import '../data/urls.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  String postText = '';
  bool logSuccess = false;
  String nickname = '';
  int ID = -1;

  String room_id = '';
  String room_password = '';

  Future<void> createRoom(int id) async {
    final url = Uri.parse('$createRoomUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        room_id = responseBody['assigned_id'];
        room_password = responseBody['password'];
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
    gameProvider.loadIdAndName();

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
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        gameProvider.clearMyPersonalInfo();
                        Navigator.pushNamed(context, '/');
                      },
                      icon: const Icon(Icons.door_back_door_outlined, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        //pass to settings
                      },
                      icon: const Icon(Icons.settings, size: 60),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15)),
                ],
              ),
              Expanded(flex: 1, child: Text("")),
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 216,
                height: 216,
              ),
              Expanded(flex: 1, child: Text("")),
              SizedBox(
                width: 300,
                height: 60,
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
                      BorderSide(color: grey3A3A3AColor, width: 1),
                    ),
                  ),
                  onPressed: () {
                    showDialog(context: context, builder: (context) {
                    return Dialog(
                      child:
                        Container(
                          width: 930,
                          height: 312,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('lib/assets/background.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: grey3A3A3AColor, width: 0.1),
                          ),
                          child:
                            Container(
                              width: 930,
                              height: 312,
                              decoration: BoxDecoration(
                                color: backInvisColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: grey3A3A3AColor, width: 0.1),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 150,
                                    height: 150,
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
                                          BorderSide(color: grey3A3A3AColor, width: 1),
                                        ),
                                      ),
                                      onPressed: () async{
                                        setState(() {
                                          logSuccess = false;
                                        });
                                        await createRoom(gameProvider.myID);
                                        if (logSuccess) {
                                          gameProvider.roomId = room_id;
                                          gameProvider.roomPassword = room_password;
                                          gameProvider.aiGame = false;
                                          gameProvider.aiGameSave();
                                          gameProvider.saveRoomInfo();
                                          Navigator.of(context).pop();
                                          Navigator.pushNamed(context, '/waitingroom');
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.create, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Create private room", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 150,
                                    height: 150,
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
                                          BorderSide(color: grey3A3A3AColor, width: 1),
                                        ),
                                      ),
                                      onPressed: () {
                                        gameProvider.aiGame = false;
                                        gameProvider.aiGameSave();
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (context) => ConnectDialog(gameProvider: gameProvider),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.key, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Connect private room", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 150,
                                    height: 150,
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
                                          BorderSide(color: grey3A3A3AColor, width: 1),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        //pass;
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.search, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Random opponents", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 150,
                                    height: 150,
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
                                          BorderSide(color: grey3A3A3AColor, width: 1),
                                        ),
                                      ),
                                      onPressed: () async{
                                        gameProvider.aiGame = true;
                                        gameProvider.aiGameSave();
                                        Navigator.of(context).pop();
                                        Navigator.pushNamed(context, '/gameroom');
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.smart_toy, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Vs Bot", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Padding(padding: const EdgeInsets.only(bottom: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                ],
                              ),
                            ),
                          ),
                    );
                    }
                  );
                  },
                  child: const Text('START NEW GAME'),
                ),
              ),
              Expanded(flex: 4, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        // pass
                      },
                      icon: const Icon(Icons.help_outline, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        //pass to settings
                      },
                      icon: const Icon(Icons.emoji_events_outlined, size: 60),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15)),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 15)),
            ],
          ),
        ),
      ),
    );          
  }
}
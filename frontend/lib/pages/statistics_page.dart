import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles.dart';
import '../data/urls.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int winstrick = 0;
  int num_of_games = 0;
  int winrate = 0;
  List<bool> achievements = [false, false, false];
  bool logSuccess = false;
  String postText = 'Info: Nothing in response';

  @override
  void initState() {
    super.initState();
    // Get statistics info abour user from Backend
    getInfo();
  }

  // Function to get statistics info abour user from Backend
  void getInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = await prefs.getInt('myID') ?? -1;
    print("user_id that I post: $id");
    await getStatistics(id);
    print(postText);
  }

  /// Sends a POST request to the server to get user statistics.
  ///
  /// If the request is successful, it sets `logSuccess` to `true` and
  /// updates the `winstrick`, `num_of_games`, `winrate` and `achievements` fields
  /// with the values from the response.
  ///
  /// If the request fails, it sets `logSuccess` to `false` and sets `postText`
  /// to an error message.
  Future<void> getStatistics(int id) async {
    final url = Uri.parse('$statisticsUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        winstrick = responseBody['winstrick'];
        num_of_games = responseBody['num_of_games'];
        winrate = responseBody['winrate'];
        achievements = responseBody['achievements'];
        logSuccess = true;
        postText = 'Info: Success to get response';
      });
    } else {
      setState(() {
        logSuccess = false;
        postText = responseBody['detail'];
      });
    }
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
              Padding(padding: const EdgeInsets.only(top: 15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  // Button to return to MainMenuPage
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/mainmenu');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Text("Statistics", style: titleBigStyle,),
                  const Expanded(flex: 1, child: Text("")),
                  Padding(padding: const EdgeInsets.only(right: 75)),
                ],
              ),
              Expanded(flex: 1, child: Text(""),),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 7, child: Text(""),),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Winstrick info
                      Icon(Icons.local_fire_department, color: grey3A3A3AColor, size: 100,),
                      Padding(padding: const EdgeInsets.only(top: 15)),
                      Text("Winstrick", style: titleStyle,),
                      if (logSuccess)
                        Text(winstrick.toString(), style: statsBigStyle,)
                      else 
                        Padding(
                          padding: const EdgeInsets.all(31),
                          child: Text("Loading...", style: titleStyle,),
                        ),
                      Padding(padding: const EdgeInsets.only(top: 40)),
                      // Achievement 1
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: logSuccess ? (achievements[0] ? const Color.fromARGB(255, 123, 237, 127) : greyTimerColor) : greyTimerColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: grey3A3A3AColor, width: 1),
                        ),
                        child: Center(
                          child: Text("Achievement 1", style: basicTextStyle, textAlign: TextAlign.center,),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 20)),
                      Text("Log in to the game for\n7 consecutive days", style: basicTextStyle, textAlign: TextAlign.center,),
                    ],
                  ),
                  Expanded(flex: 1, child: Text(""),),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Number of games info
                      Icon(Icons.stadium, color: grey3A3A3AColor, size: 100,),
                      Padding(padding: const EdgeInsets.only(top: 15)),
                      Text("Number of games", style: titleStyle,),
                      if (logSuccess)
                        Text(num_of_games.toString(), style: statsBigStyle,)
                      else 
                        Padding(
                          padding: const EdgeInsets.all(31),
                          child: Text("Loading...", style: titleStyle,),
                        ),
                      Padding(padding: const EdgeInsets.only(top: 40)),
                      // Achievement 2
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: logSuccess ? (achievements[1] ? const Color.fromARGB(255, 123, 237, 127) : greyTimerColor) : greyTimerColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: grey3A3A3AColor, width: 1),
                        ),
                        child: Center(
                          child: Text("Achievement 2", style: basicTextStyle,),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 20)),
                      Text("Win the bot 3 times\n", style: basicTextStyle, textAlign: TextAlign.center,),
                    ],
                  ),
                  Expanded(flex: 1, child: Text(""),),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Winrate info
                      Icon(Icons.percent, color: grey3A3A3AColor, size: 100,),
                      Padding(padding: const EdgeInsets.only(top: 15)),
                      Text("Winrate", style: titleStyle,),
                      if (logSuccess)
                        Text(winrate.toString(), style: statsBigStyle,)
                      else 
                        Padding(
                          padding: const EdgeInsets.all(31),
                          child: Text("Loading...", style: titleStyle,),
                        ),
                      Padding(padding: const EdgeInsets.only(top: 40)),
                      // Achievement 3
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: logSuccess ? (achievements[2] ? const Color.fromARGB(255, 123, 237, 127) : greyTimerColor) : greyTimerColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: grey3A3A3AColor, width: 1),
                        ),
                        child: Center(
                          child: Text("Achievement 3", style: basicTextStyle,),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 20)),
                      Text("Get a winstreak of 5 games\nin an online-mode", style: basicTextStyle, textAlign: TextAlign.center,),
                    ],
                  ),
                  Expanded(flex: 7, child: Text(""),),
                ],
              ),
              Expanded(flex: 3, child: Text(""),),
            ],
          ),
        ),
      ),
    );
  }
}
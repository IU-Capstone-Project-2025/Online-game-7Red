import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles.dart';
import '../data/urls.dart';

class onlineSearchDialog extends StatefulWidget {

  const onlineSearchDialog({super.key});

  @override
  State<onlineSearchDialog> createState() => _OnlineSearchDialogState();
}

class _OnlineSearchDialogState extends State<onlineSearchDialog> {
  // contriller for timer
  SharedPreferences? prefs;
  final _countDownController = CountDownController();
  Timer? _onlineTimer;
  Timer? _totalTimer;
  Timer? _pollingTimer;
  int circleTime = 10;
  int _timeLeft = 9;
  int totalTime = 0;
  int currColour = -2;
  Color backColor = greyTimerColor;
  Color ringColor = greenTimerColor;

  String room_id = '';
  String room_password = '';
  int myID = -1;

  @override
  void initState() {
    super.initState();
    startAll();
  }

   @override
  void dispose() {
    _onlineTimer?.cancel();
    _totalTimer?.cancel();
    super.dispose();
  }

  void startAll() async{
    nextColourOfTimer();
    startTotalTimer();
    prefs = await SharedPreferences.getInstance();
    myID = prefs?.getInt('myID') ?? 0;
    connectToRoom(myID);
  }

  void _startTurnTimer() {

    _onlineTimer?.cancel();

    setState(() => _timeLeft = 9);
    _onlineTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        nextColourOfTimer();
      }
    });
  }

  void stopTimers() {
    _onlineTimer?.cancel();
    _totalTimer?.cancel();
    _pollingTimer?.cancel();
  }

  void nextColourOfTimer() {
    setState(() {
      currColour = currColour + 1;
      if (currColour == -1) {
        backColor = greyTimerColor;
      } else {
        backColor = getCurrBackColor(currColour);
      }
      ringColor = getCurrRoundColor(currColour + 1);
      _countDownController.restart();
    });
    _startTurnTimer();
  }


  Color getCurrBackColor(int i) {
    if (i % 7 == 0) {
      return redCard;
    } else if (i % 7 == 1) {
      return orangeCard;
    } else if (i % 7 == 2) {
      return yellowCard;
    } else if (i % 7 == 3) {
      return greenCard;
    } else if (i % 7 == 4) {
      return blueCard;
    } else if (i % 7 == 5) {
      return indigoCard;
    } else if (i % 7 == 6) {
      return violetCard;
    } else {
      return greyTimerColor;
    }
  }

  Color getCurrRoundColor(int i) {
    if (i % 7 == 0) {
      return redCard;
    } else if (i % 7 == 1) {
      return orangeCard;
    } else if (i % 7 == 2) {
      return yellowCard;
    } else if (i % 7 == 3) {
      return greenCard;
    } else if (i % 7 == 4) {
      return blueCard;
    } else if (i % 7 == 5) {
      return indigoCard;
    } else if (i % 7 == 6) {
      return violetCard;
    } else {
      return greenTimerColor;
    }
  }

  void startTotalTimer() {
    _totalTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        totalTime++;
      });
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> connectToRoom(int id) async {
    // Use url from urls.dart file
    final url = Uri.parse('$onlineSearchUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (responseBody['status'] == "matched") {
        setState(() {
          room_id = responseBody['assigned_id'];
          room_password = responseBody['password'];
        });
        await prefs?.setString('roomId', room_id);
        await prefs?.setString('roomPassword', room_password);
        await prefs?.setBool('aiGame', false);
        await prefs?.setBool('onlineGame', true);
        Navigator.pop(context);
        Navigator.pushNamed(context, '/waitingroom');
      } else if (responseBody['status'] == "waiting") {
        _pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) async{
          stateOfRoom(id);
        });
      }
    } else {
      print("We have an Error, in connectToRoom: ${response.statusCode}");
    }
  }

  Future<void> stateOfRoom(int id) async {
    // Use url from urls.dart file
    final url = Uri.parse('$onlineStateUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (responseBody['status'] == "matched") {
        _pollingTimer?.cancel();
        setState(() {
          room_id = responseBody['assigned_id'];
          room_password = responseBody['password'];
        });
        await prefs?.setString('roomId', room_id);
        await prefs?.setString('roomPassword', room_password);
        await prefs?.setBool('aiGame', false);
        await prefs?.setBool('onlineGame', true);
        Navigator.pop(context);
        Navigator.pushNamed(context, '/waitingroom');
      } else if (responseBody['status'] == "waiting") {
        print('Wait, wait...');
      } else if (responseBody['status'] == "no_players") {
        stopTimers();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Oops! No players found"),
            backgroundColor: greyTimerColor,
          ),
        );
      } else if (responseBody['status'] == "not_in_queue") {
        stopTimers();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Oops! No players found"),
            backgroundColor: greyTimerColor,
          ),
        );
      }
    } else {
      print("We have an Error, in stateOfRoom: ${response.statusCode}");
    }
  }

  Future<void> leaveTheRoom(int id) async {
    // Use url from urls.dart file
    final url = Uri.parse('$onlineLeaveUrl');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Dialog(
    child: Container(
      width: 604,
      height: 496,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('lib/assets/background.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grey3A3A3AColor, width: 0.1),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backInvisColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: grey3A3A3AColor, width: 0.1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Expanded(flex: 1, child: Text("")),
                Text("Searching your opponents...", style: titleStyle,),
                Expanded(flex: 1, child: Text("")),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularCountDownTimer(
                    controller: _countDownController,
                    duration: circleTime,
                    isReverse: true,
                    fillColor: ringColor,
                    height: 225,
                    width: 225,
                    strokeWidth: 15,
                    isReverseAnimation: false,
                    ringColor: backColor,
                    autoStart: true,
                    textStyle: invisTextStyle,
                    ),
                    Text(formatTime(totalTime), style: resLoseStyle,),
                  ],
                ),
                Expanded(flex: 1, child: Text("")),
                SizedBox(
                  width: 129,
                  height: 40,
                  child: 
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(buttonColor),
                      textStyle: WidgetStateProperty.all<TextStyle>(buttonTextStyle),
                      foregroundColor: WidgetStateProperty.all<Color>(grey3A3A3AColor),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5),),),
                      side: WidgetStateProperty.all<BorderSide>(BorderSide(color: grey3A3A3AColor, width: 1),),
                    ),
                    onPressed: () async {
                      stopTimers();
                      await leaveTheRoom(myID);
                      Navigator.pop(context);
                    },
                  child: Text('CANCEL'),
                  ),
                ),
                Expanded(flex: 1, child: Text("")),
                Text("Hints about important points in the rules will change here", style: basicTextStyle,),
                Expanded(flex: 1, child: Text("")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
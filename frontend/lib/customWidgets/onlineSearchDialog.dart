import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

import '../data/styles.dart';

class onlineSearchDialog extends StatefulWidget {

  const onlineSearchDialog({super.key});

  @override
  State<onlineSearchDialog> createState() => _OnlineSearchDialogState();
}

class _OnlineSearchDialogState extends State<onlineSearchDialog> {
  // contriller for timer
  final _countDownController = CountDownController();

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
                    duration: 60,
                    isReverse: true,
                    fillColor: greenTimerColor,
                    height: 225,
                    width: 225,
                    strokeWidth: 15,
                    onComplete: () {
                      // later
                    },
                    strokeCap: StrokeCap.round,
                    isReverseAnimation: true,
                    ringColor: greyTimerColor,
                    autoStart: false,
                    textStyle: invisTextStyle,
                    ),
                    // Icon(Icons.account_circle, size: 80, color: grey3A3A3AColor,),
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
                    onPressed: () {
                      // later
                    },
                  child: Text('CANCEL'),
                  ),
                ),
                Expanded(flex: 1, child: Text("")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
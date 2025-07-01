import 'package:flutter/material.dart';
import '../data/styles.dart';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
final _countDownController = CountDownController();

class WelkomePage extends StatefulWidget {
  const WelkomePage({super.key});

  @override
  State<WelkomePage> createState() => _WelkomePageState();
}

class _WelkomePageState extends State<WelkomePage> {
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
              const Expanded(flex: 5, child: Text("")),
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 200,
                height: 200,
              ),
              const Expanded(flex: 2, child: Text("")),
              Text("Welcome to the game!", style: titleStyle),
              const Expanded(flex: 1, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 295,
                        height: 45,
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
                            Navigator.of(context).pushNamed('/signin');
                          },
                          child: const Text('SIGN  IN'),
                        ),
                      ),
                      Text(""),
                      Text(
                        "If you already have an account",
                        style: basicTextStyle,
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(left: 80)),
                  Container(width: 1, height: 130, color: Colors.black),
                  Padding(padding: EdgeInsets.only(left: 80)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 295,
                        height: 45,
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
                            Navigator.of(context).pushNamed('/signup');
                          },
                          child: const Text('SIGN  UP'),
                        ),
                      ),
                      Text(""),
                      Text(
                        "If you want to create an account",
                        style: basicTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
              const Expanded(flex: 6, child: Text("")),
              // const Expanded(flex: 2, child: Text("")),
              // Stack(
              //   alignment: Alignment.center,
              //   children: [
              //     CircularCountDownTimer(
              //     controller: _countDownController,
              //     duration: 60,
              //     isReverse: true,
              //     fillColor: greenTimerColor,
              //     height: 74,
              //     width: 74,
              //     strokeWidth: 8,
              //     onComplete: () {
              //       // later
              //     },
              //     strokeCap: StrokeCap.round,
              //     isReverseAnimation: true,
              //     ringColor: greyTimerColor,
              //     autoStart: false,
              //     textStyle: invisTextStyle,
              //     ),
              //     Icon(Icons.account_circle, size: 80, color: grey3A3A3AColor,),
              //   ],
              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     IconButton(
              //       onPressed: () {
              //         _countDownController.restart();
              //       },
              //       icon: Icon(Icons.refresh, size: 50, color: grey3A3A3AColor,),
              //     ),
              //     Padding(padding: EdgeInsets.only(left: 30)),
              //     IconButton(
              //       onPressed: () {
              //         _countDownController.reset();
              //       },
              //       icon: Icon(Icons.stop, size: 50, color: grey3A3A3AColor,),
              //     )
              //   ],
              // ),
              // const Expanded(flex: 2, child: Text("")),
            ],
          ),
        ),
      ),
    );
  }
}

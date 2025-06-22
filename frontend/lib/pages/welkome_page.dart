import 'package:flutter/material.dart';
import '../data/styles.dart';



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
                        width: 335,
                        height: 48,
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
                  Container(width: 1, height: 150, color: Colors.black),
                  Padding(padding: EdgeInsets.only(left: 80)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 335,
                        height: 50,
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
              const Expanded(flex: 4, child: Text("")),
              SizedBox(
                width: 60,
                height: 60,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/waitingroom');
                  },
                  icon: const Icon(Icons.skip_next, size: 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

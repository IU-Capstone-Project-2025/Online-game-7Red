import 'package:flutter/material.dart';
import '../data/styles.dart';
import 'package:provider/provider.dart';

import '../providers/provider.dart';

class WelkomePage extends StatefulWidget {
  const WelkomePage({super.key});

  @override
  State<WelkomePage> createState() => _WelkomePageState();
}

class _WelkomePageState extends State<WelkomePage> {
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
              Padding(padding: const EdgeInsets.only(top: 15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () {
                        gameProvider.toggleLanguage();
                      },
                      icon: const Icon(Icons.language, size: 44),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15)),
                ],
              ),
              const Expanded(flex: 4, child: Text("")),
              // Red7 logo
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 200,
                height: 200,
              ),
              const Expanded(flex: 2, child: Text("")),
              Text(gameProvider.localizations!.getString("welcome", gameProvider.languageCode), style: titleStyle),
              const Expanded(flex: 1, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sign in button
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
                            // Go to sign in page
                            Navigator.of(context).pushNamed('/signin');
                          },
                          child: Text(gameProvider.localizations!.getString("sign_in_botton", gameProvider.languageCode)),
                        ),
                      ),
                      Text(""),
                      Text(
                        gameProvider.localizations!.getString("already_have_account", gameProvider.languageCode),
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
                      // Sign up button
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
                            // Go to sign up page
                            Navigator.of(context).pushNamed('/signup');
                          },
                          child: Text(gameProvider.localizations!.getString("sign_up_botton", gameProvider.languageCode)),
                        ),
                      ),
                      Text(""),
                      Text(
                        gameProvider.localizations!.getString("create_account", gameProvider.languageCode),
                        style: basicTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
              const Expanded(flex: 6, child: Text("")),
            ],
          ),
        ),
      ),
    );
  }
}

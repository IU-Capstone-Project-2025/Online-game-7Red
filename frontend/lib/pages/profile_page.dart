import 'package:flutter/material.dart';
import 'package:frontend/customWidgets/changePassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../data/urls.dart';
import '../providers/provider.dart';
import '../customWidgets/changePersInfo.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SharedPreferences? prefs;

  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    gameProvider.loadMyPersonalInfo();

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
                        Navigator.pop(context);
                        // Navigator.pushNamed(context, '/mainmenu');
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Text("Settings", style: titleBigStyle,),
                  const Expanded(flex: 1, child: Text("")),
                  Padding(padding: const EdgeInsets.only(right: 75)),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 15)),
              Container(
                width: 800,
                height: 631,
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
                    child: Container(
                      width: 764,
                      height: 595,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: grey3A3A3AColor, width: 3),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(flex: 1, child: Text("")),
                            Column(
                              children: [
                                Expanded(flex: 1, child: Text("")),
                                Container(
                                  width: 217,
                                  height: 217,
                                  decoration: BoxDecoration(
                                    color: greyTimerColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: grey3A3A3AColor, width: 1),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.account_circle_rounded, size: 200,),
                                  ),
                                ),
                                Expanded(flex: 1, child: Text("")),
                                // - - - - - Nickname - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                                Row(
                                  children: [
                                    Text("Nickname", style: basicBoldTextStyle),
                                    Padding(padding: const EdgeInsets.only(left: 250)),
                                  ],
                                ),
                                Padding(padding: const EdgeInsets.only(top: 7)),
                                Container(
                                  width: 320,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(padding: const EdgeInsets.only(left: 15)),
                                        SelectableText(gameProvider.myName, style: basicTextStyle,),
                                        Expanded(flex: 1, child: Text("")),
                                        IconButton(
                                          onPressed: () {
                                            // TODO: change name
                                            showDialog(
                                              context: context,
                                              builder: (context) => changePersInfo(),
                                            );
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(top: 18),),
                                // - - - - - Email - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                Row(
                                  children: [
                                    Text("Email address", style: basicBoldTextStyle),
                                    Padding(padding: const EdgeInsets.only(left: 225)),
                                  ],
                                ),
                                Padding(padding: const EdgeInsets.only(top: 7)),
                                Container(
                                  width: 320,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(padding: const EdgeInsets.only(left: 15)),
                                        SelectableText(gameProvider.email, style: basicTextStyle,),
                                        Expanded(flex: 1, child: Text("")),
                                        IconButton(
                                          onPressed: () {
                                            // TODO: change email
                                            showDialog(
                                              context: context,
                                              builder: (context) => changePersInfo(),
                                            );
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(top: 18),),
                                // - - - - - Password - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                Row(
                                  children: [
                                    Text("Password", style: basicBoldTextStyle),
                                    Padding(padding: const EdgeInsets.only(left: 250)),
                                  ],
                                ),
                                Padding(padding: const EdgeInsets.only(top: 7)),
                                Container(
                                  width: 320,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Padding(padding: const EdgeInsets.only(left: 15)),
                                        Text("•" * gameProvider.password.length, style: basicTextStyle,),
                                        Expanded(flex: 1, child: Text("")),
                                        IconButton(
                                          onPressed: () {
                                            // TODO: change password
                                            showDialog(
                                              context: context,
                                              builder: (context) => changePassword(),
                                            );
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(top: 18),),
                                Expanded(flex: 1, child: Text("")),
                              ]
                            ),
                            Expanded(flex: 1, child: Text("")),
                            Container(
                              width: 1,
                              height: 595,
                              decoration: BoxDecoration(
                                color: grey3A3A3AColor,
                                border: Border.all(color: grey3A3A3AColor, width: 2),
                              ),
                            ),
                            Expanded(flex: 1, child: Text("")),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(flex: 1, child: Text("")),
                                // Light switch
                                SizedBox(
                                  width: 120,
                                  height: 120,
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
                                    onPressed: () {
                                      
                                    },
                                    child: Column(
                                      children: [
                                        const Expanded(flex: 1, child: Text(""),),
                                        Icon(Icons.sunny, size: 60),
                                        const Expanded(flex: 1, child: Text(""),),
                                        Text("Dark mode", style: buttonTextStyle, textAlign: TextAlign.center,),
                                        const Expanded(flex: 1, child: Text(""),),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(flex: 1, child: Text("")),
                                // Language switch
                                SizedBox(
                                  width: 120,
                                  height: 120,
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
                                    onPressed: () {
                                      
                                    },
                                    child: Column(
                                      children: [
                                        const Expanded(flex: 1, child: Text(""),),
                                        Icon(Icons.language, size: 60),
                                        const Expanded(flex: 1, child: Text(""),),
                                        Text("Language", style: buttonTextStyle, textAlign: TextAlign.center,),
                                        const Expanded(flex: 1, child: Text(""),),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(flex: 1, child: Text("")),
                                // Log out
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all<Color>(
                                        Color(0xFFFCB2AB),
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
                                    onPressed: () {
                                      gameProvider.clearMyPersonalInfo();
                                      Navigator.pushNamed(context, '/');
                                    },
                                    child: Column(
                                      children: [
                                        const Expanded(flex: 1, child: Text(""),),
                                        Icon(Icons.logout, size: 60),
                                        const Expanded(flex: 1, child: Text(""),),
                                        Text("LOG OUT", style: buttonTextStyle, textAlign: TextAlign.center,),
                                        const Expanded(flex: 1, child: Text(""),),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(flex: 1, child: Text("")),
                              ],
                            ),
                            Expanded(flex: 1, child: Text("")),
                          ],
                        )
                      )
                    ),
                  ),
                ),
              ),
              Expanded(flex: 1, child: Text(""),),
            ],
          ),
        ),
      ),
    );
  }
}
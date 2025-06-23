import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../providers/provider.dart';

class GameRoomPage extends StatefulWidget {
  const GameRoomPage({super.key});

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
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
//--------------------UPBAR----------------------------------------------------------------------------------------------------------
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
                        // do alert
                        // send http-request
                        // delete data
                        // pass to main menu
                        Navigator.pushNamed(context, '/mainmenu');
                      },
                      icon: const Icon(Icons.door_back_door_outlined, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                  ),
                  Padding(padding: const EdgeInsets.only(right: 15),),
                  Column(
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 40)),
                      Row(
                        children: [
                          Icon(Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text("Player_ABC", style: buttonTextStyle),
                        ],
                      )
                    ]
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Padding(padding: const EdgeInsets.only(left: 95)),
                ],
              ),
//--------------------PALLETES----------------------------------------------------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
//--------------------LEFT-PLAYER----------------------------------------------------------------------------------------------------------
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text("Player_123", style: buttonTextStyle),
                        ],
                      )
                  ]),
                  Padding(padding: const EdgeInsets.only(right: 30)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 30)),
                      for (int i = 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              height: 60,
                              width: 84,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(top: 9)),
                          ],
                        ),
                      Padding(padding: const EdgeInsets.only(bottom: 21)),
                    ],
                  ),
//--------------------CENTER-PLAYERS----------------------------------------------------------------------------------------------------------
                  Padding(padding: const EdgeInsets.only(right: 44)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 7; i++)
                            Row(
                              children: [
                                Container(
                                  height: 84,
                                  width: 60,
                                  decoration:  BoxDecoration(
                                    color: invisColor,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(left: 18)),
                              ],
                            )
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 75)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('lib/assets/rules_pallete.png'),
                            width: 345,
                            height: 179,
                          ),
                          Padding(padding: const EdgeInsets.only(left: 32)),
                          Container(
                                  height: 84,
                                  width: 60,
                                  decoration:  BoxDecoration(
                                    color: redCard,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                  ),
                                ),
                        ],
                      ),
                      Padding(padding: const EdgeInsets.only(top: 75)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 7; i++)
                            Row(
                              children: [
                                Container(
                                  height: 84,
                                  width: 60,
                                  decoration:  BoxDecoration(
                                    color: invisColor,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: grey3A3A3AColor, width: 1.5),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.only(left: 18)),
                              ],
                            )
                        ],
                      ),
                    ],
                  ),
//--------------------RIGHT-PLAYERS----------------------------------------------------------------------------------------------------------
                  Padding(padding: const EdgeInsets.only(right: 44)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 30)),
                      for (int i = 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              height: 60,
                              width: 84,
                              decoration:  BoxDecoration(
                                color: invisColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: grey3A3A3AColor, width: 1.5),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.only(top: 9)),
                          ],
                        ),
                      Padding(padding: const EdgeInsets.only(bottom: 21)),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.only(right: 30)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Row(
                        children: [
                          Icon(Icons.filter_7, size: 24, color: grey3A3A3AColor,),
                          Padding(padding: const EdgeInsets.only(right: 5),),
                          Text("Player_XXX", style: buttonTextStyle),
                        ],
                      )
                  ]),
                ],
              ),
//--------------------HAND----------------------------------------------------------------------------------------------------------
              Expanded(flex: 1, child: Text("")),
              Container(
                height: 155,
                decoration:  BoxDecoration(
                  color: handInvisColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.account_circle, size: 90, color: grey3A3A3AColor,),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 29)),
                    for (int i = 0; i < 7; i++)
                      Row(
                        children: [
                          Container(
                            height: 106,
                            width: 71,
                            decoration:  BoxDecoration(
                              color: invisColor,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: grey3A3A3AColor, width: 1.5),
                            ),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 18)),
                        ],
                      ),
                    Padding(padding: const EdgeInsets.only(left: 11)),
                    SizedBox(
                      width: 100,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(buttonColor),
                          textStyle: WidgetStateProperty.all<TextStyle>(buttonTextStyle,),
                          foregroundColor: WidgetStateProperty.all<Color>(grey3A3A3AColor,),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),),),
                          side: WidgetStateProperty.all<BorderSide>(BorderSide(color: grey3A3A3AColor, width: 1),),
                        ),
                        onPressed: () async{
                          // send request to server
                        },
                      child: Text('SUBMIT'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

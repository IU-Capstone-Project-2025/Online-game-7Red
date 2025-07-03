import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../providers/provider.dart';
import '../data/styles.dart';


class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
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
              Expanded(flex: 3, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.account_circle, size: 48, color: grey3A3A3AColor,),
                      Text("Player_XXX", style: basicTextStyle,),
                      Container(
                        width: 75,
                        height: 60,
                        decoration: BoxDecoration(
                          color: whiteInvisColor,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.only(left: 11)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.account_circle, size: 48, color: grey3A3A3AColor,),
                      Text("Player_XXX", style: basicTextStyle,),
                      Container(
                        width: 75,
                        height: 180,
                        decoration: BoxDecoration(
                          color: whiteInvisColor,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: grey3A3A3AColor, width: 2),
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.only(left: 11)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.account_circle, size: 48, color: grey3A3A3AColor,),
                      Text("Player_XXX", style: basicTextStyle,),
                      Container(
                        width: 75,
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
              Container(
                width: 308,
                height: 80,
                decoration: BoxDecoration(
                  color: whiteInvisColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: grey3A3A3AColor, width: 2),
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
                  Padding(padding: const EdgeInsets.only(left: 11)),
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
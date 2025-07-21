import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../providers/provider.dart';

class confirmExit extends StatefulWidget {

  confirmExit({super.key});

  @override
  State<confirmExit> createState() => _ConfirmExitState();
}

class _ConfirmExitState extends State<confirmExit> {

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Dialog(
      child: Container(
        width: 300,
        height: 270,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/background.jpg'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: grey3A3A3AColor, width: 0.1),
        ),
        child:
          Container(
            decoration: BoxDecoration(
              color: backInvisColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: grey3A3A3AColor, width: 0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(flex: 1, child: Text(""),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(gameProvider.languageCode == "en" ? "Are you sure you\nwant to exit?" : "Вы уверены, что\nхотите выйти?", style: confirmExitStyle, textAlign: TextAlign.center,),
                  ],
                ),
                Expanded(flex: 1, child: Text(""),),
                SizedBox(
                  width: 114,
                  height: 114,
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
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      side: WidgetStateProperty.all<BorderSide>(
                        BorderSide(color: grey3A3A3AColor, width: 1),
                      ),
                    ),
                    onPressed: () async {
                      gameProvider.clearMyPersonalInfo();
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/');
                    },
                    child: Column(
                      children: [
                        const Expanded(flex: 1, child: Text(""),),
                        Icon(Icons.door_back_door_outlined, size: 70),
                        const Expanded(flex: 1, child: Text(""),),
                        Text(gameProvider.localizations!.getString("room_leave", gameProvider.languageCode), style: buttonTextStyle, textAlign: TextAlign.center,),
                        const Expanded(flex: 1, child: Text(""),),
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 1, child: Text(""),),
              ],
            ),
          ),
      )
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../providers/provider.dart';

class noOpponents extends StatefulWidget {

  noOpponents({super.key});

  @override
  State<noOpponents> createState() => _NoOpponentsState();
}

class _NoOpponentsState extends State<noOpponents> {

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Dialog(
      child: Container(
        width: 300,
        height: 200,
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
                Expanded(flex: 2, child: Text(""),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(gameProvider.localizations!.getString("no_opponents", gameProvider.languageCode), style: confirmExitStyle, textAlign: TextAlign.center,)
                  ],
                ),
                Expanded(flex: 1, child: Text(""),),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 75,
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
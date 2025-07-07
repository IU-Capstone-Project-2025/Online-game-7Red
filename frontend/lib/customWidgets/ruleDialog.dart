import 'package:flutter/material.dart';

import '../data/styles.dart';

class RuleDialog extends StatefulWidget {

  const RuleDialog({super.key});

  @override
  State<RuleDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<RuleDialog> {
  int currSlide = 1;

  String getText(int slide) {
    if (slide == 1) {
      return 'Each card has a value (a number from 1 to 7) and a color\n(one of the 7 colors of the rainbow). There are 49 unique\ncards in total.';
    } else if (slide == 2) {
      return 'At the start of the game, each player is dealt 7 cards\ninto their hand.';
    } else if (slide == 3) {
      return 'The number of cards in your opponents’ hands is shown\nnext to their names.';
    } else if (slide == 4) {
      return 'In the center lies a card (the canvas), which determines the\ncurrent rule (the game always starts with the Red rule),\nalong with a reference showing all possible rules.';
    } else if (slide == 5) {
      return 'The cards lying on the table in front of you are your\npalette. Initially, it is empty for all players.';
    } else if (slide == 6) {
      return 'All players take turns in a clockwise order. The first playeris\nchosen at random. Each turn lasts while the timer runs (60\nseconds). The winner is the last remaining player in the game.';
    } else if (slide == 7) {
      return 'At the end of their turn, the player must be winning according\nto the current rule, or else they lose. If the results are\ntied, the leader is determined by the highest card.';
    } else if (slide == 8) {
      return 'The highest card is determined first by value; if equal, then\nthe card whose color is closer to red is considered higher.';
    } else if (slide == 9) {
      return 'On your turn, you may play a card to your palette, change the\nrule (by playing to the canvas), or do both. To confirm your\nmove, click the "Confirm" button.';
    }
    return '';
  }

  Widget? getImage(int slide) {
    if (slide == 1) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule1.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 2) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule2.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 3) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule3.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 4) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule4.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 5) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule5.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 6) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Column(
            children: [
              Image(
                image: AssetImage('lib/assets/rule6.png'),
                width: 400,
              height: 240,
              ),
            ]
          ),
        );
    } else if (slide == 7) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule7.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 8) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule8.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    } else if (slide == 9) {
      return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Image(
              image: AssetImage('lib/assets/rule9.png'),
              width: 400,
            height: 200,
            ),
          ),
        );
    }
    return SizedBox(
          width: 500,
          height: 250,
          child: Center(
            child: Text('NONE')
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
  return Dialog(
    child: Container(
      width: 860,
      height: 530,
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
            width: 824,
            height: 494,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: grey3A3A3AColor, width: 3),
            ),
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.only(top: 45)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 1 ? redCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 2 ? orangeCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 3 ? yellowCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 4 ? greenCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 5 ? blueCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 6 ? indigoCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 7 ? violetCard : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 8 ? Colors.white : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(left: 10)),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currSlide == 9 ? Colors.purpleAccent : grey3A3A3AColor,
                        border: Border.all(color: grey3A3A3AColor, width: 0.1),
                      ),
                    ),
                  ]
                ),
                Padding(padding: const EdgeInsets.only(top: 45)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 15)),
                    IconButton(
                      icon: ImageIcon(AssetImage('lib/assets/leftButton.png'), size: 130,),
                      onPressed: () {
                        setState(() {
                          if (currSlide > 1) {
                            currSlide--;
                          }
                        });
                      },
                    ),
                    ?getImage(currSlide),
                    IconButton(
                      icon: ImageIcon(AssetImage('lib/assets/rightButton.png'), size: 130,),
                      onPressed: () {
                        setState(() {
                          if (currSlide < 9) {
                            currSlide++;
                          }
                        });
                      },
                    ),
                    Padding(padding: const EdgeInsets.only(top: 15)),
                  ],
                ),
                Text(getText(currSlide), style: ruleStyle, textAlign: TextAlign.center,),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
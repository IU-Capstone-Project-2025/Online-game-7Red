import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../providers/provider.dart';

class RuleDialog extends StatefulWidget {

  const RuleDialog({super.key});

  @override
  State<RuleDialog> createState() => _RuleDialogState();
}

// Class for showing rules alert in the GamePage
class _RuleDialogState extends State<RuleDialog> {
  int currSlide = 1;

  // Method for getting text for each slide of the rules
  String getText(int slide) {
    if (slide == 1) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_1', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 2) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_2', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 3) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_3', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 4) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_4', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 5) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_5', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 6) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_6', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 7) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_7', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 8) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_8', Provider.of<GameProvider>(context).languageCode);
    } else if (slide == 9) {
      return Provider.of<GameProvider>(context).localizations!.getString('rule_slide_9', Provider.of<GameProvider>(context).languageCode);
    }
    return '';
  }

  // Method for getting image for each slide of rules
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
                // Slide indicator in top of Rules
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
                // For rule images and buttons to change slide
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
                // For rule text
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
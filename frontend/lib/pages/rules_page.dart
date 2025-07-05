import 'package:flutter/material.dart';

import '../data/styles.dart';

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
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
              Padding(padding: const EdgeInsets.only(top: 15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/mainmenu');
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Text("Rules", style: titleBigStyle,),
                  const Expanded(flex: 1, child: Text("")),
                  Padding(padding: const EdgeInsets.only(right: 75)),
                ],
              ),
              Expanded(flex: 1, child: Text(""),),
              Container(
                width: 938,
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
                      width: 902,
                      height: 595,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: grey3A3A3AColor, width: 3),
                      ),
                      child: ListView(
                        children: [
                          // - - - - - Deck - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text("Deck", style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• A total of 49 unique cards", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Each card has a value (number) and a color", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Card values: from 1 to 7", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Colors: 7 colors of the rainbow (each color includes", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   cards of all values)", style: ruleTextStyle,),
                                ],
                              ),
                              Expanded(flex: 1, child: Text(""),),
                              SizedBox(
                                width: 200,
                                height: 100,
                                child: Center(
                                  child: Image(
                                    image: AssetImage('lib/assets/rule1.png'),
                                    width: 300,
                                    height: 150,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.only(right: 20),),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Center(
                            child: Container(
                              width: 862,
                              height: 3,
                              decoration: BoxDecoration(
                                border: Border.all(color: grey3A3A3AColor, width: 2),
                              ),
                            ),
                          ),
                          // - - - - - Game start - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text("Game start", style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• Each player is dealt 7 cards", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• The cards lying on the table in front of you are your palette.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   Initially, it is empty for all players", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• A starting card is placed in the center — this is the canvas", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• The top card of the canvas determines the current rule by which", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   players can win.", style: ruleTextStyle,),
                                ],
                              ),
                              Expanded(flex: 1, child: Text(""),),
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: Image(
                                    image: AssetImage('lib/assets/rule10.png'),
                                    width: 300,
                                    height: 200,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.only(right: 20),),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Center(
                            child: Container(
                              width: 862,
                              height: 3,
                              decoration: BoxDecoration(
                                border: Border.all(color: grey3A3A3AColor, width: 2),
                              ),
                            ),
                          ),
                          // - - - - - Gameplay - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text("Gameplay", style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("On your turn, you must perform one of the following actions:", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("1.  Play a card into your palette (face-up).", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("2. Play a card to the canvas to change the current rule.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("      • You must be leading under the new rule.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("3. Play a card into your palette and then to the canvas to change", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   the rule.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("      • You must be leading under the new rule.", style: ruleTextStyle,),
                                ],
                              ),
                              Expanded(flex: 1, child: Text(""),),
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: Image(
                                    image: AssetImage('lib/assets/rule9.png'),
                                    width: 300,
                                    height: 200,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.only(right: 20),),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Center(
                            child: Container(
                              width: 862,
                              height: 3,
                              decoration: BoxDecoration(
                                border: Border.all(color: grey3A3A3AColor, width: 2),
                              ),
                            ),
                          ),
                          // - - - - - Determining the Leader - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text("Determining the Leader", style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• You are leading if your palette contains more cards that match", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   the current rule than any other player. Other cards in your", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   palette do not count.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• If tied, the leader is the player with the highest card that", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   matches the rule:", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("      - First compare by value.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("      - If values are equal, compare colors in the order: Red > ", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("         Orange > Yellow > Green > Blue > Indigo> Purple.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("      - If you have no cards matching the rule (e.g., under the ", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("         Green or Purple rule), you cannot be the leader.", style: ruleTextStyle,),
                                ],
                              ),
                              Expanded(flex: 1, child: Text(""),),
                              SizedBox(
                                width: 200,
                                height: 100,
                                child: Center(
                                  child: Image(
                                    image: AssetImage('lib/assets/rule8.png'),
                                    width: 300,
                                    height: 150,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.only(right: 20),),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Center(
                            child: Container(
                              width: 862,
                              height: 3,
                              decoration: BoxDecoration(
                                border: Border.all(color: grey3A3A3AColor, width: 2),
                              ),
                            ),
                          ),
                          // - - - - - Win and Loss Conditions - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text("Win and Loss Conditions", style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• If you are not leading under the current rule at the end of", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   your turn, you lose and are eliminated from the round.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Place all your cards (from hand and palette) face down in ", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   front of you.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• If at the start of your turn you have no cards in hand — you", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   lose and are eliminated.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• If you are the last remaining player at the start of your", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("   turn — you win the round!", style: ruleTextStyle,),
                                ],
                              ),
                              Expanded(flex: 1, child: Text(""),),
                              SizedBox(
                                width: 200,
                                height: 100,
                                child: Center(
                                  child: Image(
                                    image: AssetImage('lib/assets/rule3.png'),
                                    width: 300,
                                    height: 150,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.only(right: 20),),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Center(
                            child: Container(
                              width: 862,
                              height: 3,
                              decoration: BoxDecoration(
                                border: Border.all(color: grey3A3A3AColor, width: 2),
                              ),
                            ),
                          ),
                          // - - - - - Color Rules - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text("Color Rules", style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• Red — Highest card wins.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Orange — Most cards of the same value.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Yellow — Most cards of the same color.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Green — Most even-numbered cards.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Blue — Most cards of different colors.", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Indigo — Longest sequence of consecutive numbers (e.g., 4, 5, 6).", style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text("• Purple — Most cards with value less than 4.", style: ruleTextStyle,),
                                ],
                              ),
                              Expanded(flex: 1, child: Text(""),),
                              SizedBox(
                                width: 200,
                                height: 100,
                                child: Center(
                                  child: Image(
                                    image: AssetImage('lib/assets/rule4.png'),
                                    width: 300,
                                    height: 150,
                                  ),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.only(right: 20),),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                        ],
                      )
                    ),
                  ),
                ),
              ),
              Expanded(flex: 4, child: Text(""),),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../providers/provider.dart';

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      // Add background image
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
                        // Navigator.pushNamed(context, '/mainmenu');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  Text(gameProvider.localizations!.getString("main_menu_show_rules", gameProvider.languageCode), style: titleBigStyle,),
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
                      // Scrolling list to show all rules
                      child: ListView(
                        children: [
                          // - - - - - Deck - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Text(gameProvider.localizations!.getString("rules_deck", gameProvider.languageCode), style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gameProvider.localizations!.getString("rules_deck_49_cards", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_deck_card_value_color", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_deck_card_values", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_deck_colors", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_deck_cards_of_all_values", gameProvider.languageCode), style: ruleTextStyle,),
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
                          Text(gameProvider.localizations!.getString("rules_game_start", gameProvider.languageCode), style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gameProvider.localizations!.getString("rules_game_start_deal", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_game_start_palette", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_game_start_palette_empty", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_game_start_canvas", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_game_start_rule", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_game_start_players_can_win", gameProvider.languageCode), style: ruleTextStyle,),
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
                          Text(gameProvider.localizations!.getString("rules_gameplay", gameProvider.languageCode), style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gameProvider.localizations!.getString("rules_gameplay_actions", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_gameplay_action1", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_gameplay_action2", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_gameplay_action2_leading", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_gameplay_action3", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_gameplay_action3_rule", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_gameplay_action3_leading", gameProvider.languageCode), style: ruleTextStyle,),
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
                          Text(gameProvider.localizations!.getString("rules_leader_title", gameProvider.languageCode), style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gameProvider.localizations!.getString("rules_leader_palette_match", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_palette_match_rule", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_palette_do_not_count", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_tied", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_tied_match_rule", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_compare_value", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_compare_color", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_compare_color_order", gameProvider.languageCode), style: ruleTextStyle,),
                                  if (gameProvider.languageCode == 'ru')
                                    Padding(padding: const EdgeInsets.only(top: 5)),
                                  if (gameProvider.languageCode == 'ru')
                                    Text(gameProvider.localizations!.getString("rules_leader_compare_color_order_2", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_no_cards_match", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_leader_no_cards_match_rule", gameProvider.languageCode), style: ruleTextStyle,),
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
                          Text(gameProvider.localizations!.getString("rules_win_loss_title", gameProvider.languageCode), style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gameProvider.localizations!.getString("rules_win_loss_not_leading", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_lose_eliminated", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_place_cards", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_front_of_you", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_no_cards_hand", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_lose_eliminated_start", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_last_player", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_win_loss_win_round", gameProvider.languageCode), style: ruleTextStyle,),
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
                          Text(gameProvider.localizations!.getString("rules_color_rules_title", gameProvider.languageCode), style: titleRuleStyle, textAlign: TextAlign.center,),
                          Padding(padding: const EdgeInsets.only(top: 30)),
                          Row(
                            children: [
                              Padding(padding: const EdgeInsets.only(left: 32),),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gameProvider.localizations!.getString("rules_color_red", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_color_orange", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_color_yellow", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_color_green", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_color_blue", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_color_indigo", gameProvider.languageCode), style: ruleTextStyle,),
                                  Padding(padding: const EdgeInsets.only(top: 5)),
                                  Text(gameProvider.localizations!.getString("rules_color_purple", gameProvider.languageCode), style: ruleTextStyle,),
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
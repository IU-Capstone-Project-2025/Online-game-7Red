import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/styles.dart';
import '../data/urls.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // final TextEditingController controller = TextEditingController();
  // final TextEditingController controller2 = TextEditingController();
  // final TextEditingController controller3 = TextEditingController();

  bool obscure = true;

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
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                // 
                                Expanded(flex: 1, child: Text("")),
                              ]
                            )
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
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';

import '../data/styles.dart';
import '../data/urls.dart';
import '../providers/provider.dart';

class ChangePersInfo extends StatefulWidget {
  final int changeNameEmail;

  ChangePersInfo({super.key, required this.changeNameEmail});

  @override
  State<ChangePersInfo> createState() => _ChangePersInfoState(changeNameEmail);
}

class _ChangePersInfoState extends State<ChangePersInfo> {
  final TextEditingController controller = TextEditingController();
  SharedPreferences? prefs;
  int? changeNameEmail;

  String errNew = '';
  String postText = '';

  bool logSuccess = false;
  
  _ChangePersInfoState(int this.changeNameEmail);

  Future<void> changeNickname(int id, String new_nickname) async {

    // Use url from urls.dart file
    final url = Uri.parse(changeNicknameUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
        'new_nickname': new_nickname,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        logSuccess = true;
      });
    } else if (responseBody['detail'] == 'Profile not found') {
      setState(() {
        logSuccess = false;
        postText = 'Profile not found';
      });
    }
  }

  Future<void> changeEmail(int id, String new_email) async {

    // Use url from urls.dart file
    final url = Uri.parse(changeEmailUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
        'new_email': new_email,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        logSuccess = true;
      });
    } else if (responseBody['detail'] == 'Email already registered') {
      setState(() {
        logSuccess = false;
        postText = 'Email already registered';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Dialog(
    child: Container(
      width: 352,
      height: 250,
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
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 47)),
                  Text("Previous", style: basicTextStyle,),
                  const Expanded(flex: 1, child: Text("")),
                ]
              ),
              Padding(padding: const EdgeInsets.only(top: 5)),
              // Text field for email
              Container(
                width: 260,
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
                      SelectableText(changeNameEmail == 1 ? gameProvider.myName : gameProvider.email, style: basicTextStyle,),
                      Expanded(flex: 1, child: Text("")),
                    ],
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 17)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 47)),
                  Text("New", style: basicTextStyle),
                  const Expanded(flex: 1, child: Text("")),
                  Text(errNew, style: errorTextStyle, textAlign: TextAlign.right),
                  Padding(padding: const EdgeInsets.only(right: 47)),
                ]
              ),
              Padding(padding: const EdgeInsets.only(top: 5)),
              // Text field for password
              Container(
                width: 260,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: controller,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 20)),
              // Sign in button
              SizedBox(
                  width: 260,
                  height: 35,
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
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      side: WidgetStateProperty.all<BorderSide>(
                        BorderSide(color: grey3A3A3AColor, width: 1),
                      ),
                    ),
                    onPressed: () async {
                      // Reset error messages
                      setState(() {
                        postText = '';
                        errNew = '';
                      });
                      // Check if all fields are filled
                      if (controller.text.isEmpty) {
                        setState(() {
                          postText = 'All fields are required';
                        });
                        return;
                      } else if (changeNameEmail == 1 && controller.text.length > 10) {
                        setState(() {
                          errNew = '1-10 symbols';
                        });
                        return;
                      } else if (changeNameEmail == 2 && !EmailValidator.validate(controller.text)) {
                        setState(() {
                          errNew = 'Invalid email';
                        });
                        return;
                      } else {
                        if (changeNameEmail == 1) {
                          await changeNickname(gameProvider.myID, controller.text);
                        } else {
                          await changeEmail(gameProvider.myID, controller.text);
                        }
                      }
                      if (logSuccess) {
                        if (changeNameEmail == 1) {
                          gameProvider.myName = controller.text;
                        } else {
                          gameProvider.email = controller.text;
                        }
                        gameProvider.saveMyPersonalInfo();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('CHANGE'),
                  ),
                ),
                Padding(padding: const EdgeInsets.only(top: 5)),
                // For error messages
                Text("$postText", style: errorTextStyle,),
                Padding(padding: const EdgeInsets.only(top: 5)),
              ],
            ),
          ),
        )
      )
    );
  }
}
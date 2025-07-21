import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../data/styles.dart';
import '../data/urls.dart';
import '../providers/provider.dart';

class changePassword extends StatefulWidget {

  const changePassword({super.key});

  @override
  State<changePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<changePassword> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController controller3 = TextEditingController();
  SharedPreferences? prefs;

  String errOld = '';
  String errNew1 = '';
  String errNew2 = '';
  String postText = '';

  bool obscure1 = true;
  bool obscure2 = true;
  bool obscure3 = true;
  bool logSuccess = false;

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  void getInfo() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> changePassword(int id, String prev, String newP) async {

    // Use url from urls.dart file
    final url = Uri.parse(changePasswordUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'user_id': id,
        'prev_password': prev,
        'new_password': newP,
        'repeated_password': newP,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        logSuccess = true;
      });
    } else if (responseBody['detail'] == 'User not found') {
      setState(() {
        logSuccess = false;
        postText = Provider.of<GameProvider>(context).localizations!.getString('user_not_found', Provider.of<GameProvider>(context).languageCode);
      });
    } else if (responseBody['detail'] == 'Previous password is incorrect') {
      setState(() {
        logSuccess = false;
        postText = Provider.of<GameProvider>(context).localizations!.getString('incorrect_password', Provider.of<GameProvider>(context).languageCode);
      });
    } else if (responseBody['detail'] == 'Passwords do not match') {
      setState(() {
        logSuccess = false;
        postText = Provider.of<GameProvider>(context).localizations!.getString('passwords_do_not_match', Provider.of<GameProvider>(context).languageCode);
      });
    } 
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Dialog(
    child: Container(
      width: 352,
      height: 325,
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
                  Text(gameProvider.localizations!.getString("change_password_previous", gameProvider.languageCode), style: basicTextStyle,),
                  const Expanded(flex: 1, child: Text("")),
                  Text(errOld, style: errorTextStyle, textAlign: TextAlign.right),
                  Padding(padding: const EdgeInsets.only(right: 47)),
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
                child: TextField(
                  obscureText: obscure1,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure1 ? Icons.visibility : Icons.visibility_off,
                        color: grey3A3A3AColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscure1 = !obscure1;
                        });
                      },
                    ),
                  ),
                  controller: controller,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 17)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 47)),
                  Text(gameProvider.localizations!.getString("change_password_new", gameProvider.languageCode), style: basicTextStyle),
                  const Expanded(flex: 1, child: Text("")),
                  Text(errNew1, style: errorTextStyle, textAlign: TextAlign.right),
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
                  obscureText: obscure2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure2 ? Icons.visibility : Icons.visibility_off,
                        color: grey3A3A3AColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscure2 = !obscure2;
                        });
                      },
                    ),
                  ),
                  controller: controller2,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 17)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 47)),
                  Text(gameProvider.localizations!.getString("change_password_repeat", gameProvider.languageCode), style: basicTextStyle),
                  const Expanded(flex: 1, child: Text("")),
                  Text(errNew2, style: errorTextStyle, textAlign: TextAlign.right),
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
                  obscureText: obscure3,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure3 ? Icons.visibility : Icons.visibility_off,
                        color: grey3A3A3AColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscure3 = !obscure3;
                        });
                      },
                    ),
                  ),
                  controller: controller3,
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
                        errOld = '';
                        errNew1 = '';
                        errNew2 = '';
                      });
                      
                      // Check if all fields are filled
                      if (controller.text.isEmpty || controller2.text.isEmpty || controller3.text.isEmpty) {
                        setState(() {
                          postText = gameProvider.localizations!.getString("error_all_fields_required", gameProvider.languageCode);
                        });
                        return;
                      }
                      else if (controller.text.length > 16 || controller.text.length < 6) {
                        setState(() {
                          errOld = gameProvider.localizations!.getString("sign_up_error_password_length", gameProvider.languageCode);
                        });
                        return;
                      }
                      else if (controller2.text.length > 16 || controller2.text.length < 6) {
                        setState(() {
                          errNew1 = gameProvider.localizations!.getString("sign_up_error_password_length", gameProvider.languageCode);
                        });
                        return;
                      }
                      // Check if repeated password is valid
                      else if (controller2.text != controller3.text) {
                        setState(() {
                          errNew2 = gameProvider.localizations!.getString("sign_up_error_passwords_different", gameProvider.languageCode);
                        });
                        return;
                      } else {
                        await changePassword(gameProvider.myID, controller.text, controller2.text);
                        if (logSuccess) {
                          gameProvider.password = controller2.text;
                          gameProvider.saveMyPersonalInfo();
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text(gameProvider.localizations!.getString("change_pers_info_button", gameProvider.languageCode)),
                  ),
                ),
                Padding(padding: const EdgeInsets.only(top: 5)),
                // For error messages
                Text(postText, style: errorTextStyle,),
                Padding(padding: const EdgeInsets.only(top: 5)),
              ],
            ),
          ),
        )
      )
    );
  }
}
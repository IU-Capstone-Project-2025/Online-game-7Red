import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:email_validator/email_validator.dart';

import '../providers/provider.dart';
import '../data/styles.dart';
import '../data/urls.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for input fields
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController controller3 = TextEditingController();
  final TextEditingController controller4 = TextEditingController();

  // Variables for showing error messages in the UI
  String postText = '';
  String errNickname = '';
  String errEmail = '';
  String errPassword = '';
  String errRepeatedPassword = '';
  bool regSuccess = false;

  bool obscure = true;

  int ID = -1;

  /// Sends a POST request to the server to register a new user.
  ///
  /// If the registration is successful, it sets `regSuccess` to `true` and
  /// updates the `ID` field with the user's ID from the response.
  ///
  /// If the registration fails due to an already used email, it sets `regSuccess`
  /// to `false` and updates `errEmail` with an error message.

  Future<void> signUp(String nickname, String email, String password, String repeatedPassword) async {
    final url = Uri.parse('$signUpUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'nickname': nickname,
        'email': email,
        'password': password,
        'repeated_password': repeatedPassword,
      }),
    );
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        regSuccess = true;
        ID = responseBody['user_id'];
      });
    } else {
      setState(() {
        regSuccess = false;
        errEmail = Provider.of<GameProvider>(context).localizations!.getString('sign_up_error_email_already_in_use', Provider.of<GameProvider>(context).languageCode);
      });
    }
  }

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
              Padding(padding: const EdgeInsets.only(top: 15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  // Button to return to WelkomePage
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () {
                        gameProvider.toggleLanguage();
                      },
                      icon: const Icon(Icons.language, size: 44),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15)),
                ],
              ),
              // Red7 logo
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 115,
                height: 115,
              ),
              const Expanded(flex: 1, child: Text("")),
              Text(gameProvider.localizations!.getString('sign_up_title', gameProvider.languageCode), style: titleStyle),
              const Expanded(flex: 1, child: Text("")),
              Container(
                width: 352,
                height: 405,
                decoration: BoxDecoration(
                  color: backInvisColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: grey3A3A3AColor, width: 0.1),
                ),
                child: Column(
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 20)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 47)),
                        Text(gameProvider.localizations!.getString('nickname', gameProvider.languageCode), style: basicTextStyle,),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errNickname, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    // Input field for nickname
                    Container(
                      width: 260,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
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
                        Text(gameProvider.localizations!.getString('email', gameProvider.languageCode), style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errEmail, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    // Input field for email
                    Container(
                      width: 260,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
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
                        Text(gameProvider.localizations!.getString('password', gameProvider.languageCode), style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errPassword, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    // Input field for password
                    Container(
                      width: 260,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        obscureText: obscure,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility : Icons.visibility_off,
                              color: grey3A3A3AColor,
                            ),
                            onPressed: () {
                              setState(() {
                                obscure = !obscure;
                              });
                            },
                          ),
                        ),
                        controller: controller3,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 17)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 47)),
                        Text(gameProvider.localizations!.getString('sign_up_repeat_password', gameProvider.languageCode), style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errRepeatedPassword, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    // Input field for repeated password
                    Container(
                      width: 260,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        obscureText: obscure,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: controller4,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 20)),
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
                          onPressed: () async{
                            // Reset error messages
                            setState(() {
                              postText = '';
                              errNickname = '';
                              errEmail = '';
                              errPassword = '';
                              errRepeatedPassword = '';
                              regSuccess = false;
                            });
                            // Check if all fields are filled
                            if (controller.text.isEmpty || controller2.text.isEmpty || controller3.text.isEmpty || controller4.text.isEmpty) {
                              setState(() {
                                postText = gameProvider.localizations!.getString('error_all_fields_required', gameProvider.languageCode);
                              });
                              return;
                            }
                            // Check if nickname is valid
                            else if (controller.text.length > 10) {
                              setState(() {
                                errNickname = gameProvider.localizations!.getString('sign_up_error_nickname_length', gameProvider.languageCode);
                              });
                              return;
                            }
                            // Check if email is valid
                            else if (!EmailValidator.validate(controller2.text)) {
                              setState(() {
                                errEmail = gameProvider.localizations!.getString('sign_in_error_invalid_email', gameProvider.languageCode);
                              });
                              return;
                            }
                            // Check if password is valid
                            else if (controller3.text.length > 16 || controller3.text.length < 6) {
                              setState(() {
                                errPassword = gameProvider.localizations!.getString('sign_up_error_password_length', gameProvider.languageCode);
                              });
                              return;
                            }
                            // Check if repeated password is valid
                            else if (controller3.text != controller4.text) {
                              setState(() {
                                errRepeatedPassword = gameProvider.localizations!.getString('sign_up_error_passwords_different', gameProvider.languageCode);
                              });
                              return;
                            } 
                            else {
                              // If all fields are filled and valid, send http-request to sign up
                              await signUp(controller.text, controller2.text, controller3.text, controller4.text);
                              // If sign up was successful, navigate to main menu
                              if (regSuccess) {
                                gameProvider.myID = ID;
                                gameProvider.myName = controller.text;
                                gameProvider.email = controller2.text;
                                gameProvider.password = controller3.text;
                                gameProvider.saveMyPersonalInfo();
                                Navigator.pushNamed(context, '/mainmenu');
                              }
                            }
                          },
                          child: Text(gameProvider.localizations!.getString('sign_up_botton', gameProvider.languageCode)),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Text(postText, style: errorTextStyle,),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                  ],
                ),
              ),
              const Expanded(flex: 7, child: Text("")),
            ],
          ),
        ),
      ),
    );
  }
}
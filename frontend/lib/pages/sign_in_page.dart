import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:email_validator/email_validator.dart';

import '../providers/provider.dart';
import '../data/styles.dart';
import '../data/urls.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Controllers for email and password
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  // Fields for showing info and errors in the UI
  String postText = '';
  String errEmail = '';
  bool logSuccess = false;
  
  String nickname = 'None';
  int ID = -1;

  bool obscure = true;

  /// Sends a POST request to the server to sign in the user.
  ///
  /// If the request is successful, it sets `logSuccess` to `true` and
  /// updates the `nickname` and `ID` fields with the values from the response.
  ///
  /// If the request fails, it sets `logSuccess` to `false` and sets `postText`
  /// to an error message.
  Future<void> signIn(String email, String password) async {
    // Use url from urls.dart file
    final url = Uri.parse('$signInUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        nickname = responseBody['nickname'];
        ID = responseBody['user_id'];
        logSuccess = true;
      });
    } else {
      setState(() {
        logSuccess = false;
        postText = Provider.of<GameProvider>(context).localizations!.getString('sign_in_error_invalid_credentials', Provider.of<GameProvider>(context).languageCode);
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
                        Navigator.pushNamed(context, '/');
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 44),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                ],
              ),
              // Show Logo
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 115,
                height: 115,
              ),
              const Expanded(flex: 1, child: Text("")),
              Text(gameProvider.localizations!.getString("sign_in_title", gameProvider.languageCode), style: titleStyle),
              const Expanded(flex: 1, child: Text("")),
              Container(
                width: 352,
                height: 250,
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
                        Text(gameProvider.localizations!.getString("email", gameProvider.languageCode), style: basicTextStyle,),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errEmail, style: errorTextStyle, textAlign: TextAlign.right),
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
                        Text(gameProvider.localizations!.getString("password", gameProvider.languageCode), style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
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
                        controller: controller2,
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
                              errEmail = '';
                            });
                            // Check if all fields are filled
                            if (controller.text.isEmpty || controller2.text.isEmpty) {
                              setState(() {
                                postText = gameProvider.localizations!.getString("error_all_fields_required", gameProvider.languageCode);
                              });
                              return;
                            } else if (!EmailValidator.validate(controller.text)) { // Check if email is valid
                              setState(() {
                                errEmail = gameProvider.localizations!.getString("sign_in_error_invalid_email", gameProvider.languageCode);
                              });
                              return;
                            } else {
                              // If all fields are filled and email is valid, send http-request to sign in
                              await signIn(controller.text, controller2.text);
                              // If sign in was successful, navigate to main menu
                              if (logSuccess) {
                                gameProvider.myID = ID;
                                gameProvider.myName = nickname;
                                gameProvider.email = controller.text;
                                gameProvider.password = controller2.text;
                                gameProvider.saveMyPersonalInfo();
                                Navigator.pushNamed(context, '/mainmenu');
                              }
                            }
                          },
                          child: Text(gameProvider.localizations!.getString("sign_in_botton", gameProvider.languageCode)),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      // For error messages
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

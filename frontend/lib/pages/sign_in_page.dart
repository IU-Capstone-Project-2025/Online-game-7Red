import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../providers/provider.dart';
import '../data/styles.dart';
import '../data/urls.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  String postText = '';
  String errEmail = '';
  bool logSuccess = false;
  
  String nickname = 'None';
  int ID = -1;

  Future<void> signIn(String email, String password) async {
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
        postText = 'Invalid email or password';
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
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 115,
                height: 115,
              ),
              const Expanded(flex: 1, child: Text("")),
              Text("Sign in to Red7", style: titleStyle),
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
                        Text("Email address", style: basicTextStyle,),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errEmail, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
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
                        Text("Password", style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
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
                          onPressed: () async {
                            setState(() {
                              postText = '';
                              errEmail = '';
                            });
                            if (controller.text.isEmpty || controller2.text.isEmpty) {
                              setState(() {
                                postText = 'All fields are required';
                              });
                              return;
                            } else if ((controller.text.contains('@') && controller.text.contains('.')) == false) {
                              setState(() {
                                errEmail = 'Invalid email';
                              });
                              return;
                            } else {
                              await signIn(controller.text, controller2.text);
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
                          child: const Text('SIGN  IN'),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 5)),
                      Text("$postText", style: errorTextStyle,),
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

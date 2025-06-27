import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../providers/provider.dart';
import '../data/styles.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController controller3 = TextEditingController();
  final TextEditingController controller4 = TextEditingController();

  String postText = '';
  String errNickname = '';
  String errEmail = '';
  String errPassword = '';
  String errRepeatedPassword = '';
  bool regSuccess = false;

  int ID = -1;

  Future<void> signUp(String nickname, String email, String password, String repeatedPassword) async {
    final url = Uri.parse('http://192.145.30.253:8000/auth/signup');
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
        errEmail = '(already in use)';
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
                width: 140,
                height: 140,
              ),
              const Expanded(flex: 1, child: Text("")),
              Text("Sign up to Red7", style: titleStyle),
              const Expanded(flex: 1, child: Text("")),
              Container(
                width: 420,
                height: 508,
                decoration: BoxDecoration(
                  color: backInvisColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: grey3A3A3AColor, width: 0.1),
                ),
                child: Column(
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 30)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 47)),
                        Text("Nickname", style: basicTextStyle,),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errNickname, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    Container(
                      width: 327,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: controller,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 30)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 47)),
                        Text("Email address", style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errEmail, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    Container(
                      width: 327,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: controller2,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 30)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 47)),
                        Text("Password", style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errPassword, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    Container(
                      width: 327,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: controller3,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 30)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 47)),
                        Text("Repeat password", style: basicTextStyle),
                        const Expanded(flex: 1, child: Text("")),
                        Text(errRepeatedPassword, style: errorTextStyle, textAlign: TextAlign.right),
                        Padding(padding: const EdgeInsets.only(right: 47)),
                      ]
                    ),
                    Padding(padding: const EdgeInsets.only(top: 5)),
                    Container(
                      width: 327,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: controller4,
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 30)),
                    SizedBox(
                        width: 327,
                        height: 40,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            side: WidgetStateProperty.all<BorderSide>(
                              BorderSide(color: grey3A3A3AColor, width: 1),
                            ),
                          ),
                          onPressed: () async{
                            setState(() {
                              postText = '';
                              errNickname = '';
                              errEmail = '';
                              errPassword = '';
                              errRepeatedPassword = '';
                              regSuccess = false;
                            });
                            if (controller.text.isEmpty || controller2.text.isEmpty || controller3.text.isEmpty || controller4.text.isEmpty) {
                              setState(() {
                                postText = 'All fields are required';
                              });
                              return;
                            }
                            else if (controller.text.length > 10) {
                              setState(() {
                                errNickname = '(1-10 symbols)';
                              });
                              return;
                            }
                            else if (controller3.text.length > 10 || controller3.text.length < 6) {
                              setState(() {
                                errPassword = '(6-10 symbols)';
                              });
                              return;
                            } 
                            else if (controller3.text != controller4.text) {
                              setState(() {
                                errRepeatedPassword = '(passwords different)';
                              });
                              return;
                            } 
                            else {
                              await signUp(controller.text, controller2.text, controller3.text, controller4.text);
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
                          child: const Text('SIGN  UP'),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(top: 10)),
                      Text("$postText", style: errorTextStyle,),


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
import 'package:flutter/material.dart';
import '../data/styles.dart';
// import '../services/remote_service.dart';
// import '../models/post.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';



class WelkomePage extends StatefulWidget {
  const WelkomePage({super.key});

  @override
  State<WelkomePage> createState() => _WelkomePageState();
}

class _WelkomePageState extends State<WelkomePage> {
  String postText = 'none of response';

  Future<void> signUp(String nickname, String email, String password, String repeatedPassword) async {
    final url = Uri.parse('http://localhost:8000/auth/signup');
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Registration successful: ${response.body}');
      setState(() {
        postText = 'Registration successful: ${response.body}';
      });
    } else {
      print('Registration failed: ${response.body}');
      setState(() {
        postText = 'Registration failed: ${response.body}';
      });
    }
  }


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
              const Expanded(flex: 5, child: Text("")),
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 200,
                height: 200,
              ),
              const Expanded(flex: 2, child: Text("")),
              Text("Welcome to the game!", style: titleStyle),
              const Expanded(flex: 1, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 335,
                        height: 48,
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
                          onPressed: () {
                            Navigator.of(context).pushNamed('/signin');
                          },
                          child: const Text('SIGN  IN'),
                        ),
                      ),
                      Text(""),
                      Text(
                        "If you already have an account",
                        style: basicTextStyle,
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(left: 80)),
                  Container(width: 1, height: 150, color: Colors.black),
                  Padding(padding: EdgeInsets.only(left: 80)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 335,
                        height: 50,
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
                          onPressed: () {
                            Navigator.of(context).pushNamed('/signup');
                          },
                          child: const Text('SIGN  UP'),
                        ),
                      ),
                      Text(""),
                      Text(
                        "If you want to create an account",
                        style: basicTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
              const Expanded(flex: 4, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 50,
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
                      onPressed: () {
                        signUp('nickname', 'anastasia.shlomov@gmail.com', 'password', 'password');
                      },
                      child: const Text('Test post to backend'),
                    ),
                  ),
                  Padding(padding: EdgeInsets.only(left: 30)),
                  Text(
                    "${postText}",
                    style: basicTextStyle,
                  ),
                  Padding(padding: EdgeInsets.only(left: 30)),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/mainmenu');
                      },
                      icon: const Icon(Icons.skip_next, size: 44),
                    ),
                  ),
                ]
              )
            ],
          ),
        ),
      ),
    );
  }
}

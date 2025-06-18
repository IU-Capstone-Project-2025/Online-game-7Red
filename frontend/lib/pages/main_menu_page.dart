import 'package:flutter/material.dart';
import '../data/styles.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
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
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/');
                      },
                      icon: const Icon(Icons.door_back_door_outlined, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        //pass to settings
                      },
                      icon: const Icon(Icons.settings, size: 60),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15)),
                ],
              ),
              Expanded(flex: 1, child: Text("")),
              Image(
                image: AssetImage('lib/assets/logo.png'),
                width: 200,
                height: 200,
              ),
              Expanded(flex: 1, child: Text("")),
              SizedBox(
                width: 321,
                height: 64,
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
                    showDialog(context: context, builder: (context) {
                    return Dialog(
                      child:
                        Container(
                          width: 1000,
                          height: 336,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('lib/assets/background.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: grey3A3A3AColor, width: 0.1),
                          ),
                          child:
                            Container(
                              width: 1000,
                              height: 336,
                              decoration: BoxDecoration(
                                color: backInvisColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: grey3A3A3AColor, width: 0.1),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 155,
                                    height: 155,
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
                                        Navigator.of(context).pop();
                                        //pass;
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.create, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Create private room", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 155,
                                    height: 155,
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
                                        Navigator.of(context).pop();
                                        showDialog(context: context, builder: (context) {
                                          return Dialog(
                                            child:
                                              Container(
                                                width: 420,
                                                height: 308,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: AssetImage('lib/assets/background.jpg'),
                                                    fit: BoxFit.cover,
                                                  ),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: grey3A3A3AColor, width: 0.1),
                                                ),
                                                child:
                                                  Container(
                                                    width: 420,
                                                    height: 308,
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
                                                            Text("ID of the game-room", style: basicTextStyle,),
                                                            const Expanded(flex: 1, child: Text("")),
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
                                                            Text("Password", style: basicTextStyle),
                                                            const Expanded(flex: 1, child: Text("")),
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
                                                              onPressed: () {
                                                                if (controller.text.isEmpty || controller2.text.isEmpty) {
                                                                  return;
                                                                } else {
                                                                  Navigator.of(context).pushNamed('/');
                                                                }
                                                              },
                                                              child: const Text('SIGN  IN'),
                                                            ),
                                                          ),

                                                      ],
                                                    ),
                                                  ),
                                              )
                                          );
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.key, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Connect private room", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 155,
                                    height: 155,
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
                                        Navigator.of(context).pop();
                                        //pass;
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.search, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Random opponents", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                  SizedBox(
                                    width: 155,
                                    height: 155,
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
                                        Navigator.of(context).pop();
                                        //pass;
                                      },
                                      child: Column(
                                        children: [
                                          const Expanded(flex: 1, child: Text(""),),
                                          Icon(Icons.smart_toy, size: 80),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Text("Vs Bot", style: buttonTextStyle, textAlign: TextAlign.center,),
                                          const Expanded(flex: 1, child: Text(""),),
                                          Padding(padding: const EdgeInsets.only(bottom: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 1, child: Text(""),),
                                ],
                              ),
                            ),
                          ),
                    );
                    }
                  );
                  },
                  child: const Text('START NEW GAME'),
                ),
              ),
              Expanded(flex: 4, child: Text("")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: const EdgeInsets.only(left: 15)),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        // pass
                      },
                      icon: const Icon(Icons.help_outline, size: 60),
                    ),
                  ),
                  const Expanded(flex: 1, child: Text("")),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: IconButton(
                      onPressed: () {
                        //pass to settings
                      },
                      icon: const Icon(Icons.emoji_events_outlined, size: 60),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(left: 15)),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: 15)),
            ],
          ),
        ),
      ),
    );          
  }
}
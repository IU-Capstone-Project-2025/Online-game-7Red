import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../data/styles.dart';
import '../providers/provider.dart';
import '../data/urls.dart';

class ConnectDialog extends StatefulWidget {
  final GameProvider gameProvider;

  const ConnectDialog({super.key, required this.gameProvider});

  @override
  State<ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<ConnectDialog> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  String postText = '';
  bool logSuccess = false;

  Future<void> connectToRoom(int id, String room_id, String password) async {
    final url = Uri.parse('$joinRoomUrl');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: jsonEncode({
        'assigned_id': room_id,
        'password': password,
        'user_id': id,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        logSuccess = true;
      });
    } else {
      setState(() {
        logSuccess = false;
        postText = 'Invalid ID or Password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 420,
        height: 308,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('lib/assets/background.jpg'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: grey3A3A3AColor, width: 0.1),
        ),
        child: Container(
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
                  onPressed: () async {
                    setState(() {
                      postText = '';
                      logSuccess = false;
                    });
                    
                    if (controller.text.isEmpty || controller2.text.isEmpty) {
                      setState(() {
                        postText = "All fields are required";
                      });
                      return;
                    }
                    
                    await connectToRoom(widget.gameProvider.myID, controller.text, controller2.text);
                    if (logSuccess) {
                      widget.gameProvider.roomId = controller.text;
                      widget.gameProvider.roomPassword = controller2.text;
                      widget.gameProvider.saveRoomInfo();
                      Navigator.pushNamed(context, '/waitingroom');
                    }
                  },
                  child: const Text('CONNECT'),
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 10)),
              Text(postText, style: errorTextStyle),
            ],
          ),
        ),
      ),
    );
  }
}





// Dialog(
//   child:
//     Container(
//       width: 420,
//       height: 308,
//       decoration: BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage('lib/assets/background.jpg'),
//           fit: BoxFit.cover,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: grey3A3A3AColor, width: 0.1),
//       ),
//       child:
//         Container(
//           width: 420,
//           height: 308,
//           decoration: BoxDecoration(
//             color: backInvisColor,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: grey3A3A3AColor, width: 0.1),
//           ),
//           child: Column(



//             children: [
//               Padding(padding: const EdgeInsets.only(top: 30)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Padding(padding: const EdgeInsets.only(left: 47)),
//                   Text("ID of the game-room", style: basicTextStyle,),
//                   const Expanded(flex: 1, child: Text("")),
//                 ]
//               ),
//               Padding(padding: const EdgeInsets.only(top: 5)),
//               Container(
//                 width: 327,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: TextField(
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   controller: controller,
//                 ),
//               ),
//               Padding(padding: const EdgeInsets.only(top: 30)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Padding(padding: const EdgeInsets.only(left: 47)),
//                   Text("Password", style: basicTextStyle),
//                   const Expanded(flex: 1, child: Text("")),
//                 ]
//               ),
//               Padding(padding: const EdgeInsets.only(top: 5)),
//               Container(
//                 width: 327,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: TextField(
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   controller: controller2,
//                 ),
//               ),
//               Padding(padding: const EdgeInsets.only(top: 30)),



//               SizedBox(
//                   width: 327,
//                   height: 40,
//                   child: ElevatedButton(
//                     style: ButtonStyle(
//                       backgroundColor: WidgetStateProperty.all<Color>(
//                         buttonColor,
//                       ),
//                       textStyle: WidgetStateProperty.all<TextStyle>(
//                         buttonTextStyle,
//                       ),
//                       foregroundColor: WidgetStateProperty.all<Color>(
//                         grey3A3A3AColor,
//                       ),
//                       shape:
//                           WidgetStateProperty.all<RoundedRectangleBorder>(
//                             RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                       side: WidgetStateProperty.all<BorderSide>(
//                         BorderSide(color: grey3A3A3AColor, width: 1),
//                       ),
//                     ),
//                     onPressed: () async{
//                       setState(() {
//                         postText = '';
//                         logSuccess = false;
//                       });
//                       if (controller.text.isEmpty || controller2.text.isEmpty) {
//                         setState(() {
//                           postText = "All fields are required";
//                         }); // ???? WTF Почему не всплывает?..
//                         // await Future.delayed(Duration.zero);
//                         return;
//                       } else {
//                         await connectToRoom(gameProvider.myID, controller.text, controller2.text);
//                         if (logSuccess) {
//                           gameProvider.roomId = controller.text;
//                           gameProvider.roomPassword = controller2.text;
//                           gameProvider.saveRoomInfo();
//                           Navigator.pushNamed(context, '/waitingroom');
//                         }
//                       }
//                     },
//                     child: const Text('CONNECT'),
//                   ),
//                 ),
//                 Padding(padding: const EdgeInsets.only(top: 10)),
//                 Text(postText, style: errorTextStyle,),

//             ],
//           ),
//         ),
//     )
// );
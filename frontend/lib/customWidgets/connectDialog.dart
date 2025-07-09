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

// Class for connecting to the private room from MainMenuPage
class _ConnectDialogState extends State<ConnectDialog> {
  // Controllers for control text field's value
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  // For errors
  String postText = '';
  bool logSuccess = false;

  bool obscure = true;

  
  /// Connects the user to a game room using the provided room ID and password.
  ///
  /// Sends a POST request to the join room URL with the user's ID, the room ID,
  /// and the password. If the connection is successful (status code 200), 
  /// updates the `logSuccess` state to true. If an error occurs, updates 
  /// `logSuccess` to false and sets an appropriate error message in `postText`.
  /// Possible error messages include:
  /// - 'Game already started' if the game has already begun.
  /// - 'User already in the room' if the user is trying to join a room they are already in.
  /// - 'Room is full' if the room has reached its player limit.
  /// - 'Invalid ID or Password' for other errors.

  Future<void> connectToRoom(int id, String room_id, String password) async {

    // Use url from urls.dart file
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

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        logSuccess = true;
      });
    } else if (responseBody['detail'] == 'Game already started') {
      setState(() {
        logSuccess = false;
        postText = 'Game already started';
      });
    } else if (responseBody['detail'] == 'User already in the room') {
      setState(() {
        logSuccess = false;
        postText = 'User already in the room';
      });
    } else if (responseBody['detail'] == 'Room is full') {
      setState(() {
        logSuccess = false;
        postText = 'Room is full';
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
            // Add background with image
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
              // Text field for entering the room ID
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
              // Text field for entering the password
              Container(
                width: 327,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  obscureText: obscure,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
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
                    // Reset the error message
                    setState(() {
                      postText = '';
                      logSuccess = false;
                    });
                    // Check if the text fields are empty
                    if (controller.text.isEmpty || controller2.text.isEmpty) {
                      setState(() {
                        postText = "All fields are required";
                      });
                      return;
                    }
                    // Send http-request to connect to the room
                    await connectToRoom(widget.gameProvider.myID, controller.text, controller2.text);
                    // If the connection was successful, navigate to the waiting room
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

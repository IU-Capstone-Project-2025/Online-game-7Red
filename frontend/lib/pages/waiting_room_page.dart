// import 'package:flutter/material.dart';
// import '../data/styles.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class WaitingRoomPage extends StatefulWidget {
//   const WaitingRoomPage({super.key});

//   @override
//   State<WaitingRoomPage> createState() => _WaitingRoomPageState();
// }

// class _WaitingRoomPageState extends State<WaitingRoomPage> {

//   String postText = '';
//   bool logSuccess = false;

//   Future<void> checkIncomers(String email, String password) async {
//     final url = Uri.parse('http://localhost:8000/auth/signin');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
//       body: jsonEncode({
//         'email': email,
//         'password': password,
//       }),
//     );

//     if (response.statusCode == 200) {
//       setState(() {
//         logSuccess = true;
//       });
//     } else {
//       setState(() {
//         logSuccess = false;
//         postText = 'Invalid email or password';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('lib/assets/background.jpg'),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Padding(padding: const EdgeInsets.only(top: 15)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Padding(padding: const EdgeInsets.only(left: 15)),
//                   SizedBox(
//                     width: 60,
//                     height: 60,
//                     child: IconButton(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/');
//                       },
//                       icon: const Icon(Icons.arrow_back_rounded, size: 44),
//                     ),
//                   ),
//                   const Expanded(flex: 1, child: Text("")),
//                 ],
//               ),
//               Image(
//                 image: AssetImage('lib/assets/logo.png'),
//                 width: 140,
//                 height: 140,
//               ),
//               const Expanded(flex: 1, child: Text("")),
//               Text("Sign in to Red7", style: titleStyle),
//               const Expanded(flex: 1, child: Text("")),
//               Container(
//                 width: 420,
//                 height: 308,
//                 decoration: BoxDecoration(
//                   color: backInvisColor,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: grey3A3A3AColor, width: 0.1),
//                 ),
//                 child: Column(
//                   children: [
//                     Padding(padding: const EdgeInsets.only(top: 30)),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Padding(padding: const EdgeInsets.only(left: 47)),
//                         Text("Email address", style: basicTextStyle,),
//                         const Expanded(flex: 1, child: Text("")),
//                       ]
//                     ),
//                     Padding(padding: const EdgeInsets.only(top: 5)),
//                     Container(
//                       width: 327,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         controller: controller,
//                       ),
//                     ),
//                     Padding(padding: const EdgeInsets.only(top: 30)),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Padding(padding: const EdgeInsets.only(left: 47)),
//                         Text("Password", style: basicTextStyle),
//                         const Expanded(flex: 1, child: Text("")),
//                       ]
//                     ),
//                     Padding(padding: const EdgeInsets.only(top: 5)),
//                     Container(
//                       width: 327,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: TextField(
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         controller: controller2,
//                       ),
//                     ),
//                     Padding(padding: const EdgeInsets.only(top: 30)),
//                     SizedBox(
//                         width: 327,
//                         height: 40,
//                         child: ElevatedButton(
//                           style: ButtonStyle(
//                             backgroundColor: WidgetStateProperty.all<Color>(
//                               buttonColor,
//                             ),
//                             textStyle: WidgetStateProperty.all<TextStyle>(
//                               buttonTextStyle,
//                             ),
//                             foregroundColor: WidgetStateProperty.all<Color>(
//                               grey3A3A3AColor,
//                             ),
//                             shape:
//                                 WidgetStateProperty.all<RoundedRectangleBorder>(
//                                   RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                             side: WidgetStateProperty.all<BorderSide>(
//                               BorderSide(color: grey3A3A3AColor, width: 1),
//                             ),
//                           ),
//                           onPressed: () async {
//                             setState(() {
//                               postText = '';
//                             });
//                             if (controller.text.isEmpty || controller2.text.isEmpty) {
//                               setState(() {
//                                 postText = 'All fields are required';
//                               });
//                               return;
//                             } else {
//                               await signIn(controller.text, controller2.text);
//                               if (logSuccess) {
//                                 Navigator.pushNamed(context, '/mainmenu');
//                               }
//                             }
//                           },
//                           child: const Text('SIGN  IN'),
//                         ),
//                       ),
//                       Padding(padding: const EdgeInsets.only(top: 10)),
//                       Text("$postText", style: errorTextStyle,),

//                   ],
//                 ),
//               ),
//               const Expanded(flex: 7, child: Text("")),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/provider.dart';
import 'pages/welkome_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/main_menu_page.dart';
import 'pages/waiting_room_page.dart';
import 'pages/game_page.dart';
import 'pages/result_page.dart';
import 'pages/rules_page.dart';
import 'pages/statistics_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // Add provider to share data between pages
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GameProvider())],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      initialRoute: '/',
      routes: {
        '/': (context) => WelkomePage(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/mainmenu': (context) => MainMenuPage(),
        '/waitingroom': (context) => WaitingRoomPage(),
        '/gameroom': (context) => GameRoomPage(),
        '/result': (context) => ResultPage(),
        '/rules': (context) => RulesPage(),
        '/statistics': (context) => StatisticsPage(),
      },
    );
  }

}

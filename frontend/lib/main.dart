import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/provider.dart';
import 'pages/welkome_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DayProvider())],
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
      },
    );
  }

}

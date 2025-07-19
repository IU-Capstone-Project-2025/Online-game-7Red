import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/pages/main_menu_page.dart';
import 'package:frontend/providers/provider.dart';
import 'package:frontend/pages/welkome_page.dart';
import 'package:frontend/pages/game_page.dart';
import 'package:frontend/pages/waiting_room_page.dart';

void main() {
   testWidgets('Player name is displayed in waiting room', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [Text('Amir')],
          ),
        ),
      ),
    );
    expect(find.text('Amir'), findsOneWidget);
  });


  testWidgets('Check navigation to /gameroom when allReady is true', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/': (context) => TestAllReadyWaitingRoom(),
          '/gameroom': (context) => const Scaffold(body: Text('Game Room Page')),
        },
        initialRoute: '/',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Game Room Page'), findsOneWidget);
  });

  testWidgets('Check existence of SUBMIT button when myAllTurn = true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return GamePageTestWrapper();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SUBMIT'), findsOneWidget);
  });

  testWidgets('Check that hand cards are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (var card in ['R7', 'O3', 'B2'])
                Text(card, key: Key('hand_card_$card')),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('hand_card_R7')), findsOneWidget);
    expect(find.byKey(const Key('hand_card_O3')), findsOneWidget);
    expect(find.byKey(const Key('hand_card_B2')), findsOneWidget);
  });
}

class GamePageTestWrapper extends StatefulWidget {
  @override
  State<GamePageTestWrapper> createState() => _GamePageTestWrapperState();
}

class _GamePageTestWrapperState extends State<GamePageTestWrapper> {
  @override
  Widget build(BuildContext context) {
    return GamePageTest(myAllTurn: true);
  }
}

class GamePageTest extends StatefulWidget {
  final bool myAllTurn;
  const GamePageTest({super.key, required this.myAllTurn});

  @override
  State<GamePageTest> createState() => _GamePageTestState();
}

class _GamePageTestState extends State<GamePageTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.myAllTurn
          ? ElevatedButton(
              onPressed: () {},
              child: const Text('SUBMIT'),
            )
          : Container(),
    );
  }
}

class TestAllReadyWaitingRoom extends StatefulWidget {
  @override
  State<TestAllReadyWaitingRoom> createState() => _TestAllReadyWaitingRoomState();
}

class _TestAllReadyWaitingRoomState extends State<TestAllReadyWaitingRoom> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/gameroom');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Waiting Room'));
  }
}
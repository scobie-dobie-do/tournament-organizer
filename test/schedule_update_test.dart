import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_organizer/models/player.dart';
import 'package:tournament_organizer/logic/tournament_logic.dart';
import 'package:tournament_organizer/screens/match_list_screen.dart';

void main() {
  testWidgets('Schedule updates after save', (WidgetTester tester) async {
    // 1. Setup
    final p1 = Player(id: '1', name: 'A', teamName: 'T1');
    final p2 = Player(id: '2', name: 'B', teamName: 'T2');
    final state = TournamentState(
      id: 'test_t',
      name: 'Test T',
      players: [p1, p2],
      format: TournamentFormat.roundRobin,
    );

    // Mock DB service to avoid Hive crash
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MatchListScreen(tournamentState: state),
      ),
    ));

    await tester.pumpAndSettle();

    // Verify initial state
    expect(find.text('vs'), findsOneWidget);

    // Tap on the match
    await tester.tap(find.text('vs'));
    await tester.pumpAndSettle();

    // Tap increment for home goals
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    // Tap save result
    await tester.tap(find.text('Save Result'));
    await tester.pumpAndSettle();

    // Tap save in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    // We should be back on MatchListScreen
    expect(find.text('Match Details'), findsNothing);
    
    // The UI should show the score
    expect(find.text('vs'), findsNothing);
  });
}

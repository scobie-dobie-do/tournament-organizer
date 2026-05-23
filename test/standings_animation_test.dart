import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_organizer/models/player.dart';
import 'package:tournament_organizer/models/match.dart';
import 'package:tournament_organizer/logic/tournament_logic.dart';
import 'package:tournament_organizer/logic/standings_calculator.dart';
import 'package:tournament_organizer/screens/standings_screen.dart';

void main() {
  group('StandingsCalculator Tests', () {
    test('calculate sorts by points, GD, GF, and name', () {
      final p1 = Player(id: '1', name: 'A', teamName: 'T1');
      final p2 = Player(id: '2', name: 'B', teamName: 'T2');
      final p3 = Player(id: '3', name: 'C', teamName: 'T3');

      // T1: 3 pts, GD +2 (GF 3, GA 1)
      // T2: 3 pts, GD +1 (GF 2, GA 1)
      // T3: 0 pts, GD -3 (GF 1, GA 4)
      final matches = [
        TournamentMatch(
          id: 'm1',
          player1: p1,
          player2: p3,
          homeGoals: 3,
          awayGoals: 1,
          isCompleted: true,
          winner: p1,
        ),
        TournamentMatch(
          id: 'm2',
          player1: p2,
          player2: p3,
          homeGoals: 2,
          awayGoals: 1,
          isCompleted: true,
          winner: p2,
        ),
      ];

      final standings = StandingsCalculator.calculate([p1, p2, p3], matches);

      expect(standings.length, 3);
      expect(standings[0].team.id, '1'); // T1 is 1st (better GD)
      expect(standings[1].team.id, '2'); // T2 is 2nd
      expect(standings[2].team.id, '3'); // T3 is 3rd
    });

    test('calculateForm returns last 5 matches form correctly', () {
      final p1 = Player(id: '1', name: 'A', teamName: 'T1');
      final p2 = Player(id: '2', name: 'B', teamName: 'T2');

      final matches = [
        TournamentMatch(id: '1', player1: p1, player2: p2, homeGoals: 2, awayGoals: 1, isCompleted: true), // W
        TournamentMatch(id: '2', player1: p1, player2: p2, homeGoals: 1, awayGoals: 1, isCompleted: true), // D
        TournamentMatch(id: '3', player1: p1, player2: p2, homeGoals: 0, awayGoals: 3, isCompleted: true), // L
        TournamentMatch(id: '4', player1: p1, player2: p2, homeGoals: 3, awayGoals: 0, isCompleted: true), // W
        TournamentMatch(id: '5', player1: p1, player2: p2, homeGoals: 1, awayGoals: 2, isCompleted: true), // L
        TournamentMatch(id: '6', player1: p1, player2: p2, homeGoals: 4, awayGoals: 1, isCompleted: true), // W
      ];

      // T1's matches are:
      // 1: W
      // 2: D
      // 3: L
      // 4: W
      // 5: L
      // 6: W
      // Last 5: D, L, W, L, W
      final form = StandingsCalculator.calculateForm(p1, matches);
      expect(form, ['D', 'L', 'W', 'L', 'W']);
    });
  });

  group('StandingsScreen Widget Tests', () {
    testWidgets('StandingsScreen renders standings and podium correctly', (WidgetTester tester) async {
      final p1 = Player(id: '1', name: 'A', teamName: 'T1');
      final p2 = Player(id: '2', name: 'B', teamName: 'T2');
      final p3 = Player(id: '3', name: 'C', teamName: 'T3');

      final state = TournamentState(
        id: 'test_t',
        name: 'Test T',
        players: [p1, p2, p3],
        format: TournamentFormat.roundRobin,
      );

      // Record a match result so we have standings data
      state.recordMatchResult(state.matches.first.id, 2, 1);

      await tester.pumpWidget(MaterialApp(
        home: StandingsScreen(tournamentState: state),
      ));

      await tester.pumpAndSettle();

      // Check title
      expect(find.text('League Standings'), findsOneWidget);

      // Check header cells
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('PTS'), findsOneWidget);
      expect(find.text('Form'), findsOneWidget);

      // Check team names are rendered in the podium/table
      expect(find.text('T1'), findsNWidgets(2)); // Once in podium, once in table row
      expect(find.text('T2'), findsNWidgets(2));
      expect(find.text('T3'), findsNWidgets(2));

      // Verify podium columns show "1st", "2nd", "3rd"
      expect(find.text('1st'), findsOneWidget);
      expect(find.text('2nd'), findsOneWidget);
      expect(find.text('3rd'), findsOneWidget);
    });
  });
}

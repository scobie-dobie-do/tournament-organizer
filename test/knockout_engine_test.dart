import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_organizer/models/match.dart';
import 'package:tournament_organizer/models/player.dart';
import 'package:tournament_organizer/logic/knockout_engine.dart';

void main() {
  group('KnockoutEngine Tests', () {
    final p1 = Player(id: '1', teamName: 'Team 1');
    final p2 = Player(id: '2', teamName: 'Team 2');
    final p3 = Player(id: '3', teamName: 'Team 3');
    final p4 = Player(id: '4', teamName: 'Team 4');
    final p5 = Player(id: '5', teamName: 'Team 5');
    final p6 = Player(id: '6', teamName: 'Team 6');

    test('canAdvance returns false when matches are incomplete', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: false),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: false),
      ];

      expect(KnockoutEngine.canAdvance(matches, 1), isFalse);
    });

    test('canAdvance returns false when winner is null', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: null),
      ];

      expect(KnockoutEngine.canAdvance(matches, 1), isFalse);
    });

    test('canAdvance returns true when all matches are completed with winners', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: true, winner: p3),
      ];

      expect(KnockoutEngine.canAdvance(matches, 1), isTrue);
    });

    test('generateNextRound works correctly for even number of winners (4 winners)', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: true, winner: p3),
      ];

      final nextRound = KnockoutEngine.generateNextRound(matches: matches, currentRoundIndex: 1);

      expect(nextRound.length, 1);
      expect(nextRound[0].roundIndex, 2);
      expect(nextRound[0].player1, p1);
      expect(nextRound[0].player2, p3);
      expect(nextRound[0].isBye, isFalse);
      expect(nextRound[0].isCompleted, isFalse);
    });

    test('generateNextRound works correctly when winners count is odd (6 players -> 3 winners -> 1 carried over)', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: true, winner: p3),
        TournamentMatch(id: 'ko_1_2', player1: p5, player2: p6, roundIndex: 1, isCompleted: true, winner: p5),
      ];

      final nextRound = KnockoutEngine.generateNextRound(matches: matches, currentRoundIndex: 1);

      expect(nextRound.length, 1);
      expect(nextRound[0].roundIndex, 2);
      expect(nextRound[0].player1, p1);
      expect(nextRound[0].player2, p3);
      expect(nextRound[0].isBye, isFalse);
      expect(nextRound[0].isCompleted, isFalse);
    });

    test('generateNextRound carries over unpaired winner to next round matches (6 players -> Round 2 -> Round 3)', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: true, winner: p3),
        TournamentMatch(id: 'ko_1_2', player1: p5, player2: p6, roundIndex: 1, isCompleted: true, winner: p5),
        TournamentMatch(id: 'ko_2_0', player1: p1, player2: p3, roundIndex: 2, isCompleted: true, winner: p1),
      ];

      final nextRound = KnockoutEngine.generateNextRound(matches: matches, currentRoundIndex: 2);

      expect(nextRound.length, 1);
      expect(nextRound[0].roundIndex, 3);
      expect(nextRound[0].player1, p1);
      expect(nextRound[0].player2, p5);
      expect(nextRound[0].isBye, isFalse);
      expect(nextRound[0].isCompleted, isFalse);
    });

    test('isCompleted returns false when matches in round 2 are completed but carried over player exists', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: true, winner: p3),
        TournamentMatch(id: 'ko_1_2', player1: p5, player2: p6, roundIndex: 1, isCompleted: true, winner: p5),
        TournamentMatch(id: 'ko_2_0', player1: p1, player2: p3, roundIndex: 2, isCompleted: true, winner: p1),
      ];

      expect(KnockoutEngine.isCompleted(matches, 2), isFalse);
    });

    test('isCompleted returns true on final round completion', () {
      final matches = [
        TournamentMatch(id: 'ko_2_0', player1: p1, player2: p3, roundIndex: 2, isCompleted: true, winner: p1),
      ];

      expect(KnockoutEngine.isCompleted(matches, 2), isTrue);
      expect(KnockoutEngine.getChampion(matches, 2), p1);
    });

    test('isCompleted returns true when final match of carried over player is completed', () {
      final matches = [
        TournamentMatch(id: 'ko_1_0', player1: p1, player2: p2, roundIndex: 1, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_1_1', player1: p3, player2: p4, roundIndex: 1, isCompleted: true, winner: p3),
        TournamentMatch(id: 'ko_1_2', player1: p5, player2: p6, roundIndex: 1, isCompleted: true, winner: p5),
        TournamentMatch(id: 'ko_2_0', player1: p1, player2: p3, roundIndex: 2, isCompleted: true, winner: p1),
        TournamentMatch(id: 'ko_3_0', player1: p1, player2: p5, roundIndex: 3, isCompleted: true, winner: p1),
      ];

      expect(KnockoutEngine.isCompleted(matches, 3), isTrue);
      expect(KnockoutEngine.getChampion(matches, 3), p1);
    });
  });
}

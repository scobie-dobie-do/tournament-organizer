import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../models/player.dart';

class KnockoutEngine {
  /// Validates if all matches in the current round are completed and have a winner.
  static bool canAdvance(List<TournamentMatch> matches, int currentRoundIndex) {
    final currentRoundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
    if (currentRoundMatches.isEmpty) return false;
    return currentRoundMatches.every((m) => m.isCompleted && m.winner != null);
  }

  /// Recursively computes the list of active players in a given round.
  /// A player is active if they won their match in the previous round, or if they were
  /// active in the previous round but did not play a match (carried over due to an odd count).
  static List<Player> getActivePlayersForRound(
    List<TournamentMatch> matches,
    int roundIndex,
    List<Player> initialPlayers,
  ) {
    if (roundIndex <= 1) {
      return initialPlayers;
    }

    // Get active players of the previous round
    final prevActive = getActivePlayersForRound(matches, roundIndex - 1, initialPlayers);

    // Find the matches from the previous round
    final prevRoundMatches = matches.where((m) => m.roundIndex == roundIndex - 1).toList();

    // Find the winners of the matches in the previous round
    final winners = prevRoundMatches
        .where((m) => m.isCompleted && m.winner != null)
        .map((m) => m.winner!)
        .toList();

    // Find who was active in the previous round but did not play in any match in that round
    final carriedOver = prevActive.where((player) {
      final played = prevRoundMatches.any((m) => m.player1.id == player.id || m.player2?.id == player.id);
      return !played;
    }).toList();

    return [...winners, ...carriedOver];
  }

  /// Helper to extract initial players from the round 1 matches.
  static List<Player> _getInitialPlayers(List<TournamentMatch> matches) {
    final round1Matches = matches.where((m) => m.roundIndex == 1).toList();
    final List<Player> initialPlayers = [];
    for (var m in round1Matches) {
      initialPlayers.add(m.player1);
      if (m.player2 != null) {
        initialPlayers.add(m.player2!);
      }
    }
    return initialPlayers;
  }

  /// Generates matches for the next round based on the active players of the next round.
  /// Purges all BYE mechanics, pairing sequentially and carrying over any odd player.
  static List<TournamentMatch> generateNextRound({
    required List<TournamentMatch> matches,
    required int currentRoundIndex,
  }) {
    final currentRoundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();

    // Step 1: Validate winners exist for all matches in the current round
    if (currentRoundMatches.any((m) => m.winner == null)) {
      throw StateError("Complete all matches before advancing");
    }

    final initialPlayers = _getInitialPlayers(matches);

    // Step 2: Get active players for the next round
    final nextActive = getActivePlayersForRound(matches, currentRoundIndex + 1, initialPlayers);

    // If 1 or 0 players remain, there are no matches to generate (champion decided)
    if (nextActive.length <= 1) {
      return [];
    }

    final int nextRoundIndex = currentRoundIndex + 1;
    final List<TournamentMatch> nextRoundMatches = [];

    // Step 3: Generate next round matches safely using clean pairings only.
    // If the number of active players is odd, the last one is not paired and is carried over.
    for (int i = 0; i < nextActive.length; i += 2) {
      if (i + 1 < nextActive.length) {
        nextRoundMatches.add(TournamentMatch(
          id: 'ko_${nextRoundIndex}_${i ~/ 2}',
          player1: nextActive[i],
          player2: nextActive[i + 1],
          roundIndex: nextRoundIndex,
        ));
      }
    }

    return nextRoundMatches;
  }

  /// Checks if the tournament is completed based on knockout rules.
  static bool isCompleted(List<TournamentMatch> matches, int currentRoundIndex) {
    final currentRoundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
    if (currentRoundMatches.isEmpty) return false;

    // If any match in the current round is pending, it's not completed.
    final allCompleted = currentRoundMatches.every((m) => m.isCompleted);
    if (!allCompleted) return false;

    final initialPlayers = _getInitialPlayers(matches);
    final nextActive = getActivePlayersForRound(matches, currentRoundIndex + 1, initialPlayers);

    return nextActive.length <= 1;
  }

  /// Gets the champion if the tournament is completed.
  static Player? getChampion(List<TournamentMatch> matches, int currentRoundIndex) {
    if (!isCompleted(matches, currentRoundIndex)) return null;

    final initialPlayers = _getInitialPlayers(matches);
    final active = getActivePlayersForRound(matches, currentRoundIndex + 1, initialPlayers);
    return active.isNotEmpty ? active.first : null;
  }
}

import '../models/match.dart';
import '../models/player.dart';

class KnockoutEngine {
  /// Groups matches in a round by their aggregateGroupId.
  static Map<String, List<TournamentMatch>> getMatchupsInRound(List<TournamentMatch> matches, int roundIndex) {
    final roundMatches = matches.where((m) => m.roundIndex == roundIndex && !m.isThirdPlace).toList();
    final Map<String, List<TournamentMatch>> groups = {};
    for (var m in roundMatches) {
      final key = m.aggregateGroupId ?? 'legacy_${m.roundIndex}_${m.player1.id}_${m.player2?.id}';
      groups.putIfAbsent(key, () => []).add(m);
    }
    return groups;
  }

  /// Calculates the winner of a matchup (which contains 1 or more legs).
  /// Returns null if the matchup is incomplete or tied without shootout resolution.
  static Player? getWinnerOfMatchup(List<TournamentMatch> matchup, bool awayGoalsRule) {
    if (matchup.isEmpty) return null;
    if (matchup.any((m) => !m.isCompleted)) return null;

    if (matchup.length == 1) {
      return matchup.first.winner;
    }

    final p1 = matchup.first.player1;
    final p2 = matchup.first.player2;
    if (p2 == null) return p1; // Bye

    int goals1 = 0;
    int goals2 = 0;
    int awayGoals1 = 0;
    int awayGoals2 = 0;

    for (var m in matchup) {
      final hg = m.homeGoals ?? 0;
      final ag = m.awayGoals ?? 0;

      if (m.player1.id == p1.id) {
        goals1 += hg;
        goals2 += ag;
        awayGoals2 += ag;
      } else {
        goals2 += hg;
        goals1 += ag;
        awayGoals1 += ag;
      }
    }

    if (goals1 > goals2) return p1;
    if (goals2 > goals1) return p2;

    // Apply away goals rule if active
    if (awayGoalsRule) {
      if (awayGoals1 > awayGoals2) return p1;
      if (awayGoals2 > awayGoals1) return p2;
    }

    // Shootout resolution (must look at the last leg match)
    final lastLeg = matchup.reduce((curr, next) => curr.legNumber > next.legNumber ? curr : next);
    if (lastLeg.homePenalties != null && lastLeg.awayPenalties != null) {
      final hp = lastLeg.homePenalties!;
      final ap = lastLeg.awayPenalties!;

      if (lastLeg.player1.id == p1.id) {
        return hp > ap ? p1 : p2;
      } else {
        return hp > ap ? p2 : p1;
      }
    }

    return null;
  }

  /// Validates if all matches/matchups in the current round are completed and have winners.
  static bool canAdvance(List<TournamentMatch> matches, int currentRoundIndex, [bool awayGoalsRule = false]) {
    final matchups = getMatchupsInRound(matches, currentRoundIndex);
    if (matchups.isEmpty) {
      // Check if there's only a third-place match or only completed matches
      final roundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
      if (roundMatches.isEmpty) return false;
      return roundMatches.every((m) => m.isCompleted);
    }

    // Check regular matchups
    for (var group in matchups.values) {
      if (getWinnerOfMatchup(group, awayGoalsRule) == null) {
        return false;
      }
    }

    // If there is a third-place match, it must also be completed
    final thirdPlaceMatches = matches.where((m) => m.roundIndex == currentRoundIndex && m.isThirdPlace).toList();
    if (thirdPlaceMatches.isNotEmpty) {
      if (thirdPlaceMatches.any((m) => !m.isCompleted)) return false;
    }

    return true;
  }

  /// Gets the winners of the matchups in a specific round.
  static List<Player> getWinnersOfRound(List<TournamentMatch> matches, int roundIndex, [bool awayGoalsRule = false]) {
    final matchups = getMatchupsInRound(matches, roundIndex);
    final List<Player> winners = [];
    for (var group in matchups.values) {
      final w = getWinnerOfMatchup(group, awayGoalsRule);
      if (w != null) {
        winners.add(w);
      }
    }
    return winners;
  }

  /// Recursively computes the list of active players in a given round.
  static List<Player> getActivePlayersForRound(
    List<TournamentMatch> matches,
    int roundIndex,
    List<Player> initialPlayers, [
    bool awayGoalsRule = false,
  ]) {
    if (roundIndex <= 1) {
      return initialPlayers;
    }

    final prevActive = getActivePlayersForRound(matches, roundIndex - 1, initialPlayers, awayGoalsRule);
    final winners = getWinnersOfRound(matches, roundIndex - 1, awayGoalsRule);

    final prevRoundMatches = matches.where((m) => m.roundIndex == roundIndex - 1 && !m.isThirdPlace).toList();
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
      if (!initialPlayers.any((p) => p.id == m.player1.id)) {
        initialPlayers.add(m.player1);
      }
      if (m.player2 != null && !initialPlayers.any((p) => p.id == m.player2!.id)) {
        initialPlayers.add(m.player2!);
      }
    }
    return initialPlayers;
  }

  static List<TournamentMatch> generateNextRound({
    required List<TournamentMatch> matches,
    required int currentRoundIndex,
    int legs = 1,
    bool awayGoalsRule = false,
    bool hasThirdPlaceMatch = false,
  }) {
    if (!canAdvance(matches, currentRoundIndex, awayGoalsRule)) {
      throw StateError("Complete all matches before advancing");
    }

    final initialPlayers = _getInitialPlayers(matches);
    final nextActive = getActivePlayersForRound(matches, currentRoundIndex + 1, initialPlayers, awayGoalsRule);

    if (nextActive.length <= 1) {
      return [];
    }

    final int nextRoundIndex = currentRoundIndex + 1;
    final List<TournamentMatch> nextRoundMatches = [];

    // Check if we are moving to the final round (2 players remaining) and need a third-place match
    if (nextActive.length == 2 && hasThirdPlaceMatch) {
      // Find the losers of the Semi-Final matchups
      final sfMatchups = getMatchupsInRound(matches, currentRoundIndex);
      final List<Player> sfLosers = [];
      for (var group in sfMatchups.values) {
        final winner = getWinnerOfMatchup(group, awayGoalsRule);
        if (winner != null) {
          final p1 = group.first.player1;
          final p2 = group.first.player2;
          if (p2 != null) {
            sfLosers.add(p1.id == winner.id ? p2 : p1);
          }
        }
      }

      if (sfLosers.length == 2) {
        // Schedule third-place matches (same number of legs)
        final p1 = sfLosers[0];
        final p2 = sfLosers[1];
        final matchupId = 'ko_${nextRoundIndex}_third_place';

        for (int leg = 1; leg <= legs; leg++) {
          final isHomeP1 = leg.isOdd;
          final home = isHomeP1 ? p1 : p2;
          final away = isHomeP1 ? p2 : p1;

          nextRoundMatches.add(TournamentMatch(
            id: '${matchupId}_leg_$leg',
            player1: home,
            player2: away,
            roundIndex: nextRoundIndex,
            legNumber: leg,
            totalLegs: legs,
            aggregateGroupId: matchupId,
            homeAwayOrder: isHomeP1 ? 'home_away' : 'away_home',
            repetitionCycle: leg,
            isThirdPlace: true,
          ));
        }
      }
    }

    // Generate normal bracket matches for nextActive players
    for (int i = 0; i < nextActive.length; i += 2) {
      if (i + 1 < nextActive.length) {
        final p1 = nextActive[i];
        final p2 = nextActive[i + 1];
        final matchupId = 'ko_${nextRoundIndex}_${i ~/ 2}';

        for (int leg = 1; leg <= legs; leg++) {
          final isHomeP1 = leg.isOdd;
          final home = isHomeP1 ? p1 : p2;
          final away = isHomeP1 ? p2 : p1;

          nextRoundMatches.add(TournamentMatch(
            id: '${matchupId}_leg_$leg',
            player1: home,
            player2: away,
            roundIndex: nextRoundIndex,
            legNumber: leg,
            totalLegs: legs,
            aggregateGroupId: matchupId,
            homeAwayOrder: isHomeP1 ? 'home_away' : 'away_home',
            repetitionCycle: leg,
          ));
        }
      }
    }

    return nextRoundMatches;
  }

  /// Checks if the tournament is completed.
  static bool isCompleted(List<TournamentMatch> matches, int currentRoundIndex, [bool awayGoalsRule = false]) {
    final roundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
    if (roundMatches.isEmpty) return false;

    final allCompleted = roundMatches.every((m) => m.isCompleted);
    if (!allCompleted) return false;

    final initialPlayers = _getInitialPlayers(matches);
    final nextActive = getActivePlayersForRound(matches, currentRoundIndex + 1, initialPlayers, awayGoalsRule);

    return nextActive.length <= 1;
  }

  /// Gets the champion.
  static Player? getChampion(List<TournamentMatch> matches, int currentRoundIndex, [bool awayGoalsRule = false]) {
    if (!isCompleted(matches, currentRoundIndex, awayGoalsRule)) return null;

    final finalMatchups = getMatchupsInRound(matches, currentRoundIndex);
    if (finalMatchups.isEmpty) return null;

    // The final matchup is the one in the final round (excluding third place)
    // Find the one that has the championship match
    for (var group in finalMatchups.values) {
      final winner = getWinnerOfMatchup(group, awayGoalsRule);
      if (winner != null) return winner;
    }
    return null;
  }
}

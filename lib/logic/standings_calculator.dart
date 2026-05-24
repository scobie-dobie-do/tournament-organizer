import '../models/player.dart';
import '../models/match.dart';
import '../logic/tournament_logic.dart';

class StandingsCalculator {
  /// Calculates standings and returns a sorted list of TeamStats.
  /// Sorting criteria: Points -> Goal Difference -> Goals For -> Alphabetical (team name).
  static List<TeamStats> calculate(List<Player> players, List<TournamentMatch> matches) {
    final Map<String, int> playedMap = {for (var p in players) p.id: 0};
    final Map<String, int> winsMap = {for (var p in players) p.id: 0};
    final Map<String, int> drawsMap = {for (var p in players) p.id: 0};
    final Map<String, int> lossesMap = {for (var p in players) p.id: 0};
    final Map<String, int> goalsForMap = {for (var p in players) p.id: 0};
    final Map<String, int> goalsAgainstMap = {for (var p in players) p.id: 0};
    final Map<String, int> pointsMap = {for (var p in players) p.id: 0};

    for (var match in matches) {
      if (match.isCompleted) {
        if (match.isBye) {
          final p1Id = match.player1.id;
          playedMap[p1Id] = (playedMap[p1Id] ?? 0) + 1;
          winsMap[p1Id] = (winsMap[p1Id] ?? 0) + 1;
          pointsMap[p1Id] = (pointsMap[p1Id] ?? 0) + 3; // Bye counts as 3 points
        } else if (match.homeGoals != null && match.awayGoals != null) {
          final p1Id = match.player1.id;
          final p2Id = match.player2!.id;
          final hg = match.homeGoals!;
          final ag = match.awayGoals!;

          playedMap[p1Id] = (playedMap[p1Id] ?? 0) + 1;
          playedMap[p2Id] = (playedMap[p2Id] ?? 0) + 1;

          goalsForMap[p1Id] = (goalsForMap[p1Id] ?? 0) + hg;
          goalsAgainstMap[p1Id] = (goalsAgainstMap[p1Id] ?? 0) + ag;

          goalsForMap[p2Id] = (goalsForMap[p2Id] ?? 0) + ag;
          goalsAgainstMap[p2Id] = (goalsAgainstMap[p2Id] ?? 0) + hg;

          if (hg > ag) {
            winsMap[p1Id] = (winsMap[p1Id] ?? 0) + 1;
            lossesMap[p2Id] = (lossesMap[p2Id] ?? 0) + 1;
            pointsMap[p1Id] = (pointsMap[p1Id] ?? 0) + 3;
          } else if (hg < ag) {
            winsMap[p2Id] = (winsMap[p2Id] ?? 0) + 1;
            lossesMap[p1Id] = (lossesMap[p1Id] ?? 0) + 1;
            pointsMap[p2Id] = (pointsMap[p2Id] ?? 0) + 3;
          } else {
            drawsMap[p1Id] = (drawsMap[p1Id] ?? 0) + 1;
            drawsMap[p2Id] = (drawsMap[p2Id] ?? 0) + 1;
            pointsMap[p1Id] = (pointsMap[p1Id] ?? 0) + 1;
            pointsMap[p2Id] = (pointsMap[p2Id] ?? 0) + 1;
          }
        } else if (match.winner != null) {
          // Legacy check if goals are null but winner is selected (backward compatibility)
          final winnerId = match.winner!.id;
          playedMap[winnerId] = (playedMap[winnerId] ?? 0) + 1;
          winsMap[winnerId] = (winsMap[winnerId] ?? 0) + 1;
          pointsMap[winnerId] = (pointsMap[winnerId] ?? 0) + 3;

          final loser = match.player1.id == winnerId ? match.player2 : match.player1;
          if (loser != null) {
            playedMap[loser.id] = (playedMap[loser.id] ?? 0) + 1;
            lossesMap[loser.id] = (lossesMap[loser.id] ?? 0) + 1;
          }
        }
      }
    }

    final list = players.map((player) {
      final gf = goalsForMap[player.id] ?? 0;
      final ga = goalsAgainstMap[player.id] ?? 0;
      return TeamStats(
        team: player,
        played: playedMap[player.id] ?? 0,
        wins: winsMap[player.id] ?? 0,
        draws: drawsMap[player.id] ?? 0,
        losses: lossesMap[player.id] ?? 0,
        goalsFor: gf,
        goalsAgainst: ga,
        goalDifference: gf - ga,
        points: pointsMap[player.id] ?? 0,
      );
    }).toList();

    // Sort standings by: Points -> Goal Difference -> Goals For -> Head-to-Head -> Wins -> Alphabetical
    list.sort((a, b) {
      if (b.points != a.points) {
        return b.points.compareTo(a.points);
      }
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }
      if (b.goalsFor != a.goalsFor) {
        return b.goalsFor.compareTo(a.goalsFor);
      }

      // Head-to-Head (H2H) tie-breaker
      final h2hMatches = matches.where((m) {
        if (!m.isCompleted || m.isBye) return false;
        final id1 = m.player1.id;
        final id2 = m.player2?.id;
        if (id2 == null) return false;
        return (id1 == a.team.id && id2 == b.team.id) || (id1 == b.team.id && id2 == a.team.id);
      }).toList();

      if (h2hMatches.isNotEmpty) {
        int aH2hPoints = 0;
        int bH2hPoints = 0;
        int aH2hGoals = 0;
        int bH2hGoals = 0;

        for (var m in h2hMatches) {
          final hg = m.homeGoals ?? 0;
          final ag = m.awayGoals ?? 0;
          final isHomeA = m.player1.id == a.team.id;

          if (isHomeA) {
            aH2hGoals += hg;
            bH2hGoals += ag;
            if (hg > ag) {
              aH2hPoints += 3;
            } else if (hg < ag) {
              bH2hPoints += 3;
            } else {
              aH2hPoints += 1;
              bH2hPoints += 1;
            }
          } else {
            aH2hGoals += ag;
            bH2hGoals += hg;
            if (ag > hg) {
              aH2hPoints += 3;
            } else if (ag < hg) {
              bH2hPoints += 3;
            } else {
              aH2hPoints += 1;
              bH2hPoints += 1;
            }
          }
        }

        if (bH2hPoints != aH2hPoints) {
          return bH2hPoints.compareTo(aH2hPoints);
        }

        final aH2hGd = aH2hGoals - bH2hGoals;
        final bH2hGd = bH2hGoals - aH2hGoals;
        if (bH2hGd != aH2hGd) {
          return bH2hGd.compareTo(aH2hGd);
        }
      }

      // Wins tie-breaker
      if (b.wins != a.wins) {
        return b.wins.compareTo(a.wins);
      }

      return a.team.teamName.compareTo(b.team.teamName);
    });

    return list;
  }

  /// Calculates chronological match form (last 5 matches) for a team.
  /// Returns a list of strings: 'W' (Win), 'D' (Draw), 'L' (Loss).
  static List<String> calculateForm(Player team, List<TournamentMatch> matches) {
    // Filter completed, non-bye matches involving this team
    final teamMatches = matches.where((m) {
      if (!m.isCompleted || m.isBye) return false;
      return m.player1.id == team.id || (m.player2 != null && m.player2!.id == team.id);
    }).toList();

    // Since we generate matches sequentially and keep them in list order,
    // their order in the matches list is chronological.
    // Take the last 5 matches.
    final lastMatches = teamMatches.length > 5
        ? teamMatches.sublist(teamMatches.length - 5)
        : teamMatches;

    return lastMatches.map((m) {
      if (m.homeGoals == m.awayGoals) return 'D';
      final isHome = m.player1.id == team.id;
      final isHomeWinner = (m.homeGoals ?? 0) > (m.awayGoals ?? 0);
      if (isHome) {
        return isHomeWinner ? 'W' : 'L';
      } else {
        return isHomeWinner ? 'L' : 'W';
      }
    }).toList();
  }
}

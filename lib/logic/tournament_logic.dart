import 'dart:math';
import '../models/player.dart';
import '../models/match.dart';
import '../storage/database_service.dart';

enum TournamentFormat {
  knockout,
  roundRobin;

  String get displayName {
    switch (this) {
      case TournamentFormat.knockout:
        return 'Knockout';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
    }
  }
}

class TeamStats {
  final Player team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  TeamStats({
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });
}

class TournamentState {
  final String id;
  final String name;
  final List<Player> players;
  final TournamentFormat format;
  final List<TournamentMatch> matches = [];
  int currentRoundIndex = 1;
  bool isCompleted = false;
  final DateTime createdAt;

  TournamentState({
    required this.id,
    required this.name,
    required this.players,
    required this.format,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    _generateInitialMatches();
    // Auto-save initial state
    DatabaseService().saveTournament(this);
  }

  // Private constructor for loading from database
  TournamentState._internal({
    required this.id,
    required this.name,
    required this.players,
    required this.format,
    required this.createdAt,
  });

  void _generateInitialMatches() {
    matches.clear();
    currentRoundIndex = 1;
    isCompleted = false;

    if (format == TournamentFormat.knockout) {
      _generateKnockoutRound(players);
    } else {
      _generateRoundRobin();
    }
  }

  void _generateKnockoutRound(List<Player> roundPlayers) {
    final shuffled = List<Player>.from(roundPlayers)..shuffle(Random());
    
    for (int i = 0; i < shuffled.length; i += 2) {
      if (i + 1 < shuffled.length) {
        matches.add(TournamentMatch(
          id: 'ko_${currentRoundIndex}_${i ~/ 2}',
          player1: shuffled[i],
          player2: shuffled[i + 1],
          roundIndex: currentRoundIndex,
        ));
      } else {
        final byePlayer = shuffled[i];
        matches.add(TournamentMatch(
          id: 'ko_${currentRoundIndex}_${i ~/ 2}_bye',
          player1: byePlayer,
          player2: null,
          winner: byePlayer,
          isBye: true,
          roundIndex: currentRoundIndex,
          isCompleted: true,
        ));
      }
    }
    _checkTournamentStatus();
  }

  void _generateRoundRobin() {
    int matchIndex = 0;
    for (int i = 0; i < players.length; i++) {
      for (int j = i + 1; j < players.length; j++) {
        matches.add(TournamentMatch(
          id: 'rr_$matchIndex',
          player1: players[i],
          player2: players[j],
          roundIndex: 1,
        ));
        matchIndex++;
      }
    }
    _checkTournamentStatus();
  }

  void recordMatchResult(String matchId, int homeGoals, int awayGoals) {
    final index = matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = matches[index];
      if (match.isBye) return;

      Player? winner;
      if (homeGoals > awayGoals) {
        winner = match.player1;
      } else if (homeGoals < awayGoals) {
        winner = match.player2;
      }

      matches[index] = match.copyWith(
        homeGoals: homeGoals,
        awayGoals: awayGoals,
        winner: winner,
        isCompleted: true,
        clearWinner: winner == null,
      );

      _checkTournamentStatus();
      DatabaseService().saveTournament(this);
    }
  }

  void clearMatchResult(String matchId) {
    final index = matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = matches[index];
      if (match.isBye) return;

      matches[index] = TournamentMatch(
        id: match.id,
        player1: match.player1,
        player2: match.player2,
        roundIndex: match.roundIndex,
        isBye: false,
        isCompleted: false,
        winner: null,
        homeGoals: null,
        awayGoals: null,
      );

      _checkTournamentStatus();
      DatabaseService().saveTournament(this);
    }
  }

  void selectWinner(String matchId, Player? winner) {
    // Kept for backward compatibility with old tests if any,
    // delegates to direct match update if needed.
    final index = matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = matches[index];
      if (match.isBye) return;

      matches[index] = match.copyWith(
        winner: winner,
        isCompleted: winner != null,
        clearWinner: winner == null,
      );

      _checkTournamentStatus();
      DatabaseService().saveTournament(this);
    }
  }

  void _checkTournamentStatus() {
    if (format == TournamentFormat.knockout) {
      final currentRoundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
      final allPlayed = currentRoundMatches.every((m) => m.isCompleted);
      
      if (allPlayed) {
        if (currentRoundMatches.length == 1) {
          isCompleted = true;
        }
      }
    } else {
      isCompleted = matches.every((m) => m.isCompleted);
    }
  }

  bool get canAdvanceKnockout {
    if (format != TournamentFormat.knockout || isCompleted) return false;
    final currentRoundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
    return currentRoundMatches.isNotEmpty && currentRoundMatches.every((m) => m.isCompleted && m.winner != null);
  }

  void advanceKnockoutRound() {
    if (!canAdvanceKnockout) return;

    final currentRoundMatches = matches.where((m) => m.roundIndex == currentRoundIndex).toList();
    final winners = currentRoundMatches.map((m) => m.winner!).toList();

    if (winners.length <= 1) {
      isCompleted = true;
      DatabaseService().saveTournament(this);
      return;
    }

    currentRoundIndex++;
    
    for (int i = 0; i < winners.length; i += 2) {
      if (i + 1 < winners.length) {
        matches.add(TournamentMatch(
          id: 'ko_${currentRoundIndex}_${i ~/ 2}',
          player1: winners[i],
          player2: winners[i + 1],
          roundIndex: currentRoundIndex,
        ));
      } else {
        final byePlayer = winners[i];
        matches.add(TournamentMatch(
          id: 'ko_${currentRoundIndex}_${i ~/ 2}_bye',
          player1: byePlayer,
          player2: null,
          winner: byePlayer,
          isBye: true,
          roundIndex: currentRoundIndex,
          isCompleted: true,
        ));
      }
    }
    
    _checkTournamentStatus();
    DatabaseService().saveTournament(this);
  }

  List<TeamStats> getLeaderboard() {
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

    // Sort standings by: Points -> Goal Difference -> Goals Scored -> Team Name (alphabetical)
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
      return a.team.teamName.compareTo(b.team.teamName);
    });

    return list;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'format': format.name,
      'players': players.map((p) => p.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'currentRoundIndex': currentRoundIndex,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TournamentState.fromJson(Map<String, dynamic> json) {
    final formatName = json['format'] as String;
    final format = TournamentFormat.values.firstWhere((f) => f.name == formatName);
    final playersJson = json['players'] as List<dynamic>;
    final players = playersJson.map((p) => Player.fromJson(p as Map<String, dynamic>)).toList();
    
    final state = TournamentState._internal(
      id: json['id'] as String,
      name: json['name'] as String,
      format: format,
      players: players,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

    state.currentRoundIndex = (json['currentRoundIndex'] ?? 1) as int;
    state.isCompleted = (json['isCompleted'] ?? false) as bool;

    final matchesJson = json['matches'] as List<dynamic>;
    state.matches.clear();
    state.matches.addAll(
      matchesJson.map((m) => TournamentMatch.fromJson(m as Map<String, dynamic>)).toList(),
    );

    return state;
  }
}

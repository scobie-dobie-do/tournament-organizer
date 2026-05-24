import 'dart:math';
import '../models/player.dart';
import '../models/match.dart';
import '../storage/database_service.dart';
import 'standings_calculator.dart';
import 'knockout_engine.dart';

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
      matches.add(TournamentMatch(
        id: 'ko_${currentRoundIndex}_${i ~/ 2}',
        player1: shuffled[i],
        player2: shuffled[i + 1],
        roundIndex: currentRoundIndex,
      ));
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
      isCompleted = KnockoutEngine.isCompleted(matches, currentRoundIndex);
    } else {
      isCompleted = matches.every((m) => m.isCompleted);
    }
  }

  bool get canAdvanceKnockout {
    if (format != TournamentFormat.knockout || isCompleted) return false;
    return KnockoutEngine.canAdvance(matches, currentRoundIndex);
  }

  void advanceKnockoutRound() {
    if (!canAdvanceKnockout) return;

    try {
      final nextMatches = KnockoutEngine.generateNextRound(
        matches: matches,
        currentRoundIndex: currentRoundIndex,
      );

      if (nextMatches.isEmpty) {
        isCompleted = true;
      } else {
        matches.addAll(nextMatches);
        currentRoundIndex++;
      }
      
      _checkTournamentStatus();
      DatabaseService().saveTournament(this);
    } catch (e) {
      // Safety fallback
      print("Error advancing knockout round: $e");
    }
  }

  List<TeamStats> getLeaderboard() {
    return StandingsCalculator.calculate(players, matches);
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

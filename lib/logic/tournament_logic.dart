import 'dart:math';
import 'package:flutter/foundation.dart';
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
  final int legs;
  final bool awayGoalsRule;
  final bool hasThirdPlaceMatch;
  bool locked;

  TournamentState({
    required this.id,
    required this.name,
    required this.players,
    required this.format,
    this.legs = 1,
    this.awayGoalsRule = false,
    this.hasThirdPlaceMatch = false,
    this.locked = false,
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
    required this.legs,
    required this.awayGoalsRule,
    required this.hasThirdPlaceMatch,
    required this.locked,
  });

  void resetTournament() {
    locked = false;
    _generateInitialMatches();
    DatabaseService().saveTournament(this);
  }

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
      final p1 = shuffled[i];
      final p2 = shuffled[i + 1];
      final matchupId = 'ko_${currentRoundIndex}_${i ~/ 2}';
      
      for (int leg = 1; leg <= legs; leg++) {
        final isHomeP1 = leg.isOdd;
        final home = isHomeP1 ? p1 : p2;
        final away = isHomeP1 ? p2 : p1;
        
        matches.add(TournamentMatch(
          id: '${matchupId}_leg_$leg',
          player1: home,
          player2: away,
          roundIndex: currentRoundIndex,
          legNumber: leg,
          totalLegs: legs,
          aggregateGroupId: matchupId,
          homeAwayOrder: isHomeP1 ? 'home_away' : 'away_home',
          repetitionCycle: leg,
        ));
      }
    }
    _checkTournamentStatus();
  }

  void _generateRoundRobin() {
    matches.clear();
    currentRoundIndex = 1;
    isCompleted = false;

    final int teamCount = players.length;
    if (teamCount < 2) return;

    for (int cycle = 1; cycle <= legs; cycle++) {
      List<Player?> tempPlayers = List.from(players);
      if (tempPlayers.length.isOdd) {
        tempPlayers.add(null); // Add dummy player for BYEs
      }
      final int m = tempPlayers.length;
      final int roundsPerCycle = m - 1;

      for (int r = 0; r < roundsPerCycle; r++) {
        final int actualRound = (cycle - 1) * roundsPerCycle + (r + 1);
        
        for (int i = 0; i < m ~/ 2; i++) {
          final p1 = tempPlayers[i];
          final p2 = tempPlayers[m - 1 - i];

          if (p1 == null && p2 == null) continue;

          if (p1 == null) {
            matches.add(TournamentMatch(
              id: 'rr_${cycle}_${actualRound}_$i',
              player1: p2!,
              player2: null,
              isBye: true,
              isCompleted: true,
              roundIndex: actualRound,
              legNumber: cycle,
              totalLegs: legs,
              repetitionCycle: cycle,
              status: 'completed',
            ));
          } else if (p2 == null) {
            matches.add(TournamentMatch(
              id: 'rr_${cycle}_${actualRound}_$i',
              player1: p1,
              player2: null,
              isBye: true,
              isCompleted: true,
              roundIndex: actualRound,
              legNumber: cycle,
              totalLegs: legs,
              repetitionCycle: cycle,
              status: 'completed',
            ));
          } else {
            bool isP1Home = true;
            if (i == 0) {
              isP1Home = r.isEven;
            } else {
              isP1Home = (i + r).isEven;
            }

            if (cycle.isEven) {
              isP1Home = !isP1Home;
            }

            final homeTeam = isP1Home ? p1 : p2;
            final awayTeam = isP1Home ? p2 : p1;

            matches.add(TournamentMatch(
              id: 'rr_${cycle}_${actualRound}_$i',
              player1: homeTeam,
              player2: awayTeam,
              roundIndex: actualRound,
              legNumber: cycle,
              totalLegs: legs,
              repetitionCycle: cycle,
              homeAwayOrder: isP1Home ? 'home_away' : 'away_home',
              aggregateGroupId: 'rr_group_${p1.id}_${p2.id}',
              isBye: false,
              isCompleted: false,
            ));
          }
        }
        
        if (tempPlayers.length > 2) {
          final last = tempPlayers.removeLast();
          tempPlayers.insert(1, last);
        }
      }
    }
    _checkTournamentStatus();
  }

  void recordMatchResult(
    String matchId,
    int homeGoals,
    int awayGoals, {
    int? homePenalties,
    int? awayPenalties,
    List<MatchEvent>? events,
    String? notes,
    String? mvp,
    String? status,
    bool? isExtraTime,
    bool? isPenalties,
  }) {
    if (locked) return;

    final index = matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final match = matches[index];
      if (match.isBye) return;

      Player? winner;
      if (homeGoals > awayGoals) {
        winner = match.player1;
      } else if (homeGoals < awayGoals) {
        winner = match.player2;
      } else if (homePenalties != null && awayPenalties != null) {
        if (homePenalties > awayPenalties) {
          winner = match.player1;
        } else if (homePenalties < awayPenalties) {
          winner = match.player2;
        }
      }

      matches[index] = match.copyWith(
        homeGoals: homeGoals,
        awayGoals: awayGoals,
        winner: winner,
        isCompleted: true,
        clearWinner: winner == null,
        homePenalties: homePenalties,
        awayPenalties: awayPenalties,
        events: events,
        notes: notes,
        mvp: mvp,
        status: status ?? 'completed',
        isExtraTime: isExtraTime,
        isPenalties: isPenalties,
        clearPenalties: homePenalties == null,
      );

      _checkTournamentStatus();
      DatabaseService().saveTournament(this);
    }
  }

  void clearMatchResult(String matchId) {
    if (locked) return;

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
        legNumber: match.legNumber,
        totalLegs: match.totalLegs,
        aggregateGroupId: match.aggregateGroupId,
        homeAwayOrder: match.homeAwayOrder,
        repetitionCycle: match.repetitionCycle,
        isThirdPlace: match.isThirdPlace,
      );

      _checkTournamentStatus();
      DatabaseService().saveTournament(this);
    }
  }

  void selectWinner(String matchId, Player? winner) {
    if (locked) return;

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
      isCompleted = KnockoutEngine.isCompleted(matches, currentRoundIndex, awayGoalsRule);
    } else {
      isCompleted = matches.every((m) => m.isCompleted);
    }
  }

  bool get canAdvanceKnockout {
    if (format != TournamentFormat.knockout || isCompleted || locked) return false;
    return KnockoutEngine.canAdvance(matches, currentRoundIndex, awayGoalsRule);
  }

  void advanceKnockoutRound() {
    if (!canAdvanceKnockout) return;

    try {
      final nextMatches = KnockoutEngine.generateNextRound(
        matches: matches,
        currentRoundIndex: currentRoundIndex,
        legs: legs,
        awayGoalsRule: awayGoalsRule,
        hasThirdPlaceMatch: hasThirdPlaceMatch,
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
      debugPrint("Error advancing knockout round: $e");
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
      'legs': legs,
      'awayGoalsRule': awayGoalsRule,
      'hasThirdPlaceMatch': hasThirdPlaceMatch,
      'locked': locked,
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
      legs: (json['legs'] ?? 1) as int,
      awayGoalsRule: (json['awayGoalsRule'] ?? false) as bool,
      hasThirdPlaceMatch: (json['hasThirdPlaceMatch'] ?? false) as bool,
      locked: (json['locked'] ?? false) as bool,
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

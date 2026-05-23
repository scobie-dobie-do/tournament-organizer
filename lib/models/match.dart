import 'player.dart';

class TournamentMatch {
  final String id;
  final Player player1;
  final Player? player2; // Null means it's a bye match for player1
  final Player? winner;  // Null means match is pending or a draw
  final bool isBye;
  final int roundIndex;
  final int? homeGoals;
  final int? awayGoals;
  final bool isCompleted;

  TournamentMatch({
    required this.id,
    required this.player1,
    this.player2,
    this.winner,
    this.isBye = false,
    this.roundIndex = 1,
    this.homeGoals,
    this.awayGoals,
    this.isCompleted = false,
  });

  TournamentMatch copyWith({
    String? id,
    Player? player1,
    Player? player2,
    Player? winner,
    bool? isBye,
    int? roundIndex,
    int? homeGoals,
    int? awayGoals,
    bool? isCompleted,
    bool clearWinner = false,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      winner: clearWinner ? null : (winner ?? this.winner),
      isBye: isBye ?? this.isBye,
      roundIndex: roundIndex ?? this.roundIndex,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1': player1.toJson(),
      'player2': player2?.toJson(),
      'winner': winner?.toJson(),
      'isBye': isBye,
      'roundIndex': roundIndex,
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
      'isCompleted': isCompleted,
    };
  }

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      player1: Player.fromJson(json['player1'] as Map<String, dynamic>),
      player2: json['player2'] != null
          ? Player.fromJson(json['player2'] as Map<String, dynamic>)
          : null,
      winner: json['winner'] != null
          ? Player.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      isBye: (json['isBye'] ?? false) as bool,
      roundIndex: (json['roundIndex'] ?? 1) as int,
      homeGoals: json['homeGoals'] as int?,
      awayGoals: json['awayGoals'] as int?,
      isCompleted: (json['isCompleted'] ?? false) as bool,
    );
  }

  @override
  String toString() {
    if (isBye) {
      return 'TournamentMatch(id: $id, ${player1.teamName} has BYE, round: $roundIndex)';
    }
    return 'TournamentMatch(id: $id, ${player1.teamName} ($homeGoals) vs ${player2?.teamName} ($awayGoals), completed: $isCompleted, round: $roundIndex)';
  }
}

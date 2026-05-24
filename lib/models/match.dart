import 'player.dart';

class MatchEvent {
  final String id;
  final int minute;
  final String type; // 'goal', 'yellow_card', 'red_card'
  final String playerName;
  final String teamId;

  MatchEvent({
    required this.id,
    required this.minute,
    required this.type,
    required this.playerName,
    required this.teamId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minute': minute,
      'type': type,
      'playerName': playerName,
      'teamId': teamId,
    };
  }

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'] as String,
      minute: json['minute'] as int,
      type: json['type'] as String,
      playerName: json['playerName'] as String,
      teamId: json['teamId'] as String,
    );
  }
}

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

  // Rich in-game event features
  final List<MatchEvent> events;
  final String? notes;
  final String? mvp;
  final String status; // 'scheduled', 'live', 'completed'
  final int elapsedMinutes;
  final int legIndex; // 1 or 2 (or more in custom formats)
  final int legNumber; // 1 or 2 (synced with legIndex)
  final int totalLegs;
  final String? aggregateGroupId;
  final String? homeAwayOrder; // 'home_away' or 'away_home'
  final int repetitionCycle;
  final int? homePenalties;
  final int? awayPenalties;
  final bool isExtraTime;
  final bool isPenalties;
  final List<String> historyLogs;
  final bool isThirdPlace;

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
    this.events = const [],
    this.notes,
    this.mvp,
    this.status = 'scheduled',
    this.elapsedMinutes = 0,
    int? legIndex,
    int? legNumber,
    this.totalLegs = 1,
    this.aggregateGroupId,
    this.homeAwayOrder,
    this.repetitionCycle = 1,
    this.homePenalties,
    this.awayPenalties,
    this.isExtraTime = false,
    this.isPenalties = false,
    this.historyLogs = const [],
    this.isThirdPlace = false,
  })  : legNumber = legNumber ?? legIndex ?? 1,
        legIndex = legIndex ?? legNumber ?? 1;

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
    List<MatchEvent>? events,
    String? notes,
    String? mvp,
    String? status,
    int? elapsedMinutes,
    int? legIndex,
    int? legNumber,
    int? totalLegs,
    String? aggregateGroupId,
    String? homeAwayOrder,
    int? repetitionCycle,
    int? homePenalties,
    int? awayPenalties,
    bool? isExtraTime,
    bool? isPenalties,
    List<String>? historyLogs,
    bool clearPenalties = false,
    bool? isThirdPlace,
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
      events: events ?? this.events,
      notes: notes ?? this.notes,
      mvp: mvp ?? this.mvp,
      status: status ?? this.status,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
      legIndex: legIndex ?? this.legIndex,
      legNumber: legNumber ?? this.legNumber,
      totalLegs: totalLegs ?? this.totalLegs,
      aggregateGroupId: aggregateGroupId ?? this.aggregateGroupId,
      homeAwayOrder: homeAwayOrder ?? this.homeAwayOrder,
      repetitionCycle: repetitionCycle ?? this.repetitionCycle,
      homePenalties: clearPenalties ? null : (homePenalties ?? this.homePenalties),
      awayPenalties: clearPenalties ? null : (awayPenalties ?? this.awayPenalties),
      isExtraTime: isExtraTime ?? this.isExtraTime,
      isPenalties: isPenalties ?? this.isPenalties,
      historyLogs: historyLogs ?? this.historyLogs,
      isThirdPlace: isThirdPlace ?? this.isThirdPlace,
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
      'events': events.map((e) => e.toJson()).toList(),
      'notes': notes,
      'mvp': mvp,
      'status': status,
      'elapsedMinutes': elapsedMinutes,
      'legIndex': legIndex,
      'legNumber': legNumber,
      'totalLegs': totalLegs,
      'aggregateGroupId': aggregateGroupId,
      'homeAwayOrder': homeAwayOrder,
      'repetitionCycle': repetitionCycle,
      'homePenalties': homePenalties,
      'awayPenalties': awayPenalties,
      'isExtraTime': isExtraTime,
      'isPenalties': isPenalties,
      'historyLogs': historyLogs,
      'isThirdPlace': isThirdPlace,
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
      events: json['events'] != null
          ? (json['events'] as List<dynamic>)
              .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      notes: json['notes'] as String?,
      mvp: json['mvp'] as String?,
      status: (json['status'] ?? (json['isCompleted'] == true ? 'completed' : 'scheduled')) as String,
      elapsedMinutes: (json['elapsedMinutes'] ?? 0) as int,
      legIndex: (json['legIndex'] ?? 1) as int,
      legNumber: (json['legNumber'] ?? json['legIndex'] ?? 1) as int,
      totalLegs: (json['totalLegs'] ?? 1) as int,
      aggregateGroupId: json['aggregateGroupId'] as String?,
      homeAwayOrder: json['homeAwayOrder'] as String?,
      repetitionCycle: (json['repetitionCycle'] ?? 1) as int,
      homePenalties: json['homePenalties'] as int?,
      awayPenalties: json['awayPenalties'] as int?,
      isExtraTime: (json['isExtraTime'] ?? false) as bool,
      isPenalties: (json['isPenalties'] ?? false) as bool,
      historyLogs: json['historyLogs'] != null
          ? List<String>.from(json['historyLogs'] as List<dynamic>)
          : [],
      isThirdPlace: (json['isThirdPlace'] ?? false) as bool,
    );
  }

  @override
  String toString() {
    if (isBye) {
      return 'TournamentMatch(id: $id, ${player1.teamName} has BYE, round: $roundIndex)';
    }
    return 'TournamentMatch(id: $id, ${player1.teamName} ($homeGoals) vs ${player2?.teamName} ($awayGoals), status: $status, round: $roundIndex, leg: $legNumber/$totalLegs)';
  }
}

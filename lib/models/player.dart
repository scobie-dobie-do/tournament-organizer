class Player {
  final String id;
  final String teamName;
  final String name;
  final String? logoPath;

  Player({
    required this.id,
    required this.teamName,
    this.name = '',
    this.logoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamName': teamName,
      'name': name,
      'logoPath': logoPath,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      teamName: json['teamName'] as String,
      name: (json['name'] ?? '') as String,
      logoPath: json['logoPath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, teamName: $teamName, name: $name, logoPath: $logoPath)';
}

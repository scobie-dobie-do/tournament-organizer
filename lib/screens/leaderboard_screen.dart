import 'package:flutter/material.dart';
import '../logic/tournament_logic.dart';
import '../widgets/team_logo_widget.dart';

class LeaderboardScreen extends StatelessWidget {
  final TournamentState tournamentState;

  const LeaderboardScreen({
    super.key,
    required this.tournamentState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leaderboard = tournamentState.getLeaderboard();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard Standings'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Visual Podium (if at least 2 players exist)
            if (leaderboard.length >= 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: _buildVisualPodium(leaderboard, theme),
              ),

            // 2. Table Area
            Expanded(
              child: leaderboard.isEmpty
                  ? Center(
                      child: Text(
                        'No statistics available.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 540,
                                child: Table(
                                  columnWidths: const {
                                    0: FixedColumnWidth(36),  // Rank
                                    1: FixedColumnWidth(180), // Team Name + Logo
                                    2: FixedColumnWidth(36),  // MP (Matches Played)
                                    3: FixedColumnWidth(32),  // W
                                    4: FixedColumnWidth(32),  // D
                                    5: FixedColumnWidth(32),  // L
                                    6: FixedColumnWidth(38),  // GF (Goals For)
                                    7: FixedColumnWidth(38),  // GA (Goals Against)
                                    8: FixedColumnWidth(44),  // GD (Goal Difference)
                                    9: FixedColumnWidth(42),  // PTS
                                  },
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: [
                                    // Table Header
                                    _buildHeaderRow(theme),
                                    // Table Data Rows
                                    ...List.generate(leaderboard.length, (index) {
                                      final entry = leaderboard[index];
                                      return _buildTableRow(index, entry, theme);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(ThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.4).toInt()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      children: [
        _buildHeaderCell('#'),
        _buildHeaderCell('Team', align: TextAlign.left),
        _buildHeaderCell('MP'),
        _buildHeaderCell('W'),
        _buildHeaderCell('D'),
        _buildHeaderCell('L'),
        _buildHeaderCell('GF'),
        _buildHeaderCell('GA'),
        _buildHeaderCell('GD'),
        _buildHeaderCell('PTS', isBold: true),
      ],
    );
  }

  TableRow _buildTableRow(int index, TeamStats entry, ThemeData theme) {
    final rank = index + 1;
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven
            ? Colors.transparent
            : theme.colorScheme.surfaceContainerLow.withAlpha((255 * 0.3).toInt()),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withAlpha((255 * 0.05).toInt()),
            width: 1.0,
          ),
        ),
      ),
      children: [
        _buildRankCell(rank),
        _buildTeamCell(entry, theme),
        _buildDataCell('${entry.played}'),
        _buildDataCell('${entry.wins}'),
        _buildDataCell('${entry.draws}'),
        _buildDataCell('${entry.losses}'),
        _buildDataCell('${entry.goalsFor}'),
        _buildDataCell('${entry.goalsAgainst}'),
        _buildDataCell('${entry.goalDifference}', isGd: true),
        _buildPointsCell(entry.points, theme, isFirst: rank == 1),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.center, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRankCell(int rank) {
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 18);
    } else if (rank == 2) {
      rankWidget = Icon(Icons.workspace_premium_rounded, color: Colors.grey.shade400, size: 18);
    } else if (rank == 3) {
      rankWidget = Icon(Icons.workspace_premium_rounded, color: Colors.brown.shade300, size: 18);
    } else {
      rankWidget = Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: Center(child: rankWidget),
    );
  }

  Widget _buildTeamCell(TeamStats entry, ThemeData theme) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamLogoWidget(
              logoPath: entry.team.logoPath,
              teamName: entry.team.teamName,
              size: 26,
              hasBorder: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.team.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  if (entry.team.name.isNotEmpty)
                    Text(
                      entry.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isGd = false}) {
    Color? textColor = Colors.white70;
    if (isGd) {
      final val = int.tryParse(text) ?? 0;
      if (val > 0) {
        textColor = Colors.greenAccent.shade400;
        text = '+$text';
      } else if (val < 0) {
        textColor = Colors.redAccent.shade400;
      } else {
        textColor = Colors.grey.shade500;
      }
    }
    return SizedBox(
      height: 48,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isGd ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCell(int points, ThemeData theme, {bool isFirst = false}) {
    return SizedBox(
      height: 48,
      child: Center(
        child: Text(
          '$points',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isFirst ? Colors.amber : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualPodium(List<TeamStats> leaderboard, ThemeData theme) {
    final p1 = leaderboard[0];
    final p2 = leaderboard[1];
    final p3 = leaderboard.length >= 3 ? leaderboard[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 2nd Place Column
        _buildPodiumColumn(
          name: p2.team.name,
          teamName: p2.team.teamName,
          points: p2.points,
          logoPath: p2.team.logoPath,
          positionLabel: '2nd',
          medalColor: Colors.grey.shade400,
          columnHeight: 100,
          theme: theme,
        ),
        const SizedBox(width: 10),
        // 1st Place Column
        _buildPodiumColumn(
          name: p1.team.name,
          teamName: p1.team.teamName,
          points: p1.points,
          logoPath: p1.team.logoPath,
          positionLabel: '1st',
          medalColor: Colors.amber,
          columnHeight: 130,
          isChampion: true,
          theme: theme,
        ),
        const SizedBox(width: 10),
        // 3rd Place Column
        if (p3 != null)
          _buildPodiumColumn(
            name: p3.team.name,
            teamName: p3.team.teamName,
            points: p3.points,
            logoPath: p3.team.logoPath,
            positionLabel: '3rd',
            medalColor: Colors.brown.shade300,
            columnHeight: 80,
            theme: theme,
          )
        else
          Expanded(child: const SizedBox()),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required String name,
    required String teamName,
    required int points,
    required String? logoPath,
    required String positionLabel,
    required Color medalColor,
    required double columnHeight,
    bool isChampion = false,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown/Trophy Icon
          if (isChampion)
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 26,
            )
          else
            const SizedBox(height: 26),
          const SizedBox(height: 4),

          // Circle Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: medalColor, width: 2),
            ),
            child: TeamLogoWidget(
              logoPath: logoPath,
              teamName: teamName,
              size: 40,
              hasBorder: false,
            ),
          ),
          const SizedBox(height: 8),

          // Team Name
          Text(
            teamName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          
          // Player Name (Optional)
          if (name.isNotEmpty)
            Text(
              '($name)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 2),

          // Points
          Text(
            '$points pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Podium column block
          Container(
            height: columnHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  medalColor.withAlpha((255 * 0.35).toInt()),
                  medalColor.withAlpha((255 * 0.05).toInt()),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: medalColor, width: 2.0),
                left: BorderSide(color: medalColor.withAlpha((255 * 0.15).toInt()), width: 1.0),
                right: BorderSide(color: medalColor.withAlpha((255 * 0.15).toInt()), width: 1.0),
              ),
            ),
            child: Center(
              child: Text(
                positionLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: medalColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

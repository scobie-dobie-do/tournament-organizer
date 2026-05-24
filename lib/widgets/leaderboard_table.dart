import 'package:flutter/material.dart';
import '../models/match.dart';
import '../logic/tournament_logic.dart';
import '../logic/standings_calculator.dart';
import 'leaderboard_row.dart';

class LeaderboardTable extends StatelessWidget {
  final List<TeamStats> standings;
  final List<TournamentMatch> matches;
  final Map<String, int> previousRankings;
  final bool isShortView;
  final double rowHeight;

  const LeaderboardTable({
    super.key,
    required this.standings,
    required this.matches,
    required this.previousRankings,
    required this.isShortView,
    this.rowHeight = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double tableWidth = isShortView ? 390.0 : 600.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: tableWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            _buildHeaderRow(theme),
            const SizedBox(height: 4),

            // Animated Stack List of Rows
            SizedBox(
              height: standings.length * rowHeight,
              child: Stack(
                children: List.generate(standings.length, (index) {
                  final entry = standings[index];
                  final teamId = entry.team.id;
                  final prevRank = previousRankings[teamId];
                  final formList = StandingsCalculator.calculateForm(
                    entry.team,
                    matches,
                  );

                  return AnimatedPositioned(
                    key: ValueKey(teamId),
                    top: index * rowHeight,
                    left: 0,
                    right: 0,
                    height: rowHeight,
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeInOut,
                    child: LeaderboardRow(
                      stats: entry,
                      rank: index + 1,
                      previousRank: prevRank,
                      form: formList,
                      isEvenRow: index.isEven,
                      isShortView: isShortView,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.4).toInt()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('#', width: 36),
          _buildHeaderCell('Team', width: 180, align: TextAlign.left),
          _buildHeaderCell('MP', width: 36),
          _buildHeaderCell('W', width: 32),
          _buildHeaderCell('D', width: 32),
          _buildHeaderCell('L', width: 32),

          // Extra stats columns (animated sliding width & fading opacity)
          AnimatedCell(
            targetWidth: 38,
            isVisible: !isShortView,
            height: 40.0,
            child: _buildHeaderCell('GF', width: 38),
          ),
          AnimatedCell(
            targetWidth: 38,
            isVisible: !isShortView,
            height: 40.0,
            child: _buildHeaderCell('GA', width: 38),
          ),
          AnimatedCell(
            targetWidth: 44,
            isVisible: !isShortView,
            height: 40.0,
            child: _buildHeaderCell('GD', width: 44),
          ),

          _buildHeaderCell('PTS', width: 42, isBold: true),

          // Form column (animated)
          AnimatedCell(
            targetWidth: 90,
            isVisible: !isShortView,
            height: 40.0,
            child: _buildHeaderCell('Form', width: 90),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required double width,
    TextAlign align = TextAlign.center,
    bool isBold = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
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
      ),
    );
  }
}

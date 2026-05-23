import 'package:flutter/material.dart';
import '../models/match.dart';
import '../widgets/team_logo_widget.dart';

/// A compact, preview-only match card used in the Match List Screen.
/// Tapping this card navigates to the Match Detail Screen.
/// Contains NO input fields or editing controls.
class MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final int index;
  final bool isRoundActive;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.index,
    required this.isRoundActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (match.isBye) {
      return _buildByeCard(theme);
    }
    return _buildStandardCard(theme);
  }

  /// Standard match card with team logos, names, and score preview.
  Widget _buildStandardCard(ThemeData theme) {
    final isCompleted = match.isCompleted;
    final homeGoals = match.homeGoals;
    final awayGoals = match.awayGoals;
    final isP1Winner = isCompleted && (homeGoals ?? 0) > (awayGoals ?? 0);
    final isP2Winner = isCompleted && (homeGoals ?? 0) < (awayGoals ?? 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isRoundActive ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : Colors.white.withAlpha((255 * 0.06).toInt()),
                  width: isCompleted ? 3 : 1,
                ),
                top: BorderSide(
                  color: Colors.white.withAlpha((255 * 0.06).toInt()),
                  width: 1,
                ),
                right: BorderSide(
                  color: Colors.white.withAlpha((255 * 0.06).toInt()),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: Colors.white.withAlpha((255 * 0.06).toInt()),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                // Match number badge
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Home team
                Expanded(
                  child: _buildTeamPreview(
                    match.player1,
                    isWinner: isP1Winner,
                    isLoser: isP2Winner,
                    align: CrossAxisAlignment.end,
                    theme: theme,
                  ),
                ),

                // Score / VS section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildScorePreview(
                    isCompleted: isCompleted,
                    homeGoals: homeGoals,
                    awayGoals: awayGoals,
                    isP1Winner: isP1Winner,
                    isP2Winner: isP2Winner,
                    theme: theme,
                  ),
                ),

                // Away team
                Expanded(
                  child: _buildTeamPreview(
                    match.player2!,
                    isWinner: isP2Winner,
                    isLoser: isP1Winner,
                    align: CrossAxisAlignment.start,
                    theme: theme,
                  ),
                ),

                // Tap affordance chevron (only if round is active)
                if (isRoundActive && !isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                  )
                else if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                  )
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact team display for the preview card (logo + name side by side).
  Widget _buildTeamPreview(
    dynamic team,
    {
      required bool isWinner,
      required bool isLoser,
      required CrossAxisAlignment align,
      required ThemeData theme,
    }
  ) {
    final isLeft = align == CrossAxisAlignment.end;
    return Opacity(
      opacity: isLoser ? 0.45 : 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isLeft) ...[
            TeamLogoWidget(
              logoPath: team.logoPath,
              teamName: team.teamName,
              size: 30,
              hasBorder: false,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              team.teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: isLeft ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
                color: isWinner
                    ? theme.colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
          if (isLeft) ...[
            const SizedBox(width: 6),
            TeamLogoWidget(
              logoPath: team.logoPath,
              teamName: team.teamName,
              size: 30,
              hasBorder: false,
            ),
          ],
        ],
      ),
    );
  }

  /// Score preview: shows `2 - 1` if played, `? - ?` if pending.
  Widget _buildScorePreview({
    required bool isCompleted,
    required int? homeGoals,
    required int? awayGoals,
    required bool isP1Winner,
    required bool isP2Winner,
    required ThemeData theme,
  }) {
    if (!isCompleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'vs',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      );
    }

    final isDraw = homeGoals == awayGoals;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${homeGoals ?? 0}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isP1Winner ? theme.colorScheme.primary : Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Text(
              '${awayGoals ?? 0}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isP2Winner ? theme.colorScheme.primary : Colors.white,
              ),
            ),
          ],
        ),
        if (isDraw)
          Text(
            'DRAW',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade500,
              letterSpacing: 1.0,
            ),
          ),
      ],
    );
  }

  /// Slim bye-match card — no score, just shows team advancing automatically.
  Widget _buildByeCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha((255 * 0.04).toInt()),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Team logo + name
            TeamLogoWidget(
              logoPath: match.player1.logoPath,
              teamName: match.player1.teamName,
              size: 32,
              hasBorder: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                match.player1.teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // BYE pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((255 * 0.12).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'BYE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

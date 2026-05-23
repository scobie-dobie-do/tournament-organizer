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
    if (match.isBye) return _buildByeCard(theme);
    return _buildStandardCard(theme);
  }

  // ─── Standard card ────────────────────────────────────────────────────────

  Widget _buildStandardCard(ThemeData theme) {
    final isCompleted = match.isCompleted;
    final homeGoals = match.homeGoals;
    final awayGoals = match.awayGoals;
    final isP1Winner =
        isCompleted && (homeGoals ?? 0) > (awayGoals ?? 0);
    final isP2Winner =
        isCompleted && (homeGoals ?? 0) < (awayGoals ?? 0);
    final isDraw =
        isCompleted && homeGoals != null && homeGoals == awayGoals;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          // Always tappable — detail screen handles inactive-round guard
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((255 * 0.06).toInt()),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                if (isCompleted)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 3,
                    child: Container(
                      color: isDraw
                          ? Colors.blueGrey.shade400
                          : theme.colorScheme.primary,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // ── Main match row ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  child: Row(
                    children: [
                      // Match number badge
                      SizedBox(
                        width: 26,
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
                          alignRight: true,
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
                          alignRight: false,
                          theme: theme,
                        ),
                      ),

                      // Status icon
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: isCompleted
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: isDraw
                                    ? Colors.blueGrey.shade400
                                    : theme.colorScheme.primary,
                                size: 16,
                              )
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                      ),
                    ],
                  ),
                ),

                // ── Winner / Draw badge row ─────────────────────────────
                if (isCompleted)
                  _buildResultBadgeRow(
                    isP1Winner: isP1Winner,
                    isP2Winner: isP2Winner,
                    isDraw: isDraw,
                    theme: theme,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  // ─── Winner / draw badge row (shown only after result saved) ─────────────

  Widget _buildResultBadgeRow({
    required bool isP1Winner,
    required bool isP2Winner,
    required bool isDraw,
    required ThemeData theme,
  }) {
    final String label;
    final IconData icon;
    final Color bgColor;
    final Color fgColor;

    if (isDraw) {
      label = 'Draw';
      icon = Icons.handshake_rounded;
      bgColor = Colors.blueGrey.shade800;
      fgColor = Colors.blueGrey.shade200;
    } else if (isP1Winner) {
      label = '${match.player1.teamName} wins';
      icon = Icons.emoji_events_rounded;
      bgColor = theme.colorScheme.primary.withAlpha((255 * 0.14).toInt());
      fgColor = theme.colorScheme.primary;
    } else {
      label = '${match.player2!.teamName} wins';
      icon = Icons.emoji_events_rounded;
      bgColor = theme.colorScheme.primary.withAlpha((255 * 0.14).toInt());
      fgColor = theme.colorScheme.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          // Winner / Draw pill badge
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: fgColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: fgColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tap hint
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 11, color: Colors.grey.shade700),
              const SizedBox(width: 3),
              Text(
                'Edit',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Team name + logo preview ─────────────────────────────────────────────

  Widget _buildTeamPreview(
    dynamic team, {
    required bool isWinner,
    required bool isLoser,
    required bool alignRight,
    required ThemeData theme,
  }) {
    return Opacity(
      opacity: isLoser ? 0.4 : 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!alignRight) ...[
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
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner ? FontWeight.w900 : FontWeight.w600,
                color: isWinner ? theme.colorScheme.primary : Colors.white,
              ),
            ),
          ),
          if (alignRight) ...[
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

  // ─── Score pill (center of card) ─────────────────────────────────────────

  Widget _buildScorePreview({
    required bool isCompleted,
    required int? homeGoals,
    required int? awayGoals,
    required bool isP1Winner,
    required bool isP2Winner,
    required ThemeData theme,
  }) {
    if (!isCompleted) {
      return Text(
        'vs',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade600,
          letterSpacing: 1.0,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${homeGoals ?? 0}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isP1Winner ? theme.colorScheme.primary : Colors.white,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '–',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Text(
          '${awayGoals ?? 0}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isP2Winner ? theme.colorScheme.primary : Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Bye card ─────────────────────────────────────────────────────────────

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
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withAlpha((255 * 0.12).toInt()),
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

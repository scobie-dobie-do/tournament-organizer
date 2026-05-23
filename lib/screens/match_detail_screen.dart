import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import '../widgets/team_logo_widget.dart';

/// Match Detail Screen — full score editing for a single match.
/// Receives [tournamentState] directly and mutates it inline.
/// Returns `true` via Navigator.pop() when a result is saved/cleared.
class MatchDetailScreen extends StatefulWidget {
  /// The live tournament state — mutated in-place on save/undo.
  final TournamentState tournamentState;

  /// The ID of the match to edit — used to always look up the freshest copy.
  final String matchId;

  /// Whether this round is currently active (controls save/undo buttons).
  final bool isRoundActive;

  const MatchDetailScreen({
    super.key,
    required this.tournamentState,
    required this.matchId,
    required this.isRoundActive,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late int _homeGoals;
  late int _awayGoals;

  /// Always look up the freshest match from the live state.
  TournamentMatch get _livematch => widget.tournamentState.matches
      .firstWhere((m) => m.id == widget.matchId);

  @override
  void initState() {
    super.initState();
    final m = _livematch;
    _homeGoals = m.homeGoals ?? 0;
    _awayGoals = m.awayGoals ?? 0;
  }

  bool get _isDraw => _homeGoals == _awayGoals;
  bool get _isKnockout =>
      widget.tournamentState.format == TournamentFormat.knockout;

  // ─── Save ──────────────────────────────────────────────────────────────────

  void _onSaveTap() {
    if (_isKnockout && _isDraw) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Knockout matches cannot end in a draw. Please enter a winning score.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    final theme = Theme.of(context);
    final m = _livematch;
    final p1 = m.player1;
    final p2 = m.player2!;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Result',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save this match result?',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      p1.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _homeGoals > _awayGoals
                            ? theme.colorScheme.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_homeGoals  –  $_awayGoals',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p2.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _awayGoals > _homeGoals
                            ? theme.colorScheme.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        // Mutate the shared TournamentState directly, then pop.
        // MatchListScreen will call setState in its .then() callback.
        widget.tournamentState
            .recordMatchResult(widget.matchId, _homeGoals, _awayGoals);
        Navigator.pop(context, true);
      }
    });
  }

  // ─── Undo ──────────────────────────────────────────────────────────────────

  void _onUndoTap() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Undo Result',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Text(
          'This will clear the saved result and mark the match as pending again. Continue?',
          style:
              TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Undo',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        widget.tournamentState.clearMatchResult(widget.matchId);
        Navigator.pop(context, true);
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = _livematch;
    final p1 = match.player1;
    final p2 = match.player2!;
    final isCompleted = match.isCompleted;
    final isP1Winner =
        isCompleted && (match.homeGoals ?? 0) > (match.awayGoals ?? 0);
    final isP2Winner =
        isCompleted && (match.homeGoals ?? 0) < (match.awayGoals ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          match.isBye ? 'Bye Match' : 'Match Details',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status badge ─────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? theme.colorScheme.primary
                            .withAlpha((255 * 0.12).toInt())
                        : Colors.orange
                            .withAlpha((255 * 0.12).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? theme.colorScheme.primary
                              .withAlpha((255 * 0.4).toInt())
                          : Colors.orange
                              .withAlpha((255 * 0.4).toInt()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 14,
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCompleted ? 'COMPLETED' : 'PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Teams & Score card ────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTeamPanel(
                              team: p1,
                              isWinner: isP1Winner,
                              isLoser: isP2Winner,
                              theme: theme,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: _buildScoreSection(
                                  isCompleted, theme),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildTeamPanel(
                              team: p2,
                              isWinner: isP2Winner,
                              isLoser: isP1Winner,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),

                      // Result summary (shown only when completed)
                      if (isCompleted) ...[
                        const SizedBox(height: 16),
                        Divider(
                          color:
                              Colors.white.withAlpha((255 * 0.06).toInt()),
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        _buildResultSummary(match, p1, p2, theme),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Action buttons ────────────────────────────────────────
              if (widget.isRoundActive && !match.isBye) ...[
                if (!isCompleted)
                  ElevatedButton.icon(
                    onPressed: _onSaveTap,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text(
                      'Save Result',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _onUndoTap,
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    label: const Text(
                      'Undo Result',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error
                            .withAlpha((255 * 0.6).toInt()),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
              ],

              if (!widget.isRoundActive)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'This round is not active yet.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildTeamPanel({
    required Player team,
    required bool isWinner,
    required bool isLoser,
    required ThemeData theme,
  }) {
    return Opacity(
      opacity: isLoser ? 0.45 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TeamLogoWidget(
            logoPath: team.logoPath,
            teamName: team.teamName,
            size: 56,
            hasBorder: isWinner,
          ),
          const SizedBox(height: 10),
          Text(
            team.teamName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isWinner ? FontWeight.w900 : FontWeight.bold,
              color: isWinner
                  ? theme.colorScheme.primary
                  : Colors.white,
            ),
          ),
          if (team.name.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreSection(bool isCompleted, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScoreControl(
          goals: _homeGoals,
          onDecrement:
              _homeGoals > 0 ? () => setState(() => _homeGoals--) : null,
          onIncrement: () => setState(() => _homeGoals++),
          isEditable: !isCompleted && widget.isRoundActive,
          isWinnerScore: isCompleted && _homeGoals > _awayGoals,
          theme: theme,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'VS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade600,
              letterSpacing: 2,
            ),
          ),
        ),
        _buildScoreControl(
          goals: _awayGoals,
          onDecrement:
              _awayGoals > 0 ? () => setState(() => _awayGoals--) : null,
          onIncrement: () => setState(() => _awayGoals++),
          isEditable: !isCompleted && widget.isRoundActive,
          isWinnerScore: isCompleted && _awayGoals > _homeGoals,
          theme: theme,
        ),
        if (!isCompleted && _isKnockout && _isDraw && _homeGoals > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Draw not allowed in Knockout',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreControl({
    required int goals,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
    required bool isEditable,
    required bool isWinnerScore,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isEditable ? 4 : 8,
        vertical: isEditable ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isWinnerScore
            ? theme.colorScheme.primary
                .withAlpha((255 * 0.1).toInt())
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinnerScore
              ? theme.colorScheme.primary
                  .withAlpha((255 * 0.3).toInt())
              : Colors.white.withAlpha((255 * 0.05).toInt()),
          width: 1.5,
        ),
      ),
      child: isEditable
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GoalButton(
                  icon: Icons.remove,
                  onPressed: onDecrement,
                  theme: theme,
                ),
                Text(
                  '$goals',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isWinnerScore
                        ? theme.colorScheme.primary
                        : Colors.white,
                  ),
                ),
                _GoalButton(
                  icon: Icons.add,
                  onPressed: onIncrement,
                  theme: theme,
                ),
              ],
            )
          : Center(
              child: Text(
                '$goals',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isWinnerScore
                      ? theme.colorScheme.primary
                      : Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildResultSummary(
      TournamentMatch match, Player p1, Player p2, ThemeData theme) {
    final hg = match.homeGoals ?? 0;
    final ag = match.awayGoals ?? 0;
    final isDraw = hg == ag;
    final label = isDraw
        ? 'Match Drawn'
        : hg > ag
            ? '${p1.teamName} wins'
            : '${p2.teamName} wins';

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: isDraw
            ? Colors.grey.shade400
            : theme.colorScheme.primary,
      ),
    );
  }
}

// ─── Goal Button ─────────────────────────────────────────────────────────────

class _GoalButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ThemeData theme;

  const _GoalButton({
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: onPressed != null
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerLow
                  .withAlpha((255 * 0.4).toInt()),
          foregroundColor: onPressed != null
              ? theme.colorScheme.primary
              : Colors.grey.shade700,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

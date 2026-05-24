import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import '../widgets/team_logo_widget.dart';

class MatchDetailScreen extends StatefulWidget {
  final TournamentState tournamentState;
  final String matchId;
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
  late String _status;
  int? _homePenalties;
  int? _awayPenalties;
  late bool _isExtraTime;

  TournamentMatch get _livematch => widget.tournamentState.matches
      .firstWhere((m) => m.id == widget.matchId);

  bool get isCompleted => _status == 'completed';

  @override
  void initState() {
    super.initState();
    final m = _livematch;
    _homeGoals = m.homeGoals ?? 0;
    _awayGoals = m.awayGoals ?? 0;
    _status = m.isCompleted ? 'completed' : 'scheduled';
    _homePenalties = m.homePenalties;
    _awayPenalties = m.awayPenalties;
    _isExtraTime = m.isExtraTime;
  }

  bool get _requiresTieBreaker {
    if (widget.tournamentState.format != TournamentFormat.knockout) return false;
    final m = _livematch;
    if (m.totalLegs == 1) {
      return _homeGoals == _awayGoals;
    } else {
      if (m.legNumber != m.totalLegs) return false;

      final matchesGroup = widget.tournamentState.matches
          .where((x) => x.aggregateGroupId == m.aggregateGroupId)
          .toList();
      
      final p1 = m.player1;
      final p2 = m.player2;
      if (p2 == null) return false;

      int goals1 = 0;
      int goals2 = 0;
      int awayGoals1 = 0;
      int awayGoals2 = 0;

      for (var x in matchesGroup) {
        final hg = x.id == m.id ? _homeGoals : (x.homeGoals ?? 0);
        final ag = x.id == m.id ? _awayGoals : (x.awayGoals ?? 0);

        if (x.player1.id == p1.id) {
          goals1 += hg;
          goals2 += ag;
          awayGoals2 += ag;
        } else {
          goals2 += hg;
          goals1 += ag;
          awayGoals1 += ag;
        }
      }

      if (goals1 != goals2) return false;

      if (widget.tournamentState.awayGoalsRule) {
        if (awayGoals1 != awayGoals2) return false;
      }

      return true;
    }
  }

  void _onSaveTap() {
    if (widget.tournamentState.format == TournamentFormat.knockout) {
      if (_requiresTieBreaker) {
        if (_homePenalties == null || _awayPenalties == null) {
          _showErrorSnackBar('Knockout match tie requires penalty shootout scores.');
          return;
        }
        if (_homePenalties == _awayPenalties) {
          _showErrorSnackBar('Penalty shootout scores cannot end in a draw.');
          return;
        }
      } else {
        if (_homeGoals == _awayGoals && _livematch.totalLegs == 1) {
          _showErrorSnackBar('Single-leg knockout matches cannot end in a draw.');
          return;
        }
      }
    }
    _showConfirmDialog();
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        color: _homeGoals > _awayGoals ? theme.colorScheme.primary : Colors.white,
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
                        color: _awayGoals > _homeGoals ? theme.colorScheme.primary : Colors.white,
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
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        widget.tournamentState.recordMatchResult(
          widget.matchId,
          _homeGoals,
          _awayGoals,
          homePenalties: _requiresTieBreaker ? _homePenalties : null,
          awayPenalties: _requiresTieBreaker ? _awayPenalties : null,
          events: const [],
          notes: null,
          mvp: null,
          status: 'completed',
          isExtraTime: _isExtraTime,
          isPenalties: _requiresTieBreaker,
        );
        Navigator.pop(context, true);
      }
    });
  }

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
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.w900)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = _livematch;
    final p1 = match.player1;
    final p2 = match.player2!;
    final isCompleted = _status == 'completed';

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Status Header ---
              _buildClockHeader(theme),
              const SizedBox(height: 24),

              // --- Teams & Score Panel ---
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
                              isWinner: isCompleted && _homeGoals > _awayGoals,
                              isLoser: isCompleted && _homeGoals < _awayGoals,
                              theme: theme,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildScoreSection(isCompleted, theme),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildTeamPanel(
                              team: p2,
                              isWinner: isCompleted && _awayGoals > _homeGoals,
                              isLoser: isCompleted && _awayGoals < _homeGoals,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withAlpha((255 * 0.06).toInt()), height: 1),
                        const SizedBox(height: 12),
                        _buildResultSummary(match, p1, p2, theme),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Shootout & Extra Time Tie-Breaker Block ---
              if (_requiresTieBreaker && !isCompleted && widget.isRoundActive)
                _buildTieBreakerSection(theme),

              const SizedBox(height: 24),

              // --- Bottom Actions ---
              if (widget.isRoundActive && !match.isBye) ...[
                if (!isCompleted)
                  ElevatedButton.icon(
                    onPressed: _onSaveTap,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text(
                      'Save Result',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _onUndoTap,
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    label: const Text(
                      'Undo Result',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withAlpha((255 * 0.6).toInt()), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClockHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _status == 'completed'
                ? theme.colorScheme.primary.withAlpha((255 * 0.12).toInt())
                : Colors.orange.withAlpha((255 * 0.12).toInt()),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _status == 'completed'
                  ? theme.colorScheme.primary.withAlpha((255 * 0.4).toInt())
                  : Colors.orange.withAlpha((255 * 0.4).toInt()),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _status == 'completed' ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                size: 14,
                color: _status == 'completed' ? theme.colorScheme.primary : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                _status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: _status == 'completed' ? theme.colorScheme.primary : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              fontWeight: isWinner ? FontWeight.w900 : FontWeight.bold,
              color: isWinner ? theme.colorScheme.primary : Colors.white,
            ),
          ),
          if (team.name.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
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
          onDecrement: _homeGoals > 0 && !isCompleted && widget.isRoundActive
              ? () => setState(() => _homeGoals--)
              : null,
          onIncrement: !isCompleted && widget.isRoundActive ? () => setState(() => _homeGoals++) : null,
          isEditable: !isCompleted && widget.isRoundActive,
          isWinnerScore: isCompleted && _homeGoals > _awayGoals,
          theme: theme,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'VS',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 2),
          ),
        ),
        _buildScoreControl(
          goals: _awayGoals,
          onDecrement: _awayGoals > 0 && !isCompleted && widget.isRoundActive
              ? () => setState(() => _awayGoals--)
              : null,
          onIncrement: !isCompleted && widget.isRoundActive ? () => setState(() => _awayGoals++) : null,
          isEditable: !isCompleted && widget.isRoundActive,
          isWinnerScore: isCompleted && _awayGoals > _homeGoals,
          theme: theme,
        ),
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
      padding: EdgeInsets.symmetric(horizontal: isEditable ? 4 : 8, vertical: isEditable ? 6 : 8),
      decoration: BoxDecoration(
        color: isWinnerScore ? theme.colorScheme.primary.withAlpha((255 * 0.1).toInt()) : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinnerScore ? theme.colorScheme.primary.withAlpha((255 * 0.3).toInt()) : Colors.white.withAlpha((255 * 0.05).toInt()),
          width: 1.5,
        ),
      ),
      child: isEditable
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoalButton(icon: Icons.remove, onPressed: onDecrement, theme: theme),
                  const SizedBox(width: 6),
                  Text(
                    '$goals',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isWinnerScore ? theme.colorScheme.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _GoalButton(icon: Icons.add, onPressed: onIncrement, theme: theme),
                ],
              ),
            )
          : Center(
              child: Text(
                '$goals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isWinnerScore ? theme.colorScheme.primary : Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildTieBreakerSection(ThemeData theme) {
    return Card(
      color: Colors.orange.withAlpha((255 * 0.05).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.withAlpha((255 * 0.2).toInt()), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'TIE-BREAKER REQUIRED',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.orange, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Extra Time Played', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              value: _isExtraTime,
              activeThumbColor: Colors.orange,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _isExtraTime = val;
                });
              },
            ),
            const Divider(color: Colors.white12, height: 16),
            const Text(
              'Penalty Shootout Scores',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _homePenalties,
                    decoration: const InputDecoration(labelText: 'Home Pens', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (val) => setState(() => _homePenalties = val),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _awayPenalties,
                    decoration: const InputDecoration(labelText: 'Away Pens', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (val) => setState(() => _awayPenalties = val),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(TournamentMatch match, Player p1, Player p2, ThemeData theme) {
    final hg = _homeGoals;
    final ag = _awayGoals;
    final isDraw = hg == ag;
    String label = isDraw ? 'Match Drawn' : (hg > ag ? '${p1.teamName} wins' : '${p2.teamName} wins');

    if (match.isPenalties && match.homePenalties != null && match.awayPenalties != null) {
      final hp = match.homePenalties!;
      final ap = match.awayPenalties!;
      label = hp > ap ? '${p1.teamName} wins on pens ($hp-$ap)' : '${p2.teamName} wins on pens ($ap-$hp)';
    }

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
    );
  }
}

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
              : theme.colorScheme.surfaceContainerLow.withAlpha((255 * 0.4).toInt()),
          foregroundColor: onPressed != null ? theme.colorScheme.primary : Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

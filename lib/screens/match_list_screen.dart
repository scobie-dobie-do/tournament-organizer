import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import '../logic/knockout_engine.dart';
import 'standings_screen.dart';
import 'match_detail_screen.dart';
import '../widgets/match_card.dart';
import '../widgets/knockout_bracket_view.dart';
import '../services/export_service.dart';
import '../storage/database_service.dart';

/// Match List Screen — lists matches grouped by Leg or displayed in a tree bracket.
/// Settings button triggers lock options, reset dialogues, and PDF exports.
class MatchListScreen extends StatefulWidget {
  final TournamentState tournamentState;

  const MatchListScreen({
    super.key,
    required this.tournamentState,
  });

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  String _filter = 'All';
  bool _isBracketView = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Route<Object?> _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (ctx, anim, secAnim) => page,
      transitionsBuilder: (ctx, anim, secAnim, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: anim.drive(tween),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  Route<bool> _slideUpRoute(Widget page) {
    return PageRouteBuilder<bool>(
      pageBuilder: (ctx, anim, secAnim) => page,
      transitionsBuilder: (ctx, anim, secAnim, child) {
        const begin = Offset(0.0, 0.08);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: anim.drive(tween),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _openMatchDetail(TournamentMatch match) {
    final state = widget.tournamentState;
    final isRoundActive = state.format == TournamentFormat.roundRobin ||
        match.roundIndex == state.currentRoundIndex;

    Navigator.push<bool>(
      context,
      _slideUpRoute(
        MatchDetailScreen(
          tournamentState: state,
          matchId: match.id,
          isRoundActive: isRoundActive,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _advanceRound() {
    setState(() {
      widget.tournamentState.advanceKnockoutRound();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Round ${widget.tournamentState.currentRoundIndex} Generated!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAdminSettings(BuildContext context, TournamentState state) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ADMIN CONTROLS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lock Toggle Switch
                    SwitchListTile(
                      title: const Text('Lock Tournament', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Prevents accidental changes to match results', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: state.locked,
                      activeThumbColor: Colors.orange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          state.locked = val;
                        });
                        setSheetState(() {});
                        DatabaseService().saveTournament(state);
                      },
                    ),
                    const Divider(color: Colors.white12, height: 8),

                    // Reset Tournament Button
                    ListTile(
                      leading: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                      title: const Text('Reset Tournament', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Clears all recorded scores and restarts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showResetConfirmation(context, state);
                      },
                    ),
                    const Divider(color: Colors.white12, height: 8),

                    // Export PDF Report
                    ListTile(
                      leading: Icon(Icons.picture_as_pdf_rounded, color: theme.colorScheme.primary),
                      title: const Text('Export PDF Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Generates printable tournament PDF document', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(ctx);
                        ExportService.printTournamentPdf(state);
                      },
                    ),
                    
                    // Share Text Summary
                    ListTile(
                      leading: Icon(Icons.share_rounded, color: theme.colorScheme.primary),
                      title: const Text('Share Summary Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Copies text summary of standings to share', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(ctx);
                        ExportService.shareStandingsText(state);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, TournamentState state) {
    final theme = Theme.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Tournament?',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        content: Text(
          'This action is permanent and will completely reset all scores, standings, and history logs.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset Now', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        if (!context.mounted) return;
        setState(() {
          state.resetTournament();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tournament has been reset.'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // ─── Filtering ────────────────────────────────────────────────────────────

  List<TournamentMatch> _applyFilter(List<TournamentMatch> matches) {
    if (_filter == 'Pending') {
      return matches.where((m) => !m.isCompleted).toList();
    } else if (_filter == 'Completed') {
      return matches.where((m) => m.isCompleted).toList();
    }
    return matches;
  }

  // ─── Champion ────────────────────────────────────────────────────────────

  Player? _getChampion() {
    final state = widget.tournamentState;
    if (!state.isCompleted) return null;
    if (state.format == TournamentFormat.knockout) {
      return KnockoutEngine.getChampion(state.matches, state.currentRoundIndex, state.awayGoalsRule);
    } else {
      final lb = state.getLeaderboard();
      if (lb.isNotEmpty) return lb.first.team;
    }
    return null;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = widget.tournamentState;
    final theme = Theme.of(context);
    final champion = _getChampion();

    Widget content = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              state.format == TournamentFormat.knockout ? 'Knockout Bracket' : 'League Matches',
            ),
            if (state.locked) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_rounded, color: Colors.orange, size: 16),
            ]
          ],
        ),
        actions: [
          if (state.format == TournamentFormat.knockout)
            IconButton(
              icon: Icon(_isBracketView ? Icons.list_rounded : Icons.account_tree_outlined),
              tooltip: _isBracketView ? 'Switch to List View' : 'Switch to Bracket View',
              onPressed: () {
                setState(() {
                  _isBracketView = !_isBracketView;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: 'Standings',
            onPressed: () {
              Navigator.push(
                context,
                _slideRoute(StandingsScreen(tournamentState: state)),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings & Admin',
            onPressed: () => _showAdminSettings(context, state),
          ),
          const SizedBox(width: 4),
        ],
        bottom: (state.format == TournamentFormat.knockout && !_isBracketView)
            ? TabBar(
                isScrollable: state.currentRoundIndex > 4,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: List.generate(
                  state.currentRoundIndex,
                  (i) => Tab(text: 'Round ${i + 1}'),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Champion banner ───────────────────────────────────────
            if (champion != null) _buildChampionBanner(champion, state, theme),

            // ── Round Robin filter bar ────────────────────────────────
            if (state.format == TournamentFormat.roundRobin) _buildFilterBar(theme),

            // ── Match list ───────────────────────────────────────────
            Expanded(
              child: state.format == TournamentFormat.knockout
                  ? (_isBracketView
                      ? KnockoutBracketView(
                          tournamentState: state,
                          onMatchTap: _openMatchDetail,
                        )
                      : TabBarView(
                          children: List.generate(
                            state.currentRoundIndex,
                            (roundIdx) {
                              final roundMatches = state.matches
                                  .where((m) => m.roundIndex == roundIdx + 1)
                                  .toList();
                              return _buildList(roundMatches, theme);
                            },
                          ),
                        ))
                  : _buildList(
                      _applyFilter(state.matches),
                      theme,
                    ),
            ),

            // ── Advance Round button (Knockout only) ──────────────────
            if (state.format == TournamentFormat.knockout && state.canAdvanceKnockout)
              _buildAdvanceButton(theme),
          ],
        ),
      ),
    );

    if (state.format == TournamentFormat.knockout && !_isBracketView) {
      content = DefaultTabController(
        key: ValueKey('ko_tabs_${state.currentRoundIndex}'),
        length: state.currentRoundIndex,
        initialIndex: state.currentRoundIndex - 1,
        child: content,
      );
    }

    return content;
  }

  // ─── Section builders ─────────────────────────────────────────────────────

  Widget _buildChampionBanner(Player champion, TournamentState state, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha((255 * 0.25).toInt()),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CHAMPION',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  champion.name.isNotEmpty ? '${champion.teamName} · ${champion.name}' : champion.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                _slideRoute(StandingsScreen(tournamentState: state)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            child: const Text('Standings'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          backgroundColor: theme.cardTheme.color,
          selectedBackgroundColor: theme.colorScheme.primary,
          selectedForegroundColor: theme.colorScheme.surface,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        segments: const [
          ButtonSegment<String>(
            value: 'All',
            label: Text('All'),
            icon: Icon(Icons.list_rounded, size: 16),
          ),
          ButtonSegment<String>(
            value: 'Pending',
            label: Text('Pending'),
            icon: Icon(Icons.hourglass_empty_rounded, size: 16),
          ),
          ButtonSegment<String>(
            value: 'Completed',
            label: Text('Played'),
            icon: Icon(Icons.check_circle_outline_rounded, size: 16),
          ),
        ],
        selected: {_filter},
        onSelectionChanged: (s) => setState(() => _filter = s.first),
      ),
    );
  }

  Widget _buildList(List<TournamentMatch> matches, ThemeData theme) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 56, color: Colors.grey.shade700),
            const SizedBox(height: 14),
            Text(
              'No matches here',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Group matches by legNumber
    final Map<int, List<TournamentMatch>> groupedByLeg = {};
    for (var m in matches) {
      groupedByLeg.putIfAbsent(m.legNumber, () => []).add(m);
    }

    final sortedLegs = groupedByLeg.keys.toList()..sort();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: sortedLegs.length,
      itemBuilder: (context, legIdx) {
        final legNumber = sortedLegs[legIdx];
        final legMatches = groupedByLeg[legNumber]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupedByLeg.length > 1) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 4.0),
                child: Text(
                  'LEG $legNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
            ...List.generate(legMatches.length, (matchIndex) {
              final match = legMatches[matchIndex];
              final isRoundActive = widget.tournamentState.format == TournamentFormat.roundRobin ||
                  match.roundIndex == widget.tournamentState.currentRoundIndex;

              return MatchCard(
                match: match,
                index: matchIndex,
                isRoundActive: isRoundActive,
                onTap: () => _openMatchDetail(match),
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildAdvanceButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withAlpha((255 * 0.06).toInt()),
          ),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: _advanceRound,
        icon: const Icon(Icons.navigate_next_rounded, size: 22),
        label: const Text(
          'Advance to Next Round',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.surface,
          elevation: 3,
          shadowColor: theme.colorScheme.primary.withAlpha((255 * 0.25).toInt()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

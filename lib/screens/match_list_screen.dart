import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import 'standings_screen.dart';
import 'match_detail_screen.dart';
import '../widgets/match_card.dart';
import '../widgets/knockout_bracket_view.dart';

/// Match List Screen — preview-only list of matches for a tournament.
/// Tapping a match navigates to [MatchDetailScreen] for score editing.
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
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
      // Always force a full rebuild when returning from detail.
      // state.matches is already updated (mutated in-place) by MatchDetailScreen.
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
        content: Text(
            'Round ${widget.tournamentState.currentRoundIndex} Generated!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
      final finals = state.matches
          .where((m) => m.roundIndex == state.currentRoundIndex)
          .toList();
      if (finals.isNotEmpty && finals.first.winner != null) {
        return finals.first.winner;
      }
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
        title: Text(
          state.format == TournamentFormat.knockout
              ? 'Knockout Bracket'
              : 'League Matches',
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
          const SizedBox(width: 4),
        ],
        bottom: (state.format == TournamentFormat.knockout && !_isBracketView)
            ? TabBar(
                isScrollable: state.currentRoundIndex > 4,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
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
            if (state.format == TournamentFormat.roundRobin)
              _buildFilterBar(theme),

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
            if (state.format == TournamentFormat.knockout &&
                state.canAdvanceKnockout)
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

  Widget _buildChampionBanner(
      Player champion, TournamentState state, ThemeData theme) {
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
                  champion.name.isNotEmpty
                      ? '${champion.teamName} · ${champion.name}'
                      : champion.teamName,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 12),
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
          textStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
            Icon(Icons.sports_soccer_rounded,
                size: 56, color: Colors.grey.shade700),
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final isRoundActive =
            widget.tournamentState.format == TournamentFormat.roundRobin ||
                match.roundIndex == widget.tournamentState.currentRoundIndex;

        return MatchCard(
          match: match,
          index: index,
          isRoundActive: isRoundActive,
          onTap: () => _openMatchDetail(match),
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
          shadowColor:
              theme.colorScheme.primary.withAlpha((255 * 0.25).toInt()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

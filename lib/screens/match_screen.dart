import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import 'leaderboard_screen.dart';
import '../widgets/team_logo_widget.dart';

class MatchScreen extends StatefulWidget {
  final TournamentState tournamentState;

  const MatchScreen({
    super.key,
    required this.tournamentState,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    final state = widget.tournamentState;
    if (state.format == TournamentFormat.knockout) {
      _tabController = TabController(
        length: state.currentRoundIndex,
        vsync: this,
        initialIndex: state.currentRoundIndex - 1,
      );
    } else {
      _tabController = TabController(length: 1, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  void _updateTabController() {
    final state = widget.tournamentState;
    final newLength = state.currentRoundIndex;
    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: newLength - 1,
      );
    }
  }

  void _advanceRound() {
    setState(() {
      widget.tournamentState.advanceKnockoutRound();
      _updateTabController();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Round ${widget.tournamentState.currentRoundIndex} Generated!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Route _createAnimatedRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.tournamentState;
    final theme = Theme.of(context);

    Player? champion;
    if (state.isCompleted) {
      if (state.format == TournamentFormat.knockout) {
        final finalRoundMatches = state.matches.where((m) => m.roundIndex == state.currentRoundIndex).toList();
        if (finalRoundMatches.isNotEmpty && finalRoundMatches.first.winner != null) {
          champion = finalRoundMatches.first.winner;
        }
      } else {
        final leaderboard = state.getLeaderboard();
        if (leaderboard.isNotEmpty) {
          champion = leaderboard.first.team;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.format == TournamentFormat.knockout
            ? 'Knockout Bracket'
            : 'Round Robin Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: 'View Leaderboard',
            onPressed: () {
              Navigator.push(
                context,
                _createAnimatedRoute(LeaderboardScreen(tournamentState: state)),
              ).then((_) {
                setState(() {});
              });
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: state.format == TournamentFormat.knockout
            ? TabBar(
                controller: _tabController,
                isScrollable: state.currentRoundIndex > 4,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: List.generate(state.currentRoundIndex, (index) {
                  return Tab(text: 'Round ${index + 1}');
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Champion Display Banner Card (Styled with dark green details)
            if (state.isCompleted && champion != null)
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha((255 * 0.25).toInt()),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHAMPION CROWNED',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            champion.name.isNotEmpty
                                ? '${champion.teamName} (${champion.name})'
                                : champion.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          _createAnimatedRoute(LeaderboardScreen(tournamentState: state)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      child: const Text('Standings'),
                    ),
                  ],
                ),
              ),

            // 2. Round Robin Filter Bar
            if (state.format == TournamentFormat.roundRobin)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: theme.cardTheme.color,
                    selectedBackgroundColor: theme.colorScheme.primary,
                    selectedForegroundColor: theme.colorScheme.surface,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  segments: const [
                    ButtonSegment<String>(
                      value: 'All',
                      label: Text('All'),
                      icon: Icon(Icons.list_rounded),
                    ),
                    ButtonSegment<String>(
                      value: 'Pending',
                      label: Text('Pending'),
                      icon: Icon(Icons.hourglass_empty_rounded),
                    ),
                    ButtonSegment<String>(
                      value: 'Completed',
                      label: Text('Played'),
                      icon: Icon(Icons.check_circle_outline_rounded),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _filter = newSelection.first;
                    });
                  },
                ),
              ),

            // 3. Match List Display
            Expanded(
              child: state.format == TournamentFormat.knockout
                  ? TabBarView(
                      controller: _tabController,
                      children: List.generate(state.currentRoundIndex, (roundIdx) {
                        final roundMatches = state.matches
                            .where((m) => m.roundIndex == roundIdx + 1)
                            .toList();
                        return _buildMatchesList(roundMatches, theme);
                      }),
                    )
                  : _buildMatchesList(
                      _getFilteredMatches(state.matches),
                      theme,
                    ),
            ),
            
            // 4. Knockout Navigation Panel (At bottom of Bracket screen)
            if (state.format == TournamentFormat.knockout && state.canAdvanceKnockout)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withAlpha((255 * 0.05).toInt()),
                    ),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _advanceRound,
                  icon: const Icon(Icons.navigate_next_rounded, size: 24),
                  label: const Text(
                    'Advance to Next Round',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.surface,
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withAlpha((255 * 0.2).toInt()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<TournamentMatch> _getFilteredMatches(List<TournamentMatch> allMatches) {
    if (_filter == 'Pending') {
      return allMatches.where((m) => !m.isCompleted).toList();
    } else if (_filter == 'Completed') {
      return allMatches.where((m) => m.isCompleted).toList();
    }
    return allMatches;
  }

  Widget _buildMatchesList(List<TournamentMatch> matchesList, ThemeData theme) {
    if (matchesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_rounded,
              size: 58,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              'No matches found',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: matchesList.length,
      itemBuilder: (context, index) {
        final match = matchesList[index];
        final isRoundActive = widget.tournamentState.format == TournamentFormat.roundRobin ||
            match.roundIndex == widget.tournamentState.currentRoundIndex;

        return _MatchCardWidget(
          match: match,
          index: index,
          isRoundActive: isRoundActive,
          format: widget.tournamentState.format,
          onSaveResult: (hg, ag) {
            setState(() {
              widget.tournamentState.recordMatchResult(match.id, hg, ag);
              if (widget.tournamentState.format == TournamentFormat.knockout) {
                _updateTabController();
              }
            });
          },
          onClearResult: () {
            setState(() {
              widget.tournamentState.clearMatchResult(match.id);
              if (widget.tournamentState.format == TournamentFormat.knockout) {
                _updateTabController();
              }
            });
          },
        );
      },
    );
  }
}

// Private Match Card widget with stateful score controllers
class _MatchCardWidget extends StatefulWidget {
  final TournamentMatch match;
  final int index;
  final bool isRoundActive;
  final TournamentFormat format;
  final Function(int homeGoals, int awayGoals) onSaveResult;
  final VoidCallback onClearResult;

  const _MatchCardWidget({
    required this.match,
    required this.index,
    required this.isRoundActive,
    required this.format,
    required this.onSaveResult,
    required this.onClearResult,
  });

  @override
  State<_MatchCardWidget> createState() => _MatchCardWidgetState();
}

class _MatchCardWidgetState extends State<_MatchCardWidget> {
  late int _homeGoals;
  late int _awayGoals;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _resetInputs();
  }

  @override
  void didUpdateWidget(covariant _MatchCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match != widget.match) {
      _resetInputs();
    }
  }

  void _resetInputs() {
    _homeGoals = widget.match.homeGoals ?? 0;
    _awayGoals = widget.match.awayGoals ?? 0;
    _isEditing = !widget.match.isCompleted;
  }

  void _saveResult() {
    if (widget.format == TournamentFormat.knockout && _homeGoals == _awayGoals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Knockout matches cannot end in a draw. Please enter a winning score.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSaveResult(_homeGoals, _awayGoals);
    setState(() {
      _isEditing = false;
    });
  }

  void _editResult() {
    setState(() {
      _isEditing = true;
    });
    widget.onClearResult();
  }

  Widget _buildScoreControls(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _buildGoalButton(
                  icon: Icons.remove,
                  onPressed: _homeGoals > 0 ? () => setState(() => _homeGoals--) : null,
                  theme: theme,
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$_homeGoals',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                _buildGoalButton(
                  icon: Icons.add,
                  onPressed: () => setState(() => _homeGoals++),
                  theme: theme,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Row(
              children: [
                _buildGoalButton(
                  icon: Icons.remove,
                  onPressed: _awayGoals > 0 ? () => setState(() => _awayGoals--) : null,
                  theme: theme,
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$_awayGoals',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                _buildGoalButton(
                  icon: Icons.add,
                  onPressed: () => setState(() => _awayGoals++),
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saveResult,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(120, 36),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save Result', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildGoalButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerLow.withAlpha((255 * 0.5).toInt()),
          foregroundColor: theme.colorScheme.primary,
          disabledForegroundColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCompletedScoreDisplay(ThemeData theme) {
    final match = widget.match;
    final isDraw = match.homeGoals == match.awayGoals;
    final isP1Winner = (match.homeGoals ?? 0) > (match.awayGoals ?? 0);
    final isP2Winner = (match.homeGoals ?? 0) < (match.awayGoals ?? 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha((255 * 0.05).toInt()),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${match.homeGoals ?? 0}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isP1Winner ? theme.colorScheme.primary : Colors.white,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '-',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              Text(
                '${match.awayGoals ?? 0}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isP2Winner ? theme.colorScheme.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (isDraw && !match.isBye) ...[
          const SizedBox(height: 6),
          Text(
            'DRAW',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
              letterSpacing: 1.0,
            ),
          ),
        ],
        if (widget.isRoundActive) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _editResult,
            icon: const Icon(Icons.edit_rounded, size: 12),
            label: const Text('Edit Score', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamColumn(Player team, bool isWinner, bool isLoser, ThemeData theme) {
    return Expanded(
      flex: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isLoser ? 0.5 : 1.0,
            child: TeamLogoWidget(
              logoPath: team.logoPath,
              teamName: team.teamName,
              size: 44,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            team.teamName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.w900 : FontWeight.bold,
              fontSize: 13,
              color: isWinner
                  ? theme.colorScheme.primary
                  : (isLoser ? Colors.white54 : Colors.white),
            ),
          ),
          if (team.name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '(${team.name})',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isLoser ? Colors.grey.shade600 : Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardMatchLayout(ThemeData theme) {
    final match = widget.match;
    final isP1Winner = match.isCompleted && (match.homeGoals ?? 0) > (match.awayGoals ?? 0);
    final isP2Winner = match.isCompleted && (match.homeGoals ?? 0) < (match.awayGoals ?? 0);

    return Row(
      children: [
        _buildTeamColumn(match.player1, isP1Winner, isP2Winner, theme),
        Expanded(
          flex: 4,
          child: Center(
            child: _isEditing && widget.isRoundActive
                ? _buildScoreControls(theme)
                : _buildCompletedScoreDisplay(theme),
          ),
        ),
        _buildTeamColumn(match.player2!, isP2Winner, isP1Winner, theme),
      ],
    );
  }

  Widget _buildByeMatchLayout(ThemeData theme) {
    final match = widget.match;
    return Row(
      children: [
        _buildTeamColumn(match.player1, true, false, theme),
        Expanded(
          flex: 4,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'BYE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Advances automatically',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withAlpha((255 * 0.03).toInt()),
                foregroundColor: Colors.grey.shade700,
                child: const Text('?', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Text(
                'NO OPPONENT',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final match = widget.match;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.isBye ? 'BYE MATCH' : 'MATCH #${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: match.isBye
                        ? theme.colorScheme.secondary
                        : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!match.isCompleted && !match.isBye)
                  const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange,
                      letterSpacing: 0.5,
                    ),
                  )
                else if (match.isBye)
                  Text(
                    'BYE ADVANCE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PLAYED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            match.isBye ? _buildByeMatchLayout(theme) : _buildStandardMatchLayout(theme),
          ],
        ),
      ),
    );
  }
}

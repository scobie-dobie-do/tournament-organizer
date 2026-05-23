import 'package:flutter/material.dart';
import '../storage/database_service.dart';
import '../logic/tournament_logic.dart';
import '../models/player.dart';
import 'match_list_screen.dart';
import 'leaderboard_screen.dart';
import 'create_tournament_screen.dart';
import '../widgets/team_logo_widget.dart';

class TournamentHistoryScreen extends StatefulWidget {
  const TournamentHistoryScreen({super.key});

  @override
  State<TournamentHistoryScreen> createState() => _TournamentHistoryScreenState();
}

class _TournamentHistoryScreenState extends State<TournamentHistoryScreen> {
  List<TournamentState> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = DatabaseService().getAllTournaments();
      setState(() {
        _tournaments = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load history: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
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

  void _openTournament(TournamentState state) {
    if (state.isCompleted) {
      Navigator.push(
        context,
        _createAnimatedRoute(LeaderboardScreen(tournamentState: state)),
      ).then((_) => _loadHistory());
    } else {
      Navigator.push(
        context,
        _createAnimatedRoute(MatchListScreen(tournamentState: state)),
      ).then((_) => _loadHistory());
    }
  }

  Future<void> _deleteTournament(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withAlpha((255 * 0.05).toInt()),
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
              const SizedBox(width: 10),
              const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$name" from history? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await DatabaseService().deleteTournament(id);
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament deleted successfully'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _tournaments.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _tournaments.length,
                    itemBuilder: (context, index) {
                      final tournament = _tournaments[index];
                      return _buildTournamentCard(tournament, theme);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 72,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 20),
            Text(
              'No Tournament History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your completed and ongoing offline tournaments will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  _createAnimatedRoute(const CreateTournamentScreen()),
                );
              },
              icon: const Icon(Icons.add_box_rounded, size: 20),
              label: const Text('Create New Tournament'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(TournamentState tournament, ThemeData theme) {
    final formatColor = tournament.format == TournamentFormat.knockout
        ? theme.colorScheme.primary
        : Colors.cyan;

    Player? winner;
    if (tournament.isCompleted) {
      if (tournament.format == TournamentFormat.knockout) {
        final finalRoundMatches = tournament.matches
            .where((m) => m.roundIndex == tournament.currentRoundIndex)
            .toList();
        if (finalRoundMatches.isNotEmpty && finalRoundMatches.first.winner != null) {
          winner = finalRoundMatches.first.winner;
        }
      } else {
        final leaderboard = tournament.getLeaderboard();
        if (leaderboard.isNotEmpty) {
          winner = leaderboard.first.team;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _openTournament(tournament),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Format badge, completion tag, delete button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: formatColor.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: formatColor.withAlpha((255 * 0.4).toInt())),
                    ),
                    child: Text(
                      tournament.format.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: formatColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tournament.isCompleted
                          ? Colors.green.withAlpha((255 * 0.1).toInt())
                          : Colors.orange.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tournament.isCompleted
                            ? Colors.green.withAlpha((255 * 0.4).toInt())
                            : Colors.orange.withAlpha((255 * 0.4).toInt()),
                      ),
                    ),
                    child: Text(
                      tournament.isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: tournament.isCompleted ? Colors.green : Colors.orange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: Colors.red.shade400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteTournament(tournament.id, tournament.name),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tournament Name
              Text(
                tournament.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Details: Date, number of teams, winner
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(tournament.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    '${tournament.players.length} Teams',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Winner display if completed
              if (tournament.isCompleted && winner != null) ...[
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withAlpha((255 * 0.05).toInt()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'WINNER:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TeamLogoWidget(
                      logoPath: winner.logoPath,
                      teamName: winner.teamName,
                      size: 22,
                      hasBorder: false,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        winner.name.isNotEmpty
                            ? '${winner.teamName} (${winner.name})'
                            : winner.teamName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../logic/tournament_logic.dart';
import '../widgets/leaderboard_table.dart';
import '../widgets/team_logo_widget.dart';

class StandingsScreen extends StatefulWidget {
  final TournamentState tournamentState;

  const StandingsScreen({
    super.key,
    required this.tournamentState,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> with TickerProviderStateMixin {
  late List<TeamStats> _currentStandings;
  final Map<String, int> _previousRankings = {}; // teamId -> rank (1-indexed)
  bool _isShortView = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Confetti Particle Effect State
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _confettiParticles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentStandings = widget.tournamentState.getLeaderboard();
    _saveRankings();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchText = _searchController.text.trim().toLowerCase();
        });
      }
    });

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        if (mounted) {
          setState(() {
            for (var p in _confettiParticles) {
              p.update();
            }
          });
        }
      });
  }

  void _saveRankings() {
    _previousRankings.clear();
    for (int i = 0; i < _currentStandings.length; i++) {
      _previousRankings[_currentStandings[i].team.id] = i + 1;
    }
  }

  @override
  void didUpdateWidget(StandingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStandings = widget.tournamentState.getLeaderboard();

    if (_currentStandings.isNotEmpty && newStandings.isNotEmpty) {
      final oldLeaderId = _currentStandings.first.team.id;
      final newLeaderId = newStandings.first.team.id;
      if (oldLeaderId != newLeaderId) {
        _triggerConfetti();
      }
    }

    _saveRankings();
    
    setState(() {
      _currentStandings = newStandings;
    });
  }

  void _triggerConfetti() {
    _confettiParticles.clear();
    final colors = [
      Colors.amber,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.purpleAccent
    ];
    
    for (int i = 0; i < 80; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: 0,
        y: -20 - _random.nextDouble() * 50,
        vx: (_random.nextDouble() - 0.5) * 5,
        vy: 2 + _random.nextDouble() * 4,
        color: colors[_random.nextInt(colors.length)],
        size: 6 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      ));
    }

    _confettiController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TeamStats> get _filteredStandings {
    if (_searchText.isEmpty) return _currentStandings;
    return _currentStandings
        .where((st) => st.team.teamName.toLowerCase().contains(_searchText))
        .toList();
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, idx) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.25, end: 0.75),
          duration: Duration(milliseconds: 800 + idx * 100),
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha((255 * 0.04).toInt())),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Container(width: 20, height: 14, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 12),
                    Container(width: 26, height: 26, decoration: BoxDecoration(color: Colors.grey.shade800, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Container(width: 90, height: 14, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Container(width: 24, height: 14, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 20),
                    Container(width: 28, height: 14, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const rowHeight = 48.0;
    final filtered = _filteredStandings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('League Standings'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 // 1. Visual Podium (shown only if search query is empty)
                 if (_searchText.isEmpty && _currentStandings.length >= 2)
                   Padding(
                     padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                     child: _buildVisualPodium(_currentStandings, theme),
                   ),

                 // Search Bar Widget
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                   child: TextFormField(
                     controller: _searchController,
                     style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                     decoration: InputDecoration(
                       labelText: 'Search Team...',
                       hintText: 'e.g. Tigers',
                       prefixIcon: const Icon(Icons.search_rounded, size: 20),
                       suffixIcon: _searchController.text.isNotEmpty
                           ? IconButton(
                               icon: const Icon(Icons.clear_rounded, size: 18),
                               onPressed: () {
                                 _searchController.clear();
                               },
                             )
                           : null,
                       contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                     ),
                   ),
                 ),

                 // Mode Toggle Switch
                 _buildToggleBar(theme),

                 // 2. Table Area
                 Expanded(
                   child: _currentStandings.isEmpty
                       ? _buildSkeletonLoader(theme)
                       : (filtered.isEmpty
                           ? Center(
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade600),
                                   const SizedBox(height: 12),
                                   Text(
                                     "No teams match '$_searchText'",
                                     style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                   ),
                                 ],
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
                                     child: LeaderboardTable(
                                       standings: filtered,
                                       matches: widget.tournamentState.matches,
                                       previousRankings: _previousRankings,
                                       isShortView: _isShortView,
                                       rowHeight: rowHeight,
                                     ),
                                   ),
                                 ),
                               ),
                             )),
                 ),
                const SizedBox(height: 16),
              ],
            ),

            // Confetti Overlay Layer
            if (_confettiController.isAnimating)
              IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(_confettiParticles, _random),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha((255 * 0.05).toInt()),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('SHORT VIEW', true, theme),
                _buildToggleButton('FULL STATS', false, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool value, ThemeData theme) {
    final isSelected = _isShortView == value;
    return GestureDetector(
      onTap: () {
        if (_isShortView != value) {
          setState(() {
            _isShortView = value;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.surface : Colors.grey.shade400,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.5,
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
          columnHeight: 85,
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
          columnHeight: 110,
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
            columnHeight: 70,
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
          // Trophy/Crown Icon
          if (isChampion)
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 24,
            )
          else
            const SizedBox(height: 24),
          const SizedBox(height: 4),

          // Logo Avatar with implicit scale animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
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
              );
            },
          ),
          const SizedBox(height: 6),

          // Team Name
          Text(
            teamName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
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
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 2),

          // Points
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: points, end: points),
            duration: const Duration(milliseconds: 500),
            builder: (context, val, _) {
              return Text(
                '$val pts',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // Podium column block with implicit height expansion
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            height: columnHeight,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
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
              border: Border.all(
                color: medalColor.withAlpha((255 * 0.15).toInt()),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 2,
                  child: Container(
                    color: medalColor,
                  ),
                ),
                Center(
                  child: Text(
                    positionLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: medalColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  bool initialized = false;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Random random;

  _ConfettiPainter(this.particles, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var p in particles) {
      if (!p.initialized) {
        // Initialize particle horizontal coordinate centered at top of screen
        p.x = size.width / 2 + (random.nextDouble() - 0.5) * 150;
        p.initialized = true;
      }

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      paint.color = p.color;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size / 2),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

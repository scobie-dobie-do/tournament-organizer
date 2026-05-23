import 'dart:math';
import 'package:flutter/material.dart';
import '../logic/tournament_logic.dart';
import '../logic/standings_calculator.dart';
import '../widgets/standings_row.dart';
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

  // Confetti Particle Effect State
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _confettiParticles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentStandings = widget.tournamentState.getLeaderboard();
    _saveRankings();

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

    // Check if team 1 changed (to trigger confetti)
    if (_currentStandings.isNotEmpty && newStandings.isNotEmpty) {
      final oldLeaderId = _currentStandings.first.team.id;
      final newLeaderId = newStandings.first.team.id;
      if (oldLeaderId != newLeaderId) {
        _triggerConfetti();
      }
    }

    // Save rankings from the current list before we replace it
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
    
    // Spawn 80 particles
    for (int i = 0; i < 80; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: 0, // Will be set relative to canvas width on paint
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const rowHeight = 48.0;

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
                // 1. Visual Podium (if at least 2 players exist)
                if (_currentStandings.length >= 2)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildVisualPodium(_currentStandings, theme),
                  ),

                // 2. Table Area
                Expanded(
                  child: _currentStandings.isEmpty
                      ? Center(
                          child: Text(
                            'No statistics available.',
                            style: TextStyle(color: Colors.grey.shade500),
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
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 600, // Total columns width including Form
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Header Row (Fixed)
                                        _buildHeaderRow(theme),
                                        const SizedBox(height: 4),

                                        // Scrollable Animated List of Rows via Stack
                                        SizedBox(
                                          height: _currentStandings.length * rowHeight,
                                          child: Stack(
                                            children: List.generate(_currentStandings.length, (index) {
                                              final entry = _currentStandings[index];
                                              final teamId = entry.team.id;
                                              final prevRank = _previousRankings[teamId];
                                              final formList = StandingsCalculator.calculateForm(
                                                entry.team,
                                                widget.tournamentState.matches,
                                              );

                                              return AnimatedPositioned(
                                                key: ValueKey(teamId),
                                                top: index * rowHeight,
                                                left: 0,
                                                right: 0,
                                                height: rowHeight,
                                                duration: const Duration(milliseconds: 550),
                                                curve: Curves.easeInOut,
                                                child: StandingsRow(
                                                  stats: entry,
                                                  rank: index + 1,
                                                  previousRank: prevRank,
                                                  form: formList,
                                                  isEvenRow: index.isEven,
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
          _buildHeaderCell('GF', width: 38),
          _buildHeaderCell('GA', width: 38),
          _buildHeaderCell('GD', width: 44),
          _buildHeaderCell('PTS', width: 42, isBold: true),
          _buildHeaderCell('Form', width: 90),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width, TextAlign align = TextAlign.center, bool isBold = false}) {
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

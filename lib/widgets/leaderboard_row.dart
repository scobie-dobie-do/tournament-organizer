import 'package:flutter/material.dart';
import '../logic/tournament_logic.dart';
import '../widgets/team_logo_widget.dart';

class LeaderboardRow extends StatefulWidget {
  final TeamStats stats;
  final int rank;
  final int? previousRank;
  final List<String> form;
  final bool isEvenRow;
  final bool isShortView;

  const LeaderboardRow({
    super.key,
    required this.stats,
    required this.rank,
    required this.previousRank,
    required this.form,
    required this.isEvenRow,
    required this.isShortView,
  });

  @override
  State<LeaderboardRow> createState() => _LeaderboardRowState();
}

class _LeaderboardRowState extends State<LeaderboardRow> with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _highlightAnimation = ColorTween(
      begin: theme.colorScheme.primary.withAlpha((255 * 0.35).toInt()),
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(LeaderboardRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_statsChanged(oldWidget.stats, widget.stats)) {
      _triggerHighlight();
    }
  }

  bool _statsChanged(TeamStats oldStats, TeamStats newStats) {
    return oldStats.played != newStats.played ||
        oldStats.wins != newStats.wins ||
        oldStats.draws != newStats.draws ||
        oldStats.losses != newStats.losses ||
        oldStats.goalsFor != newStats.goalsFor ||
        oldStats.goalsAgainst != newStats.goalsAgainst ||
        oldStats.points != newStats.points;
  }

  void _triggerHighlight() {
    _highlightController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Baseline background color
    final baseBgColor = widget.isEvenRow
        ? Colors.transparent
        : theme.colorScheme.surfaceContainerLow.withAlpha((255 * 0.3).toInt());

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        final highlightColor = _highlightAnimation.value;
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: highlightColor != null && highlightColor != Colors.transparent
                ? Color.alphaBlend(highlightColor, baseBgColor)
                : baseBgColor,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withAlpha((255 * 0.05).toInt()),
                width: 1.0,
              ),
            ),
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          // 1. Rank & Change Arrow (36)
          _buildRankCell(),

          // 2. Team Name & Logo (180)
          _buildTeamCell(theme),

          // 3. Core Stats (Always Visible)
          _buildAnimatedStatCell(widget.stats.played, width: 36),
          _buildAnimatedStatCell(widget.stats.wins, width: 32),
          _buildAnimatedStatCell(widget.stats.draws, width: 32),
          _buildAnimatedStatCell(widget.stats.losses, width: 32),

          // 4. Extra Stats (Animated sliding width and fading opacity)
          AnimatedCell(
            targetWidth: 38,
            isVisible: !widget.isShortView,
            child: _buildAnimatedStatCell(widget.stats.goalsFor, width: 38),
          ),
          AnimatedCell(
            targetWidth: 38,
            isVisible: !widget.isShortView,
            child: _buildAnimatedStatCell(widget.stats.goalsAgainst, width: 38),
          ),
          AnimatedCell(
            targetWidth: 44,
            isVisible: !widget.isShortView,
            child: _buildAnimatedStatCell(widget.stats.goalDifference, width: 44, isGd: true),
          ),

          // 5. Points (Always Visible)
          _buildAnimatedPointsCell(widget.stats.points, theme, width: 42),

          // 6. Form (Animated)
          AnimatedCell(
            targetWidth: 90,
            isVisible: !widget.isShortView,
            child: _buildFormCell(),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCell() {
    Widget rankIconOrText;
    if (widget.rank == 1) {
      rankIconOrText = const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16);
    } else if (widget.rank == 2) {
      rankIconOrText = Icon(Icons.workspace_premium_rounded, color: Colors.grey.shade400, size: 16);
    } else if (widget.rank == 3) {
      rankIconOrText = Icon(Icons.workspace_premium_rounded, color: Colors.brown.shade300, size: 16);
    } else {
      rankIconOrText = Text(
        '${widget.rank}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade500,
          fontSize: 12,
        ),
      );
    }

    // Rank movement arrow indicator
    Widget arrowIndicator = const SizedBox(width: 8);
    if (widget.previousRank != null) {
      if (widget.previousRank! > widget.rank) {
        arrowIndicator = const Icon(
          Icons.arrow_drop_up_rounded,
          color: Colors.greenAccent,
          size: 16,
        );
      } else if (widget.previousRank! < widget.rank) {
        arrowIndicator = const Icon(
          Icons.arrow_drop_down_rounded,
          color: Colors.redAccent,
          size: 16,
        );
      }
    }

    return SizedBox(
      width: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          rankIconOrText,
          arrowIndicator,
        ],
      ),
    );
  }

  Widget _buildTeamCell(ThemeData theme) {
    return SizedBox(
      width: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children: [
            TeamLogoWidget(
              logoPath: widget.stats.team.logoPath,
              teamName: widget.stats.team.teamName,
              size: 26,
              hasBorder: false,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.stats.team.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.stats.team.name.isNotEmpty)
                    Text(
                      widget.stats.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCell(int targetVal, {required double width, bool isGd = false}) {
    return SizedBox(
      width: width,
      child: Center(
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: targetVal, end: targetVal),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (context, animatedVal, _) {
            String text = '$animatedVal';
            Color textColor = Colors.white70;

            if (isGd) {
              if (animatedVal > 0) {
                textColor = Colors.greenAccent.shade400;
                text = '+$animatedVal';
              } else if (animatedVal < 0) {
                textColor = Colors.redAccent.shade400;
              } else {
                textColor = Colors.grey.shade500;
              }
            }

            return Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isGd ? FontWeight.w600 : FontWeight.normal,
                color: textColor,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedPointsCell(int targetPoints, ThemeData theme, {required double width}) {
    final isFirst = widget.rank == 1;
    return SizedBox(
      width: width,
      child: Center(
        child: TweenAnimationBuilder<int>(
          tween: IntTween(begin: targetPoints, end: targetPoints),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (context, animatedPoints, _) {
            return Text(
              '$animatedPoints',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isFirst ? Colors.amber : theme.colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCell() {
    return SizedBox(
      width: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.form.map((result) {
          Color circleColor;
          Color textColor = Colors.white;
          String letter;

          switch (result) {
            case 'W':
              circleColor = Colors.green.shade700;
              letter = 'W';
              break;
            case 'L':
              circleColor = Colors.red.shade700;
              letter = 'L';
              break;
            case 'D':
            default:
              circleColor = Colors.grey.shade700;
              letter = 'D';
              break;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A cell that animates its width smoothly from 0 to targetWidth,
/// and clips and fades out its content.
class AnimatedCell extends StatelessWidget {
  final double targetWidth;
  final bool isVisible;
  final Widget child;
  final Duration duration;
  final double height;

  const AnimatedCell({
    super.key,
    required this.targetWidth,
    required this.isVisible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOut,
      width: isVisible ? targetWidth : 0.0,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: AnimatedOpacity(
        duration: duration,
        opacity: isVisible ? 1.0 : 0.0,
        curve: Curves.easeInOut,
        child: OverflowBox(
          minWidth: 0.0,
          maxWidth: targetWidth,
          minHeight: 0.0,
          maxHeight: height,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: targetWidth,
            height: height,
            child: child,
          ),
        ),
      ),
    );
  }
}

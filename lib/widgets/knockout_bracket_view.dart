import 'dart:math';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import 'team_logo_widget.dart';

class VirtualMatchNode {
  final int roundIndex; // 1-indexed
  final int matchIndex; // 0-indexed
  final VirtualMatchNode? parent1;
  final VirtualMatchNode? parent2;
  double centerY = 0.0;

  VirtualMatchNode({
    required this.roundIndex,
    required this.matchIndex,
    this.parent1,
    this.parent2,
  });
}

class KnockoutBracketView extends StatelessWidget {
  final TournamentState tournamentState;
  final Function(TournamentMatch) onMatchTap;

  const KnockoutBracketView({
    super.key,
    required this.tournamentState,
    required this.onMatchTap,
  });

  // ─── Build Virtual Nodes Tree ─────────────────────────────────────────────
  List<List<VirtualMatchNode>> _buildVirtualBracket(int teamCount) {
    List<List<VirtualMatchNode>> rounds = [];

    // Round 1
    List<VirtualMatchNode> round1 = [];
    int round1Size = teamCount ~/ 2;
    for (int i = 0; i < round1Size; i++) {
      round1.add(VirtualMatchNode(roundIndex: 1, matchIndex: i));
    }
    rounds.add(round1);

    // Subsequent rounds
    List<VirtualMatchNode> prevRoundActive = List.from(round1);
    int roundIdx = 2;
    while (prevRoundActive.length > 1) {
      List<VirtualMatchNode> currentRound = [];
      List<VirtualMatchNode> nextRoundActive = [];
      int matchIdx = 0;

      for (int i = 0; i < prevRoundActive.length; i += 2) {
        if (i + 1 < prevRoundActive.length) {
          final node = VirtualMatchNode(
            roundIndex: roundIdx,
            matchIndex: matchIdx,
            parent1: prevRoundActive[i],
            parent2: prevRoundActive[i + 1],
          );
          currentRound.add(node);
          nextRoundActive.add(node);
          matchIdx++;
        } else {
          // Carry over odd node
          nextRoundActive.add(prevRoundActive[i]);
        }
      }
      rounds.add(currentRound);
      prevRoundActive = nextRoundActive;
      roundIdx++;
    }

    return rounds;
  }

  // ─── Calculate Heights and Center Coordinates ─────────────────────────────
  void _calculateCoordinates(List<List<VirtualMatchNode>> rounds, double cardHeight, double cardGap) {
    for (int r = 0; r < rounds.length; r++) {
      final roundNodes = rounds[r];
      for (var node in roundNodes) {
        if (node.roundIndex == 1) {
          node.centerY = node.matchIndex * (cardHeight + cardGap) + cardHeight / 2;
        } else {
          if (node.parent1 != null && node.parent2 != null) {
            node.centerY = (node.parent1!.centerY + node.parent2!.centerY) / 2;
          } else {
            node.centerY = node.matchIndex * (cardHeight + cardGap) + cardHeight / 2;
          }
        }
      }
    }
  }

  // ─── Resolve team name & logo for placeholder cards ───────────────────────
  _ResolvedTeam _resolveTeam(VirtualMatchNode? parentNode, List<TournamentMatch> allMatches) {
    if (parentNode == null) {
      return _ResolvedTeam(teamName: 'TBD', isTbd: true);
    }

    final parentMatches = allMatches.where((m) => m.roundIndex == parentNode.roundIndex).toList();
    if (parentNode.matchIndex < parentMatches.length) {
      final actualMatch = parentMatches[parentNode.matchIndex];
      if (actualMatch.isCompleted && actualMatch.winner != null) {
        return _ResolvedTeam(
          teamName: actualMatch.winner!.teamName,
          logoPath: actualMatch.winner!.logoPath,
          player: actualMatch.winner,
        );
      } else {
        return _ResolvedTeam(
          teamName: 'Winner of M${parentNode.matchIndex + 1}',
          isTbd: true,
        );
      }
    } else {
      String label = 'Winner of R${parentNode.roundIndex} M${parentNode.matchIndex + 1}';
      if (parentNode.roundIndex == 1) {
        label = 'Winner of M${parentNode.matchIndex + 1}';
      }
      return _ResolvedTeam(teamName: label, isTbd: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dimension Constants
    const cardWidth = 190.0;
    const cardHeight = 96.0;
    const cardGap = 32.0;
    const columnWidth = 250.0;
    const colPaddingLeft = (columnWidth - cardWidth) / 2; // 30.0

    final virtualRounds = _buildVirtualBracket(tournamentState.players.length);
    _calculateCoordinates(virtualRounds, cardHeight, cardGap);

    // Calculate maximum width and height occupied by the bracket
    double totalHeight = 0.0;
    for (var round in virtualRounds) {
      for (var node in round) {
        totalHeight = max(totalHeight, node.centerY + cardHeight / 2);
      }
    }
    totalHeight += 24.0; // padding at the bottom
    final totalWidth = virtualRounds.length * columnWidth;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              children: [
                // 1. Connection lines layer
                CustomPaint(
                  size: Size(totalWidth, totalHeight),
                  painter: _BracketLinesPainter(
                    virtualRounds: virtualRounds,
                    columnWidth: columnWidth,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    colPaddingLeft: colPaddingLeft,
                    lineColor: theme.colorScheme.primary,
                  ),
                ),

                // 2. Interactive Match Cards layer
                ...List.generate(virtualRounds.length, (colIdx) {
                  final roundNodes = virtualRounds[colIdx];
                  final roundIndex = colIdx + 1;
                  final actualRoundMatches = tournamentState.matches
                      .where((m) => m.roundIndex == roundIndex)
                      .toList();

                  return Positioned(
                    left: colIdx * columnWidth,
                    top: 0,
                    bottom: 0,
                    width: columnWidth,
                    child: Stack(
                      children: roundNodes.map((node) {
                        final bool hasMatch = node.matchIndex < actualRoundMatches.length;
                        final TournamentMatch? actualMatch =
                            hasMatch ? actualRoundMatches[node.matchIndex] : null;

                        return Positioned(
                          left: colPaddingLeft,
                          top: node.centerY - cardHeight / 2,
                          width: cardWidth,
                          height: cardHeight,
                          child: _buildMatchCard(
                            context: context,
                            theme: theme,
                            node: node,
                            actualMatch: actualMatch,
                            roundIndex: roundIndex,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Match Card Builder ───────────────────────────────────────────────────
  Widget _buildMatchCard({
    required BuildContext context,
    required ThemeData theme,
    required VirtualMatchNode node,
    required TournamentMatch? actualMatch,
    required int roundIndex,
  }) {
    final bool isPlayable = actualMatch != null;
    final bool isActiveRound = roundIndex == tournamentState.currentRoundIndex;

    // Resolve teams and scores
    final _ResolvedTeam team1;
    final _ResolvedTeam team2;
    final String score1;
    final String score2;
    final bool isCompleted = actualMatch?.isCompleted ?? false;
    final Player? winner = actualMatch?.winner;

    if (actualMatch != null) {
      team1 = _ResolvedTeam(
        teamName: actualMatch.player1.teamName,
        logoPath: actualMatch.player1.logoPath,
        player: actualMatch.player1,
      );
      team2 = _ResolvedTeam(
        teamName: actualMatch.player2?.teamName ?? 'TBD',
        logoPath: actualMatch.player2?.logoPath,
        player: actualMatch.player2,
        isTbd: actualMatch.player2 == null,
      );
      score1 = isCompleted ? '${actualMatch.homeGoals ?? 0}' : '';
      score2 = isCompleted ? '${actualMatch.awayGoals ?? 0}' : '';
    } else {
      // Future placeholder card
      team1 = _resolveTeam(node.parent1, tournamentState.matches);
      team2 = _resolveTeam(node.parent2, tournamentState.matches);
      score1 = '';
      score2 = '';
    }

    final isT1Winner = isCompleted && winner != null && winner.id == team1.player?.id;
    final isT2Winner = isCompleted && winner != null && winner.id == team2.player?.id;

    final border = Border.all(
      color: isActiveRound
          ? theme.colorScheme.primary.withOpacity(0.5)
          : Colors.white.withOpacity(0.06),
      width: isActiveRound ? 1.5 : 1.0,
    );

    final glowShadow = isActiveRound
        ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ]
        : null;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isPlayable ? () => onMatchTap(actualMatch) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: glowShadow,
          ),
          child: Column(
            children: [
              // Team 1 Row
              Expanded(
                child: _buildTeamRow(
                  theme: theme,
                  resolvedTeam: team1,
                  score: score1,
                  isWinner: isT1Winner,
                  isLoser: isCompleted && !isT1Winner,
                ),
              ),
              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.04),
              ),
              // Team 2 Row
              Expanded(
                child: _buildTeamRow(
                  theme: theme,
                  resolvedTeam: team2,
                  score: score2,
                  isWinner: isT2Winner,
                  isLoser: isCompleted && !isT2Winner,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow({
    required ThemeData theme,
    required _ResolvedTeam resolvedTeam,
    required String score,
    required bool isWinner,
    required bool isLoser,
  }) {
    return Opacity(
      opacity: isLoser ? 0.45 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            // Logo
            if (resolvedTeam.isTbd)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              TeamLogoWidget(
                logoPath: resolvedTeam.logoPath,
                teamName: resolvedTeam.teamName,
                size: 22,
                hasBorder: false,
              ),
            const SizedBox(width: 8),

            // Team Name
            Expanded(
              child: Text(
                resolvedTeam.teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isWinner ? FontWeight.w900 : FontWeight.bold,
                  color: resolvedTeam.isTbd
                      ? Colors.grey.shade500
                      : (isWinner ? theme.colorScheme.primary : Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Score
            if (score.isNotEmpty)
              Text(
                score,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isWinner ? theme.colorScheme.primary : Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedTeam {
  final String teamName;
  final String? logoPath;
  final bool isTbd;
  final Player? player;

  _ResolvedTeam({
    required this.teamName,
    this.logoPath,
    this.isTbd = false,
    this.player,
  });
}

// ─── Orthogonal Connection Lines Painter ────────────────────────────────────
class _BracketLinesPainter extends CustomPainter {
  final List<List<VirtualMatchNode>> virtualRounds;
  final double columnWidth;
  final double cardWidth;
  final double cardHeight;
  final double colPaddingLeft;
  final Color lineColor;

  _BracketLinesPainter({
    required this.virtualRounds,
    required this.columnWidth,
    required this.cardWidth,
    required this.cardHeight,
    required this.colPaddingLeft,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stepOffset = 18.0;

    for (int r = 1; r < virtualRounds.length; r++) {
      final roundNodes = virtualRounds[r];
      for (var node in roundNodes) {
        final xChild = r * columnWidth + colPaddingLeft;
        final yChild = node.centerY;

        if (node.parent1 != null) {
          final parent1 = node.parent1!;
          final xParent1 = (parent1.roundIndex - 1) * columnWidth + colPaddingLeft + cardWidth;
          final yParent1 = parent1.centerY;
          _drawStepLine(canvas, xParent1, yParent1, xChild, yChild, stepOffset, paint);
        }

        if (node.parent2 != null) {
          final parent2 = node.parent2!;
          final xParent2 = (parent2.roundIndex - 1) * columnWidth + colPaddingLeft + cardWidth;
          final yParent2 = parent2.centerY;
          _drawStepLine(canvas, xParent2, yParent2, xChild, yChild, stepOffset, paint);
        }
      }
    }
  }

  void _drawStepLine(Canvas canvas, double x1, double y1, double x2, double y2, double step, Paint paint) {
    final path = Path();
    path.moveTo(x1, y1);

    final midX = x1 + step;
    path.lineTo(midX, y1);
    path.lineTo(midX, y2);
    path.lineTo(x2, y2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

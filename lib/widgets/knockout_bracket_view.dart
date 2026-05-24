import 'dart:math';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../logic/tournament_logic.dart';
import '../logic/knockout_engine.dart';
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

    // A matchup in the parent node can consist of multiple legs
    final parentGroupId = 'ko_${parentNode.roundIndex}_${parentNode.matchIndex}';
    final parentMatches = allMatches.where((m) => m.roundIndex == parentNode.roundIndex && m.aggregateGroupId == parentGroupId).toList();
    
    // Fallback if legacy match
    final legacyMatches = parentMatches.isEmpty 
        ? allMatches.where((m) => m.roundIndex == parentNode.roundIndex).toList()
        : parentMatches;

    if (parentMatches.isNotEmpty || (parentNode.matchIndex < legacyMatches.length)) {
      final matchesGroup = parentMatches.isNotEmpty ? parentMatches : [legacyMatches[parentNode.matchIndex]];
      final isCompleted = matchesGroup.every((m) => m.isCompleted);
      final winner = KnockoutEngine.getWinnerOfMatchup(matchesGroup, tournamentState.awayGoalsRule);

      if (isCompleted && winner != null) {
        return _ResolvedTeam(
          teamName: winner.teamName,
          logoPath: winner.logoPath,
          player: winner,
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
    const cardWidth = 230.0;
    const cardHeight = 100.0;
    const cardGap = 36.0;
    const columnWidth = 290.0;
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

    if (tournamentState.hasThirdPlaceMatch) {
      totalHeight += cardHeight + 40.0;
    }
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

                  return Positioned(
                    left: colIdx * columnWidth,
                    top: 0,
                    bottom: 0,
                    width: columnWidth,
                    child: Stack(
                      children: [
                        ...roundNodes.map((node) {
                          final matchupId = 'ko_${roundIndex}_${node.matchIndex}';
                          final matchupMatches = tournamentState.matches
                              .where((m) => m.roundIndex == roundIndex && m.aggregateGroupId == matchupId && !m.isThirdPlace)
                              .toList();

                          // Fallback to legacy single index if aggregateGroupId matches are empty
                          final bool isLegacy = matchupMatches.isEmpty;
                          final legacyRoundMatches = tournamentState.matches
                              .where((m) => m.roundIndex == roundIndex && !m.isThirdPlace)
                              .toList();
                          final TournamentMatch? legacyMatch = (!isLegacy || node.matchIndex >= legacyRoundMatches.length)
                              ? null
                              : legacyRoundMatches[node.matchIndex];

                          final List<TournamentMatch> actualMatchup = isLegacy
                              ? (legacyMatch != null ? [legacyMatch] : [])
                              : matchupMatches;

                          return Positioned(
                            left: colPaddingLeft,
                            top: node.centerY - cardHeight / 2,
                            width: cardWidth,
                            height: cardHeight,
                            child: _buildMatchCard(
                              context: context,
                              theme: theme,
                              node: node,
                              matchupMatches: actualMatchup,
                              roundIndex: roundIndex,
                            ),
                          );
                        }),

                        // Render Third Place Match card under the Final card
                        if (roundIndex == virtualRounds.length && tournamentState.hasThirdPlaceMatch) ...[
                          (() {
                            final finalNode = roundNodes.first;
                            final tpMatches = tournamentState.matches
                                .where((m) => m.roundIndex == roundIndex && m.isThirdPlace)
                                .toList();

                            return Positioned(
                              left: colPaddingLeft,
                              top: finalNode.centerY + cardHeight / 2 + 28,
                              width: cardWidth,
                              height: cardHeight + 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha((255 * 0.12).toInt()),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                    child: const Text(
                                      'THIRD PLACE MATCH',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.orange,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildMatchCard(
                                      context: context,
                                      theme: theme,
                                      node: VirtualMatchNode(roundIndex: roundIndex, matchIndex: -1),
                                      matchupMatches: tpMatches,
                                      roundIndex: roundIndex,
                                      isTPCard: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }())
                        ]
                      ],
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
    required List<TournamentMatch> matchupMatches,
    required int roundIndex,
    bool isTPCard = false,
  }) {
    final bool isPlayable = matchupMatches.isNotEmpty;
    final bool isActiveRound = roundIndex == tournamentState.currentRoundIndex;

    // Resolve teams and scores
    final _ResolvedTeam team1;
    final _ResolvedTeam team2;

    int? t1Leg1, t1Leg2, t1Agg, t1Pens;
    int? t2Leg1, t2Leg2, t2Agg, t2Pens;

    final bool isCompleted = isPlayable && matchupMatches.every((m) => m.isCompleted);
    final Player? winner = isPlayable
        ? KnockoutEngine.getWinnerOfMatchup(matchupMatches, tournamentState.awayGoalsRule)
        : null;

    if (isPlayable) {
      final m1 = matchupMatches.firstWhere((m) => m.legNumber == 1, orElse: () => matchupMatches.first);
      final m2 = matchupMatches.firstWhere((m) => m.legNumber == 2, orElse: () => m1);
      final p1 = m1.player1;
      final p2 = m1.player2;

      team1 = _ResolvedTeam(
        teamName: p1.teamName,
        logoPath: p1.logoPath,
        player: p1,
      );

      team2 = _ResolvedTeam(
        teamName: p2?.teamName ?? 'TBD',
        logoPath: p2?.logoPath,
        player: p2,
        isTbd: p2 == null,
      );

      if (p2 != null) {
        // Calculate scores dynamically based on team positions
        t1Leg1 = m1.player1.id == p1.id ? m1.homeGoals : m1.awayGoals;
        t2Leg1 = m1.player2?.id == p2.id ? m1.awayGoals : m1.homeGoals;

        if (matchupMatches.length > 1) {
          t1Leg2 = m2.player1.id == p1.id ? m2.homeGoals : m2.awayGoals;
          t2Leg2 = m2.player2?.id == p2.id ? m2.awayGoals : m2.homeGoals;

          if (t1Leg1 != null && t1Leg2 != null) {
            t1Agg = t1Leg1 + t1Leg2;
          }
          if (t2Leg1 != null && t2Leg2 != null) {
            t2Agg = t2Leg1 + t2Leg2;
          }

          // Penalties
          final lastLeg = matchupMatches.reduce((curr, next) => curr.legNumber > next.legNumber ? curr : next);
          if (lastLeg.isCompleted && lastLeg.homePenalties != null && lastLeg.awayPenalties != null) {
            t1Pens = lastLeg.player1.id == p1.id ? lastLeg.homePenalties : lastLeg.awayPenalties;
            t2Pens = lastLeg.player2?.id == p2.id ? lastLeg.awayPenalties : lastLeg.homePenalties;
          }
        } else {
          t1Agg = m1.homeGoals;
          t2Agg = m1.awayGoals;
          if (m1.isCompleted && m1.homePenalties != null && m1.awayPenalties != null) {
            t1Pens = m1.homePenalties;
            t2Pens = m1.awayPenalties;
          }
        }
      }
    } else {
      // Future placeholder card
      team1 = _resolveTeam(node.parent1, tournamentState.matches);
      team2 = _resolveTeam(node.parent2, tournamentState.matches);
    }

    final isT1Winner = isCompleted && winner != null && winner.id == team1.player?.id;
    final isT2Winner = isCompleted && winner != null && winner.id == team2.player?.id;

    final border = Border.all(
      color: isActiveRound
          ? theme.colorScheme.primary.withAlpha((255 * 0.8).toInt())
          : Colors.white.withAlpha((255 * 0.08).toInt()),
      width: isActiveRound ? 1.8 : 1.0,
    );

    final glowShadow = isActiveRound
        ? [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha((255 * 0.15).toInt()),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ]
        : null;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isPlayable
            ? () {
                // Tapping any leg match in the matchup list triggers detail screen
                // In bracket view, we trigger the first leg or the currently active leg match
                final activeMatch = matchupMatches.firstWhere((m) => !m.isCompleted, orElse: () => matchupMatches.first);
                onMatchTap(activeMatch);
              }
            : null,
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
                  leg1Score: t1Leg1,
                  leg2Score: t1Leg2,
                  aggScore: t1Agg,
                  pens: t1Pens,
                  isWinner: isT1Winner,
                  isLoser: isCompleted && !isT1Winner,
                  showLegs: matchupMatches.length > 1,
                  isCompleted: isCompleted,
                ),
              ),
              // Divider
              Container(
                height: 1,
                color: Colors.white.withAlpha((255 * 0.05).toInt()),
              ),
              // Team 2 Row
              Expanded(
                child: _buildTeamRow(
                  theme: theme,
                  resolvedTeam: team2,
                  leg1Score: t2Leg1,
                  leg2Score: t2Leg2,
                  aggScore: t2Agg,
                  pens: t2Pens,
                  isWinner: isT2Winner,
                  isLoser: isCompleted && !isT2Winner,
                  showLegs: matchupMatches.length > 1,
                  isCompleted: isCompleted,
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
    required int? leg1Score,
    required int? leg2Score,
    required int? aggScore,
    required int? pens,
    required bool isWinner,
    required bool isLoser,
    required bool showLegs,
    required bool isCompleted,
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
                  color: Colors.white.withAlpha((255 * 0.04).toInt()),
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

            // Legs and Agg score details
            if (isCompleted || aggScore != null) ...[
              if (showLegs) ...[
                if (leg1Score != null)
                  Container(
                    width: 20,
                    alignment: Alignment.center,
                    child: Text(
                      '$leg1Score',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (leg2Score != null)
                  Container(
                    width: 20,
                    alignment: Alignment.center,
                    child: Text(
                      '$leg2Score',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              
              // Aggregate / Main Score
              if (aggScore != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$aggScore',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isWinner ? theme.colorScheme.primary : Colors.white,
                      ),
                    ),
                    if (pens != null)
                      Text(
                        ' ($pens)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isWinner ? theme.colorScheme.primary : Colors.orangeAccent,
                        ),
                      ),
                  ],
                ),
            ],
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
      ..color = lineColor.withAlpha((255 * 0.2).toInt())
      ..strokeWidth = 1.8
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

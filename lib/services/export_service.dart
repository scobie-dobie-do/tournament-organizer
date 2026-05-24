import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../logic/tournament_logic.dart';
import '../models/match.dart';

class ExportService {
  /// Shares a text-based standings report.
  static Future<void> shareStandingsText(TournamentState state) async {
    final buffer = StringBuffer();
    buffer.writeln('🏆 TOURNAMENT SUMMARY: ${state.name.toUpperCase()} 🏆');
    buffer.writeln('Format: ${state.format.displayName}');
    buffer.writeln('Status: ${state.isCompleted ? "Completed" : "In Progress"}');
    buffer.writeln('----------------------------------------');

    if (state.format == TournamentFormat.roundRobin) {
      buffer.writeln('STANDINGS TABLE:');
      final standings = state.getLeaderboard();
      for (int i = 0; i < standings.length; i++) {
        final st = standings[i];
        buffer.writeln(
          '#${i + 1} ${st.team.teamName} - ${st.points} pts | MP: ${st.played} | W: ${st.wins} D: ${st.draws} L: ${st.losses} | GD: ${st.goalDifference > 0 ? "+" : ""}${st.goalDifference}',
        );
      }
    } else {
      buffer.writeln('TOURNAMENT BRACKET RESULTS:');
      for (int r = 1; r <= state.currentRoundIndex; r++) {
        buffer.writeln('\n--- ROUND $r ---');
        final roundMatches = state.matches.where((m) => m.roundIndex == r).toList();
        for (var m in roundMatches) {
          if (m.isBye) {
            buffer.writeln('${m.player1.teamName} [BYE]');
          } else {
            final scoreStr = m.isCompleted
                ? '${m.homeGoals}-${m.awayGoals}${m.isPenalties ? " (pens ${m.homePenalties}-${m.awayPenalties})" : ""}'
                : 'vs';
            buffer.writeln(
              '${m.player1.teamName} $scoreStr ${m.player2?.teamName ?? "TBD"} (Leg ${m.legNumber}/${m.totalLegs})',
            );
          }
        }
      }
    }

    buffer.writeln('\nGenerated via Tournament Organizer App.');
    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: '${state.name} Report',
      ),
    );
  }

  /// Generates and prints a PDF tournament report.
  static Future<void> printTournamentPdf(TournamentState state) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    state.name.toUpperCase(),
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'TOURNAMENT REPORT',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            ),

            // Metadata info
            pw.Paragraph(
              text: 'Format: ${state.format.displayName} | Legs: ${state.legs} | '
                  'Status: ${state.isCompleted ? "Completed" : "In Progress"} | '
                  'Created: ${state.createdAt.toString().split(".")[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),

            // Standings Section (If Round Robin)
            if (state.format == TournamentFormat.roundRobin) ...[
              pw.Text('LEAGUE STANDINGS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildStandingsPdfTable(state),
              pw.SizedBox(height: 20),
            ],

            // Matches section
            pw.Text('MATCH LIST & FIXTURES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ..._buildMatchesPdfList(state),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${state.name}_Report.pdf',
    );
  }

  static pw.Widget _buildStandingsPdfTable(TournamentState state) {
    final standings = state.getLeaderboard();

    final headers = ['#', 'Team', 'MP', 'W', 'D', 'L', 'GF', 'GA', 'GD', 'PTS'];
    final data = List.generate(standings.length, (idx) {
      final st = standings[idx];
      return [
        '${idx + 1}',
        st.team.teamName,
        '${st.played}',
        '${st.wins}',
        '${st.draws}',
        '${st.losses}',
        '${st.goalsFor}',
        '${st.goalsAgainst}',
        '${st.goalDifference > 0 ? "+" : ""}${st.goalDifference}',
        '${st.points}',
      ];
    });

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
        bottom: pw.BorderSide(width: 1, color: PdfColors.grey700),
        top: pw.BorderSide(width: 1, color: PdfColors.grey700),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {1: pw.Alignment.centerLeft},
    );
  }

  static List<pw.Widget> _buildMatchesPdfList(TournamentState state) {
    final List<pw.Widget> children = [];

    // Group matches by round or leg
    if (state.format == TournamentFormat.roundRobin) {
      // Group by Leg
      final Map<int, List<TournamentMatch>> groupedByLeg = {};
      for (var m in state.matches) {
        groupedByLeg.putIfAbsent(m.legNumber, () => []).add(m);
      }

      for (var legEntry in groupedByLeg.entries) {
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text('Leg ${legEntry.key}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
        );

        for (var m in legEntry.value) {
          final scoreStr = m.isCompleted ? '${m.homeGoals}-${m.awayGoals}' : 'vs';
          children.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Round ${m.roundIndex}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Expanded(
                    child: pw.Text(
                      '  ${m.player1.teamName} $scoreStr ${m.player2?.teamName ?? "BYE"}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: m.isCompleted ? pw.FontWeight.bold : pw.FontWeight.normal),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } else {
      // Knockout format
      for (int r = 1; r <= state.currentRoundIndex; r++) {
        final roundMatches = state.matches.where((m) => m.roundIndex == r).toList();
        if (roundMatches.isEmpty) continue;

        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text('Round $r', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
        );

        for (var m in roundMatches) {
          final scoreStr = m.isCompleted
              ? '${m.homeGoals}-${m.awayGoals}${m.isPenalties ? " (pens ${m.homePenalties}-${m.awayPenalties})" : ""}'
              : 'vs';
          children.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Leg ${m.legNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Expanded(
                    child: pw.Text(
                      '  ${m.player1.teamName} $scoreStr ${m.player2?.teamName ?? "TBD"}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: m.isCompleted ? pw.FontWeight.bold : pw.FontWeight.normal),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return children;
  }
}

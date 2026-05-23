// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:tournament_organizer/main.dart';

void main() {
  testWidgets('Tournament Organizer smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TournamentOrganizerApp());

    // Verify that our splash screen loads and shows the title.
    expect(find.text('TOURNAMENT ORGANIZER'), findsOneWidget);

    // Settle all timers by advancing the virtual clock
    await tester.pump(const Duration(seconds: 3));
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:edutrack_phs/main.dart';

void main() {
  testWidgets('login navigates to the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('EduTrack PHS'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('School ID or Email'),
      'john@phs.edu',
    );
    await tester.enterText(find.bySemanticsLabel('Password'), 'password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, John Rexter'), findsOneWidget);
    expect(find.text('Active Borrowings'), findsOneWidget);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edutrack_phs/main.dart';
import 'package:edutrack_phs/models/account_role.dart';
import 'package:edutrack_phs/screens/dashboard_screen.dart';

void main() {
  testWidgets('login navigates to the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Access Portal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('School ID / Email'),
      'john@phs.edu',
    );
    await tester.enterText(find.bySemanticsLabel('Password'), 'password');
    await tester.tap(find.text('Login with EduTrack PHS'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, John Rexter'), findsOneWidget);
    expect(find.text('My Borrowed Resources'), findsOneWidget);
  });

  testWidgets('property custodian dashboard shows management metrics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const DashboardScreen(role: AccountRole.propertyCustodian),
      ),
    );

    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text('Learning Resources'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    expect(find.text('QR Codes'), findsNothing);
    expect(find.text('User Management'), findsNothing);
    expect(find.text('System Logs'), findsNothing);
  });
}

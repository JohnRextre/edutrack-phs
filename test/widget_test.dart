// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edutrack_phs/models/account_role.dart';
import 'package:edutrack_phs/screens/common/dashboard_screen.dart';
import 'package:edutrack_phs/screens/common/homepage_screen.dart';

void main() {
  testWidgets('homepage remains visible in a 980px desktop viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(980, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomepageScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Every resource'), findsOneWidget);
  });

  testWidgets('homepage remains visible at laptop and desktop widths', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(1366, 768), Size(1920, 1080)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: HomepageScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Every resource'), findsOneWidget);
    }
  });

  testWidgets('homepage opens the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const HomepageScreen(),
          '/home': (_) => const HomepageScreen(),
          '/login': (_) => const Scaffold(body: Text('Sign in')),
        },
        initialRoute: '/home',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open workspace'), findsOneWidget);
    await tester.tap(find.text('Open workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
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
    expect(find.text('User Management'), findsNothing);
    expect(find.text('System Logs'), findsNothing);
  });
}

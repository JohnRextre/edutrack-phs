import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/return_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTrack PHS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B87),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/resources': (context) => const ResourcesScreen(),
        '/return': (context) => const ReturnScreen(),
      },
    );
  }
}

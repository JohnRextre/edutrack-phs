import 'package:flutter/material.dart';

import 'models/account_role.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/admin_system_logs_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/custodian_borrow_requests_screen.dart';
import 'screens/custodian_reports_screen.dart';
import 'screens/custodian_resources_screen.dart';
import 'screens/custodian_return_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/my_borrowings_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/resources_screen.dart';

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
      initialRoute: '/home',
      routes: {
        '/': (context) => const HomepageScreen(),
        '/home': (context) => const HomepageScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) {
          return DashboardScreen(
            role: _roleFromArguments(
              ModalRoute.of(context)?.settings.arguments,
            ),
          );
        },
        '/resources': (context) => const ResourcesScreen(),
        '/return': (context) => const MyBorrowingsScreen(),
        '/my-borrowings': (context) => const MyBorrowingsScreen(),
        '/my-requests': (context) => const MyRequestsScreen(),
        '/activity': (context) => const ActivityScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/custodian-resources': (context) => const CustodianResourcesScreen(),
        '/custodian-borrow-requests': (context) =>
            const CustodianBorrowRequestsScreen(),
        '/custodian-return-verification': (context) =>
            const CustodianReturnVerificationScreen(),
        '/custodian-reports': (context) => const CustodianReportsScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-users': (context) => const AdminUserManagementScreen(),
        '/admin-logs': (context) => const AdminSystemLogsScreen(),
      },
    );
  }
}

AccountRole _roleFromArguments(Object? value) {
  final roleName = value is String ? value : value?.toString().split('.').last;
  return AccountRole.values.firstWhere(
    (role) => role.name == roleName,
    orElse: () => AccountRole.student,
  );
}

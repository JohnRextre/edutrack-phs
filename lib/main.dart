import 'package:flutter/material.dart';

import 'models/account_role.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/account_activities_screen.dart';
import 'screens/admin_system_logs_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/custodian_borrow_requests_screen.dart';
import 'screens/custodian/reports_analytics_screen.dart';
import 'screens/custodian/learning_resources_screen.dart';
import 'screens/custodian_return_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/homepage_screen.dart';
import 'screens/initial_admin_setup_screen.dart';
import 'screens/my_borrowings_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/resources_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/register': (context) => const RegisterScreen(),
        '/initial-admin-setup': (context) => const InitialAdminSetupScreen(),
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
        '/my-requests': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialTab = args is int ? args : 0;
          return MyRequestsScreen(initialTabIndex: initialTab);
        },
        '/activity': (context) => const AccountActivitiesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/custodian-resources': (context) => const LearningResourcesScreen(),
        '/custodian-borrow-requests': (context) =>
            const CustodianBorrowRequestsScreen(),
        '/custodian-return-verification': (context) =>
            const CustodianReturnVerificationScreen(),
        '/custodian-reports': (context) => const ReportsAnalyticsScreen(),
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

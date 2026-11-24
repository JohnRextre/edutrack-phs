import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/account_role.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/common/account_activities_screen.dart';
import 'screens/admin/admin_system_logs_screen.dart';
import 'screens/admin/admin_user_management_screen.dart';
import 'screens/admin/admin_sections_screen.dart';
import 'screens/admin/admin_resource_monitoring_screen.dart';
import 'screens/admin/admin_borrowing_monitor_screen.dart';
import 'screens/admin/admin_reports_screen.dart';
import 'screens/custodian/custodian_borrowed_inventory_screen.dart';
import 'screens/custodian/reports_analytics_screen.dart';
import 'screens/custodian/learning_resources_screen.dart';
import 'screens/custodian/custodian_return_verification_screen.dart';
import 'screens/common/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/common/homepage_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/initial_admin_setup_screen.dart';
import 'screens/borrower/my_borrowings_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/borrower/resources_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  try {
    await AuthService.initialize();
  } catch (error) {
    startupError = error;
  }
  runApp(MyApp(startupError: startupError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B87)),
        ),
        home: _StartupErrorScreen(error: startupError!),
      );
    }
    return MaterialApp(
      title: 'EduTrack PHS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B87),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF176B87), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/': (context) => const HomepageScreen(),
        '/home': (context) => const HomepageScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verify-email': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final role = _roleFromArguments(args);
          return EmailVerificationScreen(role: role);
        },
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
        '/my-borrowings': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialTab = args is int ? args : 0;
          return MyBorrowingsScreen(initialTabIndex: initialTab);
        },
        '/activity': (context) => const AccountActivitiesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/custodian-resources': (context) => const LearningResourcesScreen(),
        '/custodian-borrow-requests': (context) =>
            const CustodianBorrowedInventoryScreen(),
        '/custodian-return-verification': (context) =>
            const CustodianReturnVerificationScreen(),
        '/custodian-reports': (context) => const ReportsAnalyticsScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-users': (context) => const AdminUserManagementScreen(),
        '/admin-sections': (context) => const AdminSectionsScreen(),
        '/admin-resource-monitoring': (context) =>
            const AdminResourceMonitoringScreen(),
        '/admin-borrowing-monitor': (context) =>
            const AdminBorrowingMonitorScreen(),
        '/admin-reports': (context) => const AdminReportsScreen(),
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

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is FirebaseAuthException
        ? (error as FirebaseAuthException).message
        : null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: Color(0xFF176B87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EduTrack could not start',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message ??
                        'Firebase could not be initialized. Check the web configuration and rebuild.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

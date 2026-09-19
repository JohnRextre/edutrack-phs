import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../services/auth_service.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/borrower_navigation_bar.dart';
import '../widgets/custodian_sidebar.dart';
import 'admin_dashboard_screen.dart';
import 'borrower_dashboard_screen.dart';
import 'custodian_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    final isBorrower = role.isBorrower;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isBorrower,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          if (isBorrower)
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      drawer: isBorrower
          ? null
          : Drawer(child: _sidebarForRole(context, role, mobile: true)),
      body: isBorrower
          ? BorrowerDashboardScreen(
              role: role,
              onSignOut: () => _signOut(context),
            )
          : _ManagementShell(role: role, onSignOut: () => _signOut(context)),
      bottomNavigationBar: isBorrower
          ? const BorrowerNavigationBar(selectedIndex: 0)
          : null,
    );
  }

  Widget _sidebarForRole(
    BuildContext context,
    AccountRole role, {
    required bool mobile,
  }) {
    void navigate(String label) {
      if (mobile) Navigator.pop(context);
      final route = switch (label) {
        'Learning Resources' => '/custodian-resources',
        'Borrowed Inventory' => '/custodian-borrow-requests',
        'Borrow Requests' => '/custodian-borrow-requests',
        'Return Verification' => '/custodian-return-verification',
        'Reports' =>
          role == AccountRole.propertyCustodian
              ? '/custodian-reports'
              : '/custodian-reports',
        'User Management' => '/admin-users',
        'System Logs' => '/admin-logs',
        _ => null,
      };
      if (route != null) Navigator.pushNamed(context, route);
    }

    if (role == AccountRole.propertyCustodian) {
      return CustodianSidebar(
        onNavigate: navigate,
        onSignOut: () => _signOut(context),
      );
    }
    return AdminSidebar(
      onNavigate: navigate,
      onSignOut: () => _signOut(context),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}

class _ManagementShell extends StatelessWidget {
  const _ManagementShell({required this.role, required this.onSignOut});
  final AccountRole role;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final content = role == AccountRole.propertyCustodian
        ? const CustodianDashboardScreen()
        : const AdminDashboardScreen();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) return content;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 240, child: _desktopSidebar(context)),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _desktopSidebar(BuildContext context) {
    void navigate(String label) {
      final route = switch (label) {
        'Learning Resources' => '/custodian-resources',
        'Borrowed Inventory' => '/custodian-borrow-requests',
        'Borrow Requests' => '/custodian-borrow-requests',
        'Return Verification' => '/custodian-return-verification',
        'Reports' =>
          role == AccountRole.propertyCustodian
              ? '/custodian-reports'
              : '/custodian-reports',
        'User Management' => '/admin-users',
        'System Logs' => '/admin-logs',
        _ => null,
      };
      if (route != null) Navigator.pushNamed(context, route);
    }

    if (role == AccountRole.propertyCustodian) {
      return CustodianSidebar(onNavigate: navigate, onSignOut: onSignOut);
    }
    return AdminSidebar(onNavigate: navigate, onSignOut: onSignOut);
  }
}

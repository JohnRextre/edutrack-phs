import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/custodian_sidebar.dart';
import 'admin_dashboard_screen.dart';
import 'borrower_dashboard_screen.dart';
import 'custodian_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.role});

  final AccountRole role;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AccountRole _selectedRole = widget.role;

  @override
  Widget build(BuildContext context) {
    final isBorrower = _selectedRole.isBorrower;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<AccountRole>(
            tooltip: 'Switch dashboard role',
            initialValue: _selectedRole,
            onSelected: (role) => setState(() => _selectedRole = role),
            icon: const Icon(Icons.swap_horiz),
            itemBuilder: (context) => AccountRole.values
                .map(
                  (role) => PopupMenuItem(value: role, child: Text(role.label)),
                )
                .toList(),
          ),
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
          : Drawer(
              child: _sidebarForRole(context, _selectedRole, mobile: true),
            ),
      body: isBorrower
          ? BorrowerDashboardScreen(
              role: _selectedRole,
              onSignOut: () => _signOut(context),
            )
          : _ManagementShell(
              role: _selectedRole,
              onSignOut: () => _signOut(context),
            ),
      bottomNavigationBar: isBorrower ? const _BorrowerNavigationBar() : null,
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
        'Borrow Requests' => '/custodian-borrow-requests',
        'Return Verification' => '/custodian-return-verification',
        'Reports' =>
          role == AccountRole.propertyCustodian
              ? '/custodian-reports'
              : '/admin-dashboard',
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

  void _signOut(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
        'Borrow Requests' => '/custodian-borrow-requests',
        'Return Verification' => '/custodian-return-verification',
        'Reports' =>
          role == AccountRole.propertyCustodian
              ? '/custodian-reports'
              : '/admin-dashboard',
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

class _BorrowerNavigationBar extends StatelessWidget {
  const _BorrowerNavigationBar();

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: 0,
    onDestinationSelected: (index) {
      if (index == 1) Navigator.pushNamed(context, '/resources');
      if (index == 2) Navigator.pushNamed(context, '/return');
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(icon: Icon(Icons.search), label: 'Resources'),
      NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ],
  );
}

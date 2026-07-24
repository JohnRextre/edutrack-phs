import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../widgets/access_banner.dart';

class BorrowerDashboardScreen extends StatelessWidget {
  const BorrowerDashboardScreen({
    super.key,
    required this.role,
    required this.onSignOut,
  });

  final AccountRole role;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          'Welcome, John Rexter',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${role.label} account',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const AccessBanner(
          text:
              'Borrower Access: You can browse available learning resources, submit borrowing requests, view transaction status, and upload return verification photos.',
        ),
        const SizedBox(height: 16),
        const _BorrowerStats(),
        const SizedBox(height: 18),
        const Text(
          'Due Soon',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.schedule_outlined),
            title: Text('Biology Microscope'),
            subtitle: Text('Due in 3 days - SCI-MIC-001'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Borrowing History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text('Laptop Dell Latitude'),
            subtitle: Text('Returned - PHS-LPT-042'),
          ),
        ),
      ],
    );
  }
}

class _BorrowerStats extends StatelessWidget {
  const _BorrowerStats();

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.45,
    children: const [
      _Stat('My Borrowed Resources', '2', Icons.inventory_2_outlined),
      _Stat('Pending Borrow Requests', '1', Icons.pending_actions_outlined),
      _Stat(
        'Pending Return Requests',
        '0',
        Icons.assignment_turned_in_outlined,
      ),
      _Stat('Overdue Resources', '1', Icons.warning_amber_outlined),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    ),
  );
}

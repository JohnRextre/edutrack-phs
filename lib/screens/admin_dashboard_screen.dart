import 'package:flutter/material.dart';

import '../widgets/access_banner.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: const [
      Text(
        'ICT Coordinator Dashboard',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 12),
      AccessBanner(
        text:
            'ICT Coordinator Access: Manage user accounts, system configuration, and audit logs. Inventory and borrowing metrics are view-only.',
      ),
      SizedBox(height: 20),
      _AdminStats(),
      SizedBox(height: 20),
      ListTile(
        title: Text('System Logs'),
        subtitle: Text('12 new events require attention'),
      ),
      ListTile(
        title: Text('Recent Login Activities'),
        subtitle: Text('John Rexter logged in 10 minutes ago'),
      ),
    ],
  );
}

class _AdminStats extends StatelessWidget {
  const _AdminStats();
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: const [
      _AdminMetric('Total Users', '486'),
      _AdminMetric('Active Users', '412'),
      _AdminMetric('Inventory Overview (View Only)', '124'),
      _AdminMetric('Borrowing Overview (View Only)', '35'),
    ],
  );
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

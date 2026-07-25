import 'package:flutter/material.dart';

import '../widgets/borrower_navigation_bar.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Activity')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Account Activity & History',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Your borrowing, return, and compliance history.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        const _ActivityCard(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Return verification submitted',
          timestamp: 'Today, 10:20 AM',
          item: 'Dell Latitude 3420 · PHS-LPT-042',
          status: 'Pending Verification',
          color: Color(0xFF8A5600),
        ),
        const _ActivityCard(
          icon: Icons.bookmark_added_outlined,
          title: 'Borrow request submitted',
          timestamp: 'Today, 9:45 AM',
          item: 'Biology Microscope · SCI-MIC-001',
          status: 'Pending Approval',
          color: Color(0xFF8A5600),
        ),
        const _ActivityCard(
          icon: Icons.inventory_2_outlined,
          title: 'Item picked up',
          timestamp: 'July 12, 2026, 8:30 AM',
          item: 'Dell Latitude 3420 · PHS-LPT-042',
          status: 'Active Borrowing',
          color: Color(0xFF146C43),
        ),
        const _ActivityCard(
          icon: Icons.check_circle_outline,
          title: 'Borrow request approved',
          timestamp: 'July 11, 2026, 3:15 PM',
          item: 'Dell Latitude 3420 · PHS-LPT-042',
          status: 'Approved',
          color: Color(0xFF146C43),
        ),
        const _ActivityCard(
          icon: Icons.warning_amber_outlined,
          title: 'Overdue notice resolved',
          timestamp: 'June 21, 2026, 1:40 PM',
          item: 'Chemistry Glassware Set · SCI-GLS-017',
          status: 'Penalty Complied',
          color: Color(0xFF0B65B9),
        ),
        const _ActivityCard(
          icon: Icons.task_alt_outlined,
          title: 'Borrowing transaction completed',
          timestamp: 'May 14, 2026, 11:00 AM',
          item: 'Biology Microscope · SCI-MIC-001',
          status: 'Completed',
          color: Color(0xFF146C43),
        ),
      ],
    ),
    bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 4),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.item,
    required this.status,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String timestamp;
  final String item;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(timestamp),
                const SizedBox(height: 4),
                Text(item),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

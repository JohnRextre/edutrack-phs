import 'package:flutter/material.dart';

import 'borrower_return_screen.dart';
import '../widgets/borrower_navigation_bar.dart';

class MyBorrowingsScreen extends StatelessWidget {
  const MyBorrowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      BorrowedItem(
        title: 'Dell Latitude 3420',
        location: 'IT Department - Grade 11',
        assetTag: 'PHS-LPT-042',
        dueStatus: 'Due in 3 days',
        imagePath: 'lib/assets/borrowed_assets/Dell Laptop.png',
        fallbackIcon: Icons.laptop_mac_outlined,
      ),
      BorrowedItem(
        title: 'Biology Microscope',
        location: 'Science Lab - Grade 11',
        assetTag: 'SCI-MIC-001',
        dueStatus: 'Due in 5 days',
        imagePath: 'lib/assets/borrowed_assets/Biology Microscope.png',
        fallbackIcon: Icons.biotech_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Borrowings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Currently Borrowed',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Return items to their assigned office before the due date.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BorrowedItemCard(item: item),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 2),
    );
  }
}

class _BorrowedItemCard extends StatelessWidget {
  const _BorrowedItemCard({required this.item});
  final BorrowedItem item;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Image.asset(
            item.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _ImageFallback(item: item),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(item.location),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('ID: ${item.assetTag}')),
                  DueStatus(status: item.dueStatus),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BorrowerReturnScreen(item: item),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Return Item'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DueStatus extends StatelessWidget {
  const DueStatus({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE1DE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: Color(0xFFB3261E),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.item});
  final BorrowedItem item;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Center(
      child: Icon(
        item.fallbackIcon,
        size: 60,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
  );
}

class BorrowedItem {
  const BorrowedItem({
    required this.title,
    required this.location,
    required this.assetTag,
    required this.dueStatus,
    required this.imagePath,
    required this.fallbackIcon,
  });

  final String title;
  final String location;
  final String assetTag;
  final String dueStatus;
  final String imagePath;
  final IconData fallbackIcon;
}

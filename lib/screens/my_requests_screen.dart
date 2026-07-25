import 'package:flutter/material.dart';

import '../widgets/borrower_navigation_bar.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Borrow Requests'),
            Tab(text: 'Return Requests'),
          ],
        ),
      ),
      body: const TabBarView(children: [_BorrowRequests(), _ReturnRequests()]),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 3),
    ),
  );
}

class _BorrowRequests extends StatelessWidget {
  const _BorrowRequests();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      _BorrowRequestCard(
        item: 'Biology Microscope',
        code: 'SCI-MIC-001',
        date: 'July 25, 2026',
        purpose: 'Research for Science Fair',
        status: 'Pending Approval',
        color: Color(0xFF8A5600),
      ),
      _BorrowRequestCard(
        item: 'Dell Latitude 3420',
        code: 'PHS-LPT-042',
        date: 'July 12, 2026',
        purpose: 'STEM Class programming activity',
        status: 'Approved',
        color: Color(0xFF146C43),
      ),
      _BorrowRequestCard(
        item: 'Digital Camera',
        code: 'MED-CAM-008',
        date: 'June 30, 2026',
        purpose: 'Campus journalism coverage',
        status: 'Rejected',
        color: Color(0xFFB3261E),
      ),
    ],
  );
}

class _ReturnRequests extends StatelessWidget {
  const _ReturnRequests();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      _ReturnRequestCard(
        item: 'Dell Latitude 3420',
        date: 'July 25, 2026',
        status: 'Pending Verification',
        color: Color(0xFF8A5600),
        imagePath: 'lib/assets/borrowed_assets/Dell Laptop.png',
      ),
      _ReturnRequestCard(
        item: 'Biology Microscope',
        date: 'May 14, 2026',
        status: 'Approved',
        color: Color(0xFF146C43),
        imagePath: 'lib/assets/borrowed_assets/Biology Microscope.png',
      ),
      _ReturnRequestCard(
        item: 'Calculator Set',
        date: 'April 03, 2026',
        status: 'Pending Penalty',
        color: Color(0xFFB3261E),
      ),
    ],
  );
}

class _BorrowRequestCard extends StatelessWidget {
  const _BorrowRequestCard({
    required this.item,
    required this.code,
    required this.date,
    required this.purpose,
    required this.status,
    required this.color,
  });
  final String item;
  final String code;
  final String date;
  final String purpose;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusPill(label: status, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text('Code: $code'),
          Text('Requested: $date'),
          const SizedBox(height: 8),
          Text('Purpose: $purpose'),
        ],
      ),
    ),
  );
}

class _ReturnRequestCard extends StatelessWidget {
  const _ReturnRequestCard({
    required this.item,
    required this.date,
    required this.status,
    required this.color,
    this.imagePath,
  });
  final String item;
  final String date;
  final String status;
  final Color color;
  final String? imagePath;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 74,
              width: 74,
              child: imagePath == null
                  ? ColoredBox(
                      color: Colors.transparent,
                      child: Icon(
                        Icons.photo_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Colors.transparent,
                        child: Icon(Icons.photo_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Return submitted: $date'),
                const SizedBox(height: 8),
                _StatusPill(label: status, color: color),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

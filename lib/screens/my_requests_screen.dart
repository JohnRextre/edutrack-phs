import 'package:flutter/material.dart';

import '../widgets/borrower_navigation_bar.dart';
import 'resolution_submission_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String _rejectedReturnStatus = 'Rejected';
  Color _rejectedReturnColor = const Color(0xFFB3261E);

  Future<void> _resubmitAppeal() async {
    final resolution = await _showResolutionSelection(context);
    if (resolution == null || !mounted) return;

    final newStatus = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ResolutionSubmissionScreen(resolution: resolution),
      ),
    );
    if (newStatus != null && mounted) {
      setState(() {
        _rejectedReturnStatus = newStatus;
        _rejectedReturnColor = const Color(0xFF8A5600);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return request updated: $newStatus')),
      );
    }
  }

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
      body: TabBarView(
        children: [
          const _BorrowRequests(),
          _ReturnRequests(
            rejectedStatus: _rejectedReturnStatus,
            rejectedColor: _rejectedReturnColor,
            onResubmit: _resubmitAppeal,
          ),
        ],
      ),
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
        transactionId: 'BR-2026-0725-001',
        item: 'Biology Microscope',
        code: 'SCI-MIC-001',
        category: 'Science Lab - Grade 11',
        serialNumber: 'MIC-BIO-11024',
        date: 'July 25, 2026',
        purpose: 'Research for Science Fair',
        status: 'Pending Approval',
        color: Color(0xFF8A5600),
      ),
      _BorrowRequestCard(
        transactionId: 'BR-2026-0712-014',
        item: 'Dell Latitude 3420',
        code: 'PHS-LPT-042',
        category: 'IT Department - Grade 11',
        serialNumber: 'DL-3420-7F92',
        date: 'July 12, 2026',
        purpose: 'STEM Class programming activity',
        status: 'Approved',
        color: Color(0xFF146C43),
      ),
      _BorrowRequestCard(
        transactionId: 'BR-2026-0630-007',
        item: 'Digital Camera',
        code: 'MED-CAM-008',
        category: 'Media Center',
        serialNumber: 'CAM-008-5541',
        date: 'June 30, 2026',
        purpose: 'Campus journalism coverage',
        status: 'Rejected',
        color: Color(0xFFB3261E),
        adminNotes:
            'This item is already reserved for an official school event.',
      ),
    ],
  );
}

class _ReturnRequests extends StatelessWidget {
  const _ReturnRequests({
    required this.rejectedStatus,
    required this.rejectedColor,
    required this.onResubmit,
  });
  final String rejectedStatus;
  final Color rejectedColor;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _ReturnRequestCard(
        transactionId: 'RR-2026-0725-003',
        item: 'Dell Latitude 3420',
        code: 'PHS-LPT-042',
        category: 'IT Department - Grade 11',
        serialNumber: 'DL-3420-7F92',
        date: 'July 25, 2026',
        status: 'Pending Verification',
        color: Color(0xFF8A5600),
        imagePath: 'lib/assets/borrowed_assets/Dell Laptop.png',
      ),
      const _ReturnRequestCard(
        transactionId: 'RR-2026-0514-011',
        item: 'Biology Microscope',
        code: 'SCI-MIC-001',
        category: 'Science Lab - Grade 11',
        serialNumber: 'MIC-BIO-11024',
        date: 'May 14, 2026',
        status: 'Approved',
        color: Color(0xFF146C43),
        imagePath: 'lib/assets/borrowed_assets/Biology Microscope.png',
      ),
      _ReturnRequestCard(
        transactionId: 'RR-2026-0403-005',
        item: 'Calculator Set',
        code: 'MTH-CAL-016',
        category: 'Mathematics Department',
        serialNumber: 'CAL-016-2288',
        date: 'April 03, 2026',
        status: rejectedStatus,
        color: rejectedColor,
        adminNotes:
            'The returned calculator has a damaged display. Select the required resolution and submit supporting proof.',
        onResubmit: rejectedStatus == 'Rejected' ? onResubmit : null,
      ),
    ],
  );
}

class _BorrowRequestCard extends StatelessWidget {
  const _BorrowRequestCard({
    required this.transactionId,
    required this.item,
    required this.code,
    required this.category,
    required this.serialNumber,
    required this.date,
    required this.purpose,
    required this.status,
    required this.color,
    this.adminNotes,
  });
  final String transactionId,
      item,
      code,
      category,
      serialNumber,
      date,
      purpose,
      status;
  final Color color;
  final String? adminNotes;

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
              IconButton(
                tooltip: 'View request details',
                onPressed: () => _showRequestDetails(
                  context,
                  transactionId: transactionId,
                  requestDate: date,
                  item: item,
                  code: code,
                  category: category,
                  serialNumber: serialNumber,
                  status: status,
                  color: color,
                  adminNotes: adminNotes,
                ),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Code: $code'),
          Text('Requested: $date'),
          const SizedBox(height: 8),
          Text('Purpose: $purpose'),
          const SizedBox(height: 10),
          _StatusPill(label: status, color: color),
        ],
      ),
    ),
  );
}

class _ReturnRequestCard extends StatelessWidget {
  const _ReturnRequestCard({
    required this.transactionId,
    required this.item,
    required this.code,
    required this.category,
    required this.serialNumber,
    required this.date,
    required this.status,
    required this.color,
    this.imagePath,
    this.adminNotes,
    this.onResubmit,
  });
  final String transactionId, item, code, category, serialNumber, date, status;
  final Color color;
  final String? imagePath, adminNotes;
  final VoidCallback? onResubmit;

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
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: const Icon(Icons.photo_outlined),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'View request details',
                      onPressed: () => _showRequestDetails(
                        context,
                        transactionId: transactionId,
                        requestDate: date,
                        item: item,
                        code: code,
                        category: category,
                        serialNumber: serialNumber,
                        status: status,
                        color: color,
                        adminNotes: adminNotes,
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ],
                ),
                Text('Return submitted: $date'),
                const SizedBox(height: 8),
                _StatusPill(label: status, color: color),
                if (onResubmit != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onResubmit,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resubmit Appeal'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showRequestDetails(
  BuildContext context, {
  required String transactionId,
  required String requestDate,
  required String item,
  required String code,
  required String category,
  required String serialNumber,
  required String status,
  required Color color,
  String? adminNotes,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Request Details'),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow('Transaction ID', transactionId),
          _DetailRow('Request Date', requestDate),
          const Divider(),
          const Text(
            'Item Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          _DetailRow('Name', item),
          _DetailRow('Code', code),
          _DetailRow('Category', category),
          _DetailRow('Serial Number', serialNumber),
          const Divider(),
          const Text(
            'Borrow Period',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const _DetailRow('Start Date', 'July 12, 2026'),
          const _DetailRow('Due Date', 'July 29, 2026'),
          const SizedBox(height: 12),
          _StatusPill(label: status, color: color),
          if (adminNotes != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Admin Notes / Remarks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(adminNotes),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
);

Future<ResolutionType?> _showResolutionSelection(BuildContext context) {
  ResolutionType? selected;
  return showDialog<ResolutionType>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Resolve Rejected Return Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your return request was rejected by the administrator. Please select the required resolution type below to proceed.',
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<ResolutionType>(
              decoration: const InputDecoration(
                labelText: 'Select Resolution Type',
                border: OutlineInputBorder(),
              ),
              initialValue: selected,
              items: ResolutionType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selected = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selected == null
                ? null
                : () => Navigator.pop(context, selected),
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
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

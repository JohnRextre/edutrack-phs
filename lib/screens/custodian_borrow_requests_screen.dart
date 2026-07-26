import 'package:flutter/material.dart';

enum RequestStatus {
  pending('Pending Approval', Colors.orange),
  checkedOut('Checked Out', Colors.blue),
  awaitingVerification('Awaiting Verification', Colors.purple),
  returned('Returned & Verified', Colors.green),
  rejected('Rejected', Colors.red);

  const RequestStatus(this.label, this.color);
  final String label;
  final Color color;
}

class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.borrowerName,
    required this.borrowerRole,
    required this.borrowerContact,
    required this.itemTitle,
    required this.assetTag,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    this.returnPhotoPath,
    this.returnNotes,
    this.rejectionReason,
  });

  final String id;
  final String borrowerName;
  final String borrowerRole;
  final String borrowerContact;
  final String itemTitle;
  final String assetTag;
  final DateTime issueDate;
  final DateTime dueDate;
  final RequestStatus status;
  final String? returnPhotoPath;
  final String? returnNotes;
  final String? rejectionReason;
}

class CustodianBorrowRequestsScreen extends StatefulWidget {
  const CustodianBorrowRequestsScreen({super.key});

  @override
  State<CustodianBorrowRequestsScreen> createState() =>
      _CustodianBorrowRequestsScreenState();
}

class _CustodianBorrowRequestsScreenState
    extends State<CustodianBorrowRequestsScreen> {
  RequestStatus _selectedTab = RequestStatus.pending;

  // Sample data - in real app, this would come from a database/service
  final List<BorrowRequest> _allRequests = [
    BorrowRequest(
      id: 'REQ-001',
      borrowerName: 'Juan Dela Cruz',
      borrowerRole: 'Student - Grade 11 STEM',
      borrowerContact: 'ID: 2023-0456',
      itemTitle: 'Advanced Physics Vol 2',
      assetTag: 'SCI-BIO-001',
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      status: RequestStatus.pending,
    ),
    BorrowRequest(
      id: 'REQ-002',
      borrowerName: 'Maria Reyes',
      borrowerRole: 'Teacher - Science Dept',
      borrowerContact: 'EMP-1234',
      itemTitle: 'Biology Microscope',
      assetTag: 'SCI-MIC-001',
      issueDate: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: RequestStatus.checkedOut,
    ),
    BorrowRequest(
      id: 'REQ-003',
      borrowerName: 'Pedro Santos',
      borrowerRole: 'Student - Grade 12 ABM',
      borrowerContact: 'ID: 2023-0789',
      itemTitle: 'Dell Latitude 3420',
      assetTag: 'ICT-LPT-001',
      issueDate: DateTime.now().subtract(const Duration(days: 10)),
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      status: RequestStatus.awaitingVerification,
      returnPhotoPath: 'lib/assets/borrowed_assets/return_photo.jpg',
      returnNotes: 'Item returned in good condition, minor scratch on lid.',
    ),
  ];

  List<BorrowRequest> get _filteredRequests {
    return _allRequests.where((request) {
      if (_selectedTab == RequestStatus.pending) {
        return request.status == RequestStatus.pending;
      } else if (_selectedTab == RequestStatus.checkedOut) {
        return request.status == RequestStatus.checkedOut;
      } else if (_selectedTab == RequestStatus.awaitingVerification) {
        return request.status == RequestStatus.awaitingVerification;
      } else if (_selectedTab == RequestStatus.returned) {
        return request.status == RequestStatus.returned;
      } else {
        return request.status == RequestStatus.rejected;
      }
    }).toList();
  }

  void _approveRequest(BorrowRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          'Approve borrow request for ${request.borrowerName}?\n\n'
          'Item: ${request.itemTitle}\n'
          'Due Date: ${_formatDate(request.dueDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Request approved. Item marked as checked out.',
                  ),
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(BorrowRequest request) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject request from ${request.borrowerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText: 'e.g., Item under maintenance, Reserved for lab exam',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection.'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request rejected.')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _sendOverdueReminder(BorrowRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Overdue Reminder'),
        content: Text(
          'Send overdue reminder to ${request.borrowerName}?\n\n'
          'Item: ${request.itemTitle}\n'
          'Due Date: ${_formatDate(request.dueDate)}\n'
          'Days Overdue: ${DateTime.now().difference(request.dueDate).inDays}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Overdue reminder sent to ${request.borrowerName}.',
                  ),
                ),
              );
            },
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );
  }

  void _openReturnVerificationModal(BorrowRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Return Verification',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Borrower Info
                      Text(
                        'Borrower: ${request.borrowerName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.borrowerRole} • ${request.borrowerContact}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Item Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.itemTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Asset Tag: ${request.assetTag}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo Proof Preview
                      const Text(
                        'Return Photo Proof',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: request.returnPhotoPath != null
                            ? Image.asset(
                                request.returnPhotoPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Photo not available'),
                                        ],
                                      ),
                                    ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.no_photography, size: 48),
                                    SizedBox(height: 8),
                                    Text('No photo uploaded'),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Borrower Condition Notes
                      const Text(
                        'Borrower Condition Notes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.returnNotes ?? 'No notes provided.',
                          style: TextStyle(
                            color: request.returnNotes == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDamageReportDialog(request);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Flag Damage / Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Return verified. Inventory quantity updated successfully!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Approve Return'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDamageReportDialog(BorrowRequest request) {
    final damageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Damage / Reject Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report issues for ${request.itemTitle}:'),
            const SizedBox(height: 16),
            TextField(
              controller: damageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Damage / Issue Description *',
                hintText: 'Describe the damage or missing accessories...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (damageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please describe the damage or issue.'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Return flagged. Borrower will be notified.'),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _filteredRequests;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Requests')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Navigation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: RequestStatus.values.map((status) {
                final isSelected = _selectedTab == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTab = status;
                      });
                    },
                    selectedColor: status.color.withValues(alpha: 0.2),
                    checkmarkColor: status.color,
                    labelStyle: TextStyle(
                      color: isSelected ? status.color : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Requests List
          Expanded(
            child: filteredRequests.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No requests found for this category.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      final request = filteredRequests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RequestCard(
                          request: request,
                          onApprove: () => _approveRequest(request),
                          onReject: () => _rejectRequest(request),
                          onRemind: () => _sendOverdueReminder(request),
                          onVerify: () => _openReturnVerificationModal(request),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onRemind,
    required this.onVerify,
  });

  final BorrowRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRemind;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        request.status == RequestStatus.checkedOut &&
        DateTime.now().isAfter(request.dueDate);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.itemTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: request.status.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status.label,
                    style: TextStyle(
                      color: request.status.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Borrower Info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.borrowerName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${request.borrowerRole} • ${request.borrowerContact}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Resource Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Asset Tag: ${request.assetTag}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Issued: ${_formatDate(request.issueDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_busy, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${_formatDate(request.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : null,
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            if (request.status == RequestStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == RequestStatus.checkedOut) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isOverdue ? onRemind : null,
                  icon: Icon(
                    isOverdue ? Icons.notifications_active : Icons.check_circle,
                  ),
                  label: Text(
                    isOverdue ? 'Send Overdue Reminder' : 'Mark as Returned',
                  ),
                ),
              ),
            ] else if (request.status ==
                RequestStatus.awaitingVerification) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Inspect Return Photo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';

/// Custodian view for approving or rejecting pending borrow requests.
class CustodianBorrowRequestsScreen extends StatefulWidget {
  const CustodianBorrowRequestsScreen({super.key});

  @override
  State<CustodianBorrowRequestsScreen> createState() =>
      _CustodianBorrowRequestsScreenState();
}

class _CustodianBorrowRequestsScreenState
    extends State<CustodianBorrowRequestsScreen> {
  final BorrowService _borrowService = BorrowService();
  bool _isProcessing = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Action completed successfully.');
      }
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _approveRequest(BorrowTransaction transaction) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          'Approve borrow request for ${transaction.userName}?\n\n'
          'Item: ${transaction.resourceName}\n'
          'Quantity: ${transaction.requestedQuantity}\n'
          'Due: ${formatBorrowDate(transaction.expectedReturnDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _runWithLoading(
                () => _borrowService.approveBorrow(
                  transaction.id,
                  transaction.resourceId,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(BorrowTransaction transaction) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text(
          'Reject the borrow request from ${transaction.userName} for '
          '${transaction.resourceName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _runWithLoading(
                () => _borrowService.rejectBorrow(transaction.id),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Requests')),
      body: Stack(
        children: [
          StreamBuilder<List<BorrowTransaction>>(
            stream: _borrowService.getPendingRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    BorrowService.friendlyErrorMessage(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final requests = snapshot.data ?? const [];

              if (requests.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No pending borrow requests.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PendingRequestCard(
                      transaction: request,
                      onApprove: () => _approveRequest(request),
                      onReject: () => _rejectRequest(request),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.transaction,
    required this.onApprove,
    required this.onReject,
  });

  final BorrowTransaction transaction;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.resourceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                BorrowStatusBadge(transaction: transaction, compact: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transaction.userName,
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
                Text(
                  transaction.userRole == 'teacher' ? 'Teacher' : 'Student',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asset Tag: ${transaction.resourceCode}'),
                  const SizedBox(height: 4),
                  Text('Quantity: ${transaction.requestedQuantity}'),
                  const SizedBox(height: 4),
                  Text(
                    'Requested: ${formatBorrowDate(transaction.borrowDate)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expected return: '
                    '${formatBorrowDate(transaction.expectedReturnDate)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}

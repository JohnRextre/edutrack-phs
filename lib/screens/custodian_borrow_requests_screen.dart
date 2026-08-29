import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import 'custodian/borrow_request_details_screen.dart';

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

  Future<void> _openBorrowDetails(BorrowTransaction transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BorrowRequestDetailsScreen(transaction: transaction),
      ),
    );

    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result
              ? 'Borrow request processed successfully.'
              : 'Request updated.',
        ),
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
                  final isExpired =
                      BorrowService.isPendingBorrowTransactionExpired(request);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PendingRequestCard(
                      transaction: request,
                      isExpired: isExpired,
                      onTap: () => _openBorrowDetails(request),
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
    required this.isExpired,
    required this.onTap,
  });

  final BorrowTransaction transaction;
  final bool isExpired;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
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
                  if (isExpired)
                    _ExpiredChip(compact: true)
                  else
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
              if (isExpired) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    border: Border.all(color: Colors.amber.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This request expired because the scheduled borrow or return '
                    'date has passed.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Verify request',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiredChip extends StatelessWidget {
  const _ExpiredChip({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(compact ? 12 : 20),
      ),
      child: Text(
        'Expired',
        style: TextStyle(
          color: Colors.amber.shade900,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

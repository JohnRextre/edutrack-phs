import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';

/// Full borrowing and transaction history, opened from Profile → Account Activities.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final borrowService = BorrowService();

    return Scaffold(
      appBar: AppBar(title: const Text('Account Activities')),
      body: userId == null
          ? const Center(
              child: Text('Please sign in to view your activity history.'),
            )
          : StreamBuilder<List<BorrowTransaction>>(
              stream: borrowService.getStudentBorrowHistory(userId),
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

                final transactions = snapshot.data ?? const [];

                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activity yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your borrowing and return history will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Account Activity & History',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your borrowing, return, and compliance history.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...transactions.map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityTransactionCard(
                          transaction: transaction,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ActivityTransactionCard extends StatelessWidget {
  const _ActivityTransactionCard({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => BorrowTransactionDetailsModal.show(
          context,
          transaction: transaction,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    transaction.statusColor.withValues(alpha: 0.12),
                child: Icon(
                  _iconForStatus(transaction.effectiveStatus),
                  color: transaction.statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.resourceName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        BorrowStatusBadge(
                          transaction: transaction,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Code: ${transaction.resourceCode}'),
                    Text(
                      'Requested: ${formatBorrowDate(transaction.borrowDate)}',
                    ),
                    if (transaction.actualReturnDate != null)
                      Text(
                        'Returned: ${formatBorrowDate(transaction.actualReturnDate!)}',
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => BorrowTransactionDetailsModal.show(
                          context,
                          transaction: transaction,
                        ),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('View Details'),
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

  IconData _iconForStatus(String status) {
    switch (status) {
      case BorrowTransactionStatus.pending:
        return Icons.pending_actions_outlined;
      case BorrowTransactionStatus.borrowed:
        return Icons.inventory_2_outlined;
      case BorrowTransactionStatus.overdue:
        return Icons.warning_amber_outlined;
      case BorrowTransactionStatus.borrowRejected:
        return Icons.cancel_outlined;
      case BorrowTransactionStatus.returnPending:
        return Icons.assignment_return_outlined;
      case BorrowTransactionStatus.returned:
        return Icons.check_circle_outline;
      case BorrowTransactionStatus.returnRejected:
        return Icons.replay_circle_filled_outlined;
      default:
        return Icons.history;
    }
  }
}

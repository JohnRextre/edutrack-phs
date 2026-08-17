import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';
import '../widgets/borrower_navigation_bar.dart';

/// Shows the student's or teacher's currently borrowed items from Firestore.
class MyBorrowingsScreen extends StatelessWidget {
  const MyBorrowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final borrowService = BorrowService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Borrowed Items')),
      body: userId == null
          ? const Center(child: Text('Please sign in to view borrowings.'))
          : StreamBuilder<List<BorrowTransaction>>(
              stream: borrowService.watchActiveBorrowings(userId),
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

                final items = snapshot.data ?? const [];

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Currently Borrowed',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Return items to the property custodian before the due date.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'You have no active borrowings.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _BorrowedItemCard(
                            transaction: transaction,
                            borrowService: borrowService,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 2),
    );
  }
}

class _BorrowedItemCard extends StatefulWidget {
  const _BorrowedItemCard({
    required this.transaction,
    required this.borrowService,
  });

  final BorrowTransaction transaction;
  final BorrowService borrowService;

  @override
  State<_BorrowedItemCard> createState() => _BorrowedItemCardState();
}

class _BorrowedItemCardState extends State<_BorrowedItemCard> {
  bool _isSubmittingReturn = false;

  Future<void> _submitReturn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Return Item'),
        content: Text(
          'Submit a return request for ${widget.transaction.resourceName}? '
          'The property custodian will verify the item before it is marked returned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Return Item'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmittingReturn = true);
    try {
      await widget.borrowService.submitReturnRequest(widget.transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Return request submitted. Track progress under My Requests → Return Requests.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BorrowService.friendlyErrorMessage(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReturn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isOverdue =
        transaction.effectiveStatus == BorrowTransactionStatus.overdue;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => BorrowTransactionDetailsModal.show(
          context,
          transaction: transaction,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.resourceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BorrowStatusBadge(transaction: transaction, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text('Code: ${transaction.resourceCode}'),
              if (transaction.requestedQuantity > 1)
                Text('Quantity: ${transaction.requestedQuantity}'),
              Text('Borrowed: ${formatBorrowDate(transaction.borrowDate)}'),
              Text('Due: ${formatBorrowDate(transaction.expectedReturnDate)}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.withValues(alpha: 0.12)
                      : const Color(0xFFFFE1DE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  borrowDueLabel(transaction),
                  style: TextStyle(
                    color: isOverdue
                        ? Colors.red.shade700
                        : const Color(0xFFB3261E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => BorrowTransactionDetailsModal.show(
                        context,
                        transaction: transaction,
                      ),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmittingReturn ? null : _submitReturn,
                      icon: _isSubmittingReturn
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.assignment_return, size: 18),
                      label: const Text('Return Item'),
                    ),
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

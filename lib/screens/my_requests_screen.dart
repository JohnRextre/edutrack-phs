import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';
import '../widgets/borrower_navigation_bar.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
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
        body: userId == null
            ? const Center(
                child: Text('Please sign in to view your requests.'),
              )
            : TabBarView(
                children: [
                  _BorrowRequestsTab(userId: userId),
                  _ReturnRequestsTab(userId: userId),
                ],
              ),
        bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 3),
      ),
    );
  }
}

class _BorrowRequestsTab extends StatelessWidget {
  const _BorrowRequestsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final borrowService = BorrowService();

    return StreamBuilder<List<BorrowTransaction>>(
      stream: borrowService.watchBorrowRequests(userId),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No borrow requests yet.\nBrowse Resources to request an item.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: transactions
              .map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BorrowRequestCard(transaction: transaction),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReturnRequestsTab extends StatelessWidget {
  const _ReturnRequestsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final borrowService = BorrowService();

    return StreamBuilder<List<BorrowTransaction>>(
      stream: borrowService.watchReturnRequests(userId),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No return requests yet.\nSubmit a return from My Borrowed Items.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: transactions
              .map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ReturnRequestCard(
                    transaction: transaction,
                    borrowService: borrowService,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _BorrowRequestCard extends StatelessWidget {
  const _BorrowRequestCard({required this.transaction});

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 8),
              Text('Code: ${transaction.resourceCode}'),
              if (transaction.requestedQuantity > 1)
                Text('Quantity: ${transaction.requestedQuantity}'),
              Text('Requested: ${formatBorrowDate(transaction.borrowDate)}'),
              Text(
                'Expected return: ${formatBorrowDate(transaction.expectedReturnDate)}',
              ),
              if (transaction.isBorrowRejected &&
                  (transaction.rejectionReason?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: ${transaction.rejectionReason!.trim()}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
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
      ),
    );
  }
}

class _ReturnRequestCard extends StatefulWidget {
  const _ReturnRequestCard({
    required this.transaction,
    required this.borrowService,
  });

  final BorrowTransaction transaction;
  final BorrowService borrowService;

  @override
  State<_ReturnRequestCard> createState() => _ReturnRequestCardState();
}

class _ReturnRequestCardState extends State<_ReturnRequestCard> {
  bool _isResubmitting = false;

  Future<void> _resubmitAppeal() async {
    if (_isResubmitting) return;

    setState(() => _isResubmitting = true);
    try {
      await widget.borrowService.resubmitReturnRequest(widget.transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return request resubmitted for verification.'),
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
      if (mounted) setState(() => _isResubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;

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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BorrowStatusBadge(transaction: transaction, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text('Code: ${transaction.resourceCode}'),
              if (transaction.returnSubmittedDate != null)
                Text(
                  'Submitted: ${formatBorrowDate(transaction.returnSubmittedDate!)}',
                ),
              if (transaction.actualReturnDate != null)
                Text(
                  'Returned: ${formatBorrowDate(transaction.actualReturnDate!)}',
                ),
              if (transaction.isReturnRejected &&
                  (transaction.rejectionReason?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: ${transaction.rejectionReason!.trim()}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (transaction.isReturnRejected)
                    FilledButton.tonalIcon(
                      onPressed: _isResubmitting ? null : _resubmitAppeal,
                      icon: _isResubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.replay, size: 18),
                      label: const Text('Resubmit Appeal'),
                    ),
                  if (transaction.isReturnRejected) const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => BorrowTransactionDetailsModal.show(
                      context,
                      transaction: transaction,
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrower_navigation_bar.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final borrowService = BorrowService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Borrow Requests')),
      body: userId == null
          ? const Center(child: Text('Please sign in to view your requests.'))
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
            ),
      bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 3),
    );
  }
}

class _BorrowRequestCard extends StatelessWidget {
  const _BorrowRequestCard({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Card(
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
            if (transaction.actualReturnDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Returned: ${formatBorrowDate(transaction.actualReturnDate!)}',
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Role: ${transaction.userRole == 'teacher' ? 'Teacher' : 'Student'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

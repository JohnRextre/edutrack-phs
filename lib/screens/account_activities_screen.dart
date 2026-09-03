import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';

enum _ActivitySort { newest, oldest, status }

class AccountActivitiesScreen extends StatefulWidget {
  const AccountActivitiesScreen({super.key});

  @override
  State<AccountActivitiesScreen> createState() =>
      _AccountActivitiesScreenState();
}

class _AccountActivitiesScreenState extends State<AccountActivitiesScreen> {
  final _searchController = TextEditingController();
  final _borrowService = BorrowService();
  _ActivitySort _sort = _ActivitySort.newest;
  int? _limit = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Account Activities')),
      body: userId == null
          ? const Center(
              child: Text('Please sign in to view your activity history.'),
            )
          : StreamBuilder<List<BorrowTransaction>>(
              stream: _borrowService.watchAccountActivities(userId),
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
                return _buildContent(context, snapshot.data ?? const []);
              },
            ),
    );
  }

  Widget _buildContent(BuildContext context, List<BorrowTransaction> raw) {
    final query = _searchController.text.trim().toLowerCase();
    final matching = raw.where((transaction) {
      if (query.isEmpty) return true;
      return transaction.resourceName.toLowerCase().contains(query) ||
          transaction.resourceCode.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case _ActivitySort.newest:
        matching.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
      case _ActivitySort.oldest:
        matching.sort((a, b) => a.borrowDate.compareTo(b.borrowDate));
      case _ActivitySort.status:
        matching.sort((a, b) {
          final statusCompare = a.statusLabel.compareTo(b.statusLabel);
          return statusCompare != 0
              ? statusCompare
              : b.borrowDate.compareTo(a.borrowDate);
        });
    }

    final visible = _limit == null ? matching : matching.take(_limit!).toList();
    final hasMore = matching.length > visible.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Account Activity & History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search item name or resource code',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<_ActivitySort>(
                      initialValue: _sort,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Sort',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _ActivitySort.newest,
                          child: Text('Newest First'),
                        ),
                        DropdownMenuItem(
                          value: _ActivitySort.oldest,
                          child: Text('Oldest First'),
                        ),
                        DropdownMenuItem(
                          value: _ActivitySort.status,
                          child: Text('By Status'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _sort = value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _limit,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Display',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10 items')),
                        DropdownMenuItem(value: 25, child: Text('25 items')),
                        DropdownMenuItem(value: 50, child: Text('50 items')),
                        DropdownMenuItem(value: null, child: Text('Show All')),
                      ],
                      onChanged: (value) => setState(() => _limit = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      query.isEmpty
                          ? 'No activity records found.'
                          : 'No activity records found matching your search.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityCard(transaction: visible[index]),
                  ),
                ),
        ),
        if (hasMore)
          TextButton.icon(
            onPressed: () => setState(() {
              _limit = (_limit ?? matching.length) + 10;
            }),
            icon: const Icon(Icons.expand_more),
            label: const Text('Load More Activities'),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Showing ${visible.length} of ${matching.length} activities',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final reason = transaction.isExpiredBorrowRejection
        ? BorrowService.borrowRequestExpiredDisplayReason
        : transaction.rejectionReason?.trim();
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
                backgroundColor: transaction.statusColor.withValues(alpha: .12),
                child: Icon(
                  transaction.statusLabel == 'Returned'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
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
                    Text('Item Code: ${transaction.resourceCode}'),
                    Text('Date: ${formatBorrowDate(transaction.borrowDate)}'),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: TextStyle(
                          color: transaction.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

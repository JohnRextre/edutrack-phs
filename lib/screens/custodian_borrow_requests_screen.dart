import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';

/// Property Custodian screen for monitoring all active borrowed resources.
class CustodianBorrowRequestsScreen extends StatefulWidget {
  const CustodianBorrowRequestsScreen({super.key});

  @override
  State<CustodianBorrowRequestsScreen> createState() =>
      _CustodianBorrowRequestsScreenState();
}

/// Alias for modern semantic naming
typedef CustodianBorrowedInventoryScreen = CustodianBorrowRequestsScreen;

class _CustodianBorrowRequestsScreenState
    extends State<CustodianBorrowRequestsScreen> {
  final BorrowService _borrowService = BorrowService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter =
      'All'; // 'All', 'Students', 'Teachers', 'Overdue', 'Pending Return'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BorrowTransaction> _filterTransactions(
    List<BorrowTransaction> transactions,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return transactions.where((tx) {
      final isOverdue = BorrowService.isOverdueBorrowing(tx);

      if (_selectedFilter == 'Students' && tx.userRole != 'student') {
        return false;
      }
      if (_selectedFilter == 'Teachers' && tx.userRole != 'teacher') {
        return false;
      }
      if (_selectedFilter == 'Overdue' && !isOverdue) {
        return false;
      }
      if (_selectedFilter == 'Pending Return' &&
          tx.status != BorrowTransactionStatus.returnPending) {
        return false;
      }

      if (query.isNotEmpty) {
        final matchesName = tx.resourceName.toLowerCase().contains(query);
        final matchesCode = tx.resourceCode.toLowerCase().contains(query);
        final matchesUser = tx.userName.toLowerCase().contains(query);
        final matchesRole = tx.userRole.toLowerCase().contains(query);
        final matchesPurpose = tx.purpose.toLowerCase().contains(query);
        return matchesName ||
            matchesCode ||
            matchesUser ||
            matchesRole ||
            matchesPurpose;
      }

      return true;
    }).toList();
  }

  void _showTransactionDetails(BorrowTransaction transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverdue = BorrowService.isOverdueBorrowing(transaction);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.resourceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BorrowStatusBadge(transaction: transaction),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Asset Code: ${transaction.resourceCode}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Borrower',
                value:
                    '${transaction.userName} (${transaction.userRole == 'teacher' ? 'Teacher' : 'Student'})',
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.numbers_outlined,
                label: 'Quantity Borrowed',
                value:
                    '${transaction.requestedQuantity} unit${transaction.requestedQuantity > 1 ? 's' : ''}',
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date Borrowed',
                value: formatBorrowDate(transaction.borrowDate),
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.event_available_outlined,
                label: 'Expected Return Date',
                value: formatBorrowDate(transaction.expectedReturnDate),
                valueColor: isOverdue ? Colors.red.shade700 : null,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Due Status',
                value: BorrowService.dueSoonLabel(
                  transaction.expectedReturnDate,
                ),
                valueColor: isOverdue
                    ? Colors.red.shade700
                    : Colors.green.shade800,
              ),
              if (transaction.purpose.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Purpose',
                  value: transaction.purpose,
                ),
              ],
              if (transaction.status ==
                  BorrowTransactionStatus.returnPending) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_return_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Borrower has submitted a return request awaiting verification.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      Navigator.pushNamed(
                        context,
                        '/custodian-return-verification',
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Open Return Verification'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrowed Inventory')),
      body: StreamBuilder<List<BorrowTransaction>>(
        stream: _borrowService.watchBorrowedInventory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  BorrowService.friendlyErrorMessage(snapshot.error!),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBorrowed = snapshot.data ?? const [];
          final filtered = _filterTransactions(allBorrowed);

          final totalItems = allBorrowed.length;
          final totalUnits = allBorrowed.fold<int>(
            0,
            (sum, item) => sum + item.requestedQuantity,
          );
          final overdueCount = allBorrowed
              .where(BorrowService.isOverdueBorrowing)
              .length;
          final returnPendingCount = allBorrowed
              .where(
                (item) => item.status == BorrowTransactionStatus.returnPending,
              )
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search by borrower, item, or asset code...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),

              // Summary metric chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Active Records',
                      count: totalItems,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Total Units Out',
                      count: totalUnits,
                      color: Colors.indigo,
                    ),
                    if (overdueCount > 0) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Overdue',
                        count: overdueCount,
                        color: Colors.red.shade700,
                      ),
                    ],
                    if (returnPendingCount > 0) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Pending Return',
                        count: returnPendingCount,
                        color: Colors.orange.shade800,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children:
                      [
                        'All',
                        'Students',
                        'Teachers',
                        'Overdue',
                        'Pending Return',
                      ].map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // List of Borrowed Items
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isNotEmpty ||
                                        _selectedFilter != 'All'
                                    ? 'No borrowed items match the filter.'
                                    : 'No items currently borrowed in inventory.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          final isOverdue = BorrowService.isOverdueBorrowing(
                            tx,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BorrowedInventoryCard(
                              transaction: tx,
                              isOverdue: isOverdue,
                              onTap: () => _showTransactionDetails(tx),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowedInventoryCard extends StatelessWidget {
  const _BorrowedInventoryCard({
    required this.transaction,
    required this.isOverdue,
    required this.onTap,
  });

  final BorrowTransaction transaction;
  final bool isOverdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dueLabel = BorrowService.dueSoonLabel(transaction.expectedReturnDate);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isOverdue ? Colors.red.shade300 : colorScheme.outlineVariant,
          width: isOverdue ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      color: isOverdue
          ? Colors.red.withValues(alpha: 0.04)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Item Name and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.resourceName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code: ${transaction.resourceCode} • Qty: ${transaction.requestedQuantity}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BorrowStatusBadge(transaction: transaction, compact: true),
                ],
              ),
              const SizedBox(height: 10),

              // Borrower details
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: Text(
                        transaction.userRole == 'teacher'
                            ? 'Teacher'
                            : 'Student',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Due Date & Due status row
              Row(
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.schedule_outlined,
                    size: 16,
                    color: isOverdue
                        ? Colors.red.shade700
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Due: ${formatBorrowDate(transaction.expectedReturnDate)} ($dueLabel)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isOverdue
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isOverdue
                            ? Colors.red.shade700
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

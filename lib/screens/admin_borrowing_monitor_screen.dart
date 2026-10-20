import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';

class AdminBorrowingMonitorScreen extends StatefulWidget {
  const AdminBorrowingMonitorScreen({super.key});

  @override
  State<AdminBorrowingMonitorScreen> createState() =>
      _AdminBorrowingMonitorScreenState();
}

class _AdminBorrowingMonitorScreenState
    extends State<AdminBorrowingMonitorScreen> {
  final BorrowService _borrowService = BorrowService();
  final TextEditingController _searchController = TextEditingController();
  String _status = 'All';
  _BorrowingSort _sort = _BorrowingSort.newest;
  int _displayLimit = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BorrowTransaction> _filterAndSort(List<BorrowTransaction> transactions) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = transactions.where((transaction) {
      if (_status != 'All' && transaction.effectiveStatus != _status) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        transaction.resourceName,
        transaction.resourceCode,
        transaction.userName,
        transaction.userRole,
        transaction.sectionName,
        transaction.purpose,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _BorrowingSort.newest:
          return b.borrowDate.compareTo(a.borrowDate);
        case _BorrowingSort.dueSoon:
          return a.expectedReturnDate.compareTo(b.expectedReturnDate);
        case _BorrowingSort.borrower:
          return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
        case _BorrowingSort.item:
          return a.resourceName.toLowerCase().compareTo(
            b.resourceName.toLowerCase(),
          );
        case _BorrowingSort.status:
          return a.statusLabel.compareTo(b.statusLabel);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowing Monitor'),
        actions: [
          IconButton(
            tooltip: 'Refresh transactions',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<BorrowTransaction>>(
        stream: _borrowService.watchAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load borrowing records.\n'
                '${BorrowService.friendlyErrorMessage(snapshot.error!)}',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = _filterAndSort(snapshot.data ?? const []);
          final visibleRecords = _displayLimit == 0
              ? records
              : records.take(_displayLimit).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonitorHeader(total: snapshot.data?.length ?? 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search borrower, item, code, or section',
                  leading: const Icon(Icons.search),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final status in const [
                      'All',
                      'borrowed',
                      'overdue',
                      'return_pending',
                      'returned',
                      'return_rejected',
                      'borrow_rejected',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_statusLabel(status)),
                          selected: _status == status,
                          onSelected: (_) => setState(() => _status = status),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      visibleRecords.length == records.length
                          ? '${records.length} record${records.length == 1 ? '' : 's'}'
                          : 'Showing ${visibleRecords.length} of ${records.length} records',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Text('Show'),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _displayLimit,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _displayLimit = value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 25, child: Text('25')),
                          DropdownMenuItem(value: 50, child: Text('50')),
                          DropdownMenuItem(value: 100, child: Text('100')),
                          DropdownMenuItem(value: 0, child: Text('All')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<_BorrowingSort>(
                        value: _sort,
                        icon: const Icon(Icons.sort_rounded, size: 20),
                        onChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: _BorrowingSort.newest,
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: _BorrowingSort.dueSoon,
                            child: Text('Due date'),
                          ),
                          DropdownMenuItem(
                            value: _BorrowingSort.borrower,
                            child: Text('Borrower'),
                          ),
                          DropdownMenuItem(
                            value: _BorrowingSort.item,
                            child: Text('Item'),
                          ),
                          DropdownMenuItem(
                            value: _BorrowingSort.status,
                            child: Text('Status'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          'No borrowing or return records match your filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visibleRecords.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _BorrowingRecordCard(
                          transaction: visibleRecords[index],
                          onTap: () =>
                              _showDetails(context, visibleRecords[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, BorrowTransaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.resourceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  BorrowStatusBadge(transaction: transaction),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                transaction.resourceCode,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 28),
              _DetailLine(
                icon: Icons.person_outline,
                label: 'Borrower',
                value: '${transaction.userName} (${transaction.userRole})',
              ),
              _DetailLine(
                icon: Icons.groups_outlined,
                label: 'Section',
                value: transaction.sectionName.isEmpty
                    ? 'No section assigned'
                    : transaction.sectionName,
              ),
              _DetailLine(
                icon: Icons.inventory_2_outlined,
                label: 'Quantity',
                value: '${transaction.requestedQuantity} unit(s)',
              ),
              _DetailLine(
                icon: Icons.calendar_today_outlined,
                label: 'Borrowed',
                value: _dateLabel(transaction.borrowDate),
              ),
              _DetailLine(
                icon: Icons.event_available_outlined,
                label: 'Expected return',
                value: _dateLabel(transaction.expectedReturnDate),
              ),
              if (transaction.actualReturnDate != null)
                _DetailLine(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Returned',
                  value: _dateLabel(transaction.actualReturnDate!),
                ),
              if (transaction.returnSubmittedDate != null)
                _DetailLine(
                  icon: Icons.outbox_outlined,
                  label: 'Return submitted',
                  value: _dateLabel(transaction.returnSubmittedDate!),
                ),
              if (transaction.purpose.isNotEmpty)
                _DetailLine(
                  icon: Icons.notes_outlined,
                  label: 'Purpose',
                  value: transaction.purpose,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    if (status == 'All') return status;
    return status
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  static String _dateLabel(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

class _MonitorHeader extends StatelessWidget {
  const _MonitorHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Borrowing & Returns',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$total total transaction${total == 1 ? '' : 's'}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowingRecordCard extends StatelessWidget {
  const _BorrowingRecordCard({required this.transaction, required this.onTap});

  final BorrowTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: transaction.statusColor.withValues(alpha: 0.12),
              child: Icon(
                transaction.effectiveStatus == BorrowTransactionStatus.returned
                    ? Icons.assignment_turned_in_outlined
                    : Icons.inventory_2_outlined,
                color: transaction.statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.resourceName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${transaction.userName} • ${transaction.sectionName.isEmpty ? 'No section' : transaction.sectionName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.effectiveStatus ==
                            BorrowTransactionStatus.returned
                        ? 'Returned ${_dateLabel(transaction.actualReturnDate ?? transaction.expectedReturnDate)}'
                        : 'Due ${_dateLabel(transaction.expectedReturnDate)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: BorrowStatusBadge(transaction: transaction),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  static String _dateLabel(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

enum _BorrowingSort { newest, dueSoon, borrower, item, status }

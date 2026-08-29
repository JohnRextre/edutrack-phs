import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';
import '../widgets/borrower_navigation_bar.dart';
import 'student/resubmit_appeal_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final tabIndex = initialTabIndex.clamp(0, 1);

    return DefaultTabController(
      length: 2,
      initialIndex: tabIndex,
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
            ? const Center(child: Text('Please sign in to view your requests.'))
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
                'No pending borrow requests.',
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
                'No pending return requests.',
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
              if (transaction.isBorrowRejected) ...[
                const SizedBox(height: 8),
                Text(
                  transaction.isExpiredBorrowRejection
                      ? BorrowService.borrowRequestExpiredDisplayReason
                      : (transaction.rejectionReason?.trim().isNotEmpty ??
                            false)
                      ? transaction.rejectionReason!.trim()
                      : 'No reason provided.',
                  style: TextStyle(
                    color: transaction.isExpiredBorrowRejection
                        ? Colors.amber.shade900
                        : Colors.red.shade700,
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

    final defaultType =
        ReturnType.normalizeRequiredReturnType(
          widget.transaction.requiredReturnType,
        ) ??
        ReturnType.paymentProof;

    setState(() => _isResubmitting = true);
    try {
      final selectedAppealType = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) =>
            _AppealTypeSelectionDialog(defaultType: defaultType),
      );

      if (!mounted || selectedAppealType == null) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResubmitAppealScreen(
            transaction: widget.transaction,
            appealType: selectedAppealType,
          ),
        ),
      );
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
              if (transaction.isReturnRejected) ...[
                const SizedBox(height: 8),
                if (transaction.rejectionReason?.trim().isNotEmpty ?? false)
                  Text(
                    'Reason: ${transaction.rejectionReason!.trim()}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                if (transaction.requiredReturnType?.trim().isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      'Correction Needed: Returned Type Item Should be: '
                      '${transaction.requiredReturnType!.trim()}',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
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

class _AppealTypeSelectionDialog extends StatefulWidget {
  const _AppealTypeSelectionDialog({required this.defaultType});

  final String defaultType;

  @override
  State<_AppealTypeSelectionDialog> createState() =>
      _AppealTypeSelectionDialogState();
}

class _AppealTypeSelectionDialogState
    extends State<_AppealTypeSelectionDialog> {
  late String _selectedType;

  static const List<_AppealOption> _options = [
    _AppealOption(value: ReturnType.paymentProof, label: 'Resubmit Payment'),
    _AppealOption(value: ReturnType.repairedProof, label: 'Repaired Item'),
    _AppealOption(
      value: ReturnType.replacementProof,
      label: 'Replacement Item',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    if (!_options.any((option) => option.value == _selectedType)) {
      _selectedType = ReturnType.paymentProof;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Appeal Type'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _options.map((option) {
            final selected = _selectedType == option.value;
            return RadioListTile<String>(
              value: option.value,
              groupValue: _selectedType,
              title: Text(option.label),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
              selected: selected,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedType),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _AppealOption {
  const _AppealOption({required this.value, required this.label});

  final String value;
  final String label;
}

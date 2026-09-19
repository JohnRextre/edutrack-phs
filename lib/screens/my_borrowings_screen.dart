import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../widgets/borrow_status_badge.dart';
import '../widgets/borrow_transaction_details_modal.dart';
import '../widgets/borrower_navigation_bar.dart';
import 'student/resubmit_appeal_screen.dart';
import 'student/return_item_screen.dart';

/// Screen for student / teacher to view their borrowed inventory and return request status.
class MyBorrowingsScreen extends StatelessWidget {
  const MyBorrowingsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final args = ModalRoute.of(context)?.settings.arguments;
    final tabIndex = (args is int ? args : initialTabIndex).clamp(0, 1);

    return DefaultTabController(
      length: 2,
      initialIndex: tabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Borrowed Items'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.inventory_2_outlined, size: 20),
                text: 'Currently Borrowed',
              ),
              Tab(
                icon: Icon(Icons.assignment_turned_in_outlined, size: 20),
                text: 'Return Status',
              ),
            ],
          ),
        ),
        body: userId == null
            ? const Center(
                child: Text('Please sign in to view your borrowed items.'),
              )
            : TabBarView(
                children: [
                  _ActiveBorrowingsTab(userId: userId),
                  _ReturnStatusTab(userId: userId),
                ],
              ),
        bottomNavigationBar: const BorrowerNavigationBar(selectedIndex: 2),
      ),
    );
  }
}

class _ActiveBorrowingsTab extends StatelessWidget {
  const _ActiveBorrowingsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final borrowService = BorrowService();

    return StreamBuilder<List<BorrowTransaction>>(
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

        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'You have no active borrowings.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Currently Borrowed',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Click "Return Item" when you are ready to surrender the item to the custodian.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (transaction) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BorrowedItemCard(
                  transaction: transaction,
                  borrowService: borrowService,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReturnStatusTab extends StatelessWidget {
  const _ReturnStatusTab({required this.userId});

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

        final items = snapshot.data ?? const [];

        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No pending return verification requests.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Return Verifications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Track the review status of your returned items or resubmit appeals.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (transaction) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ReturnStatusCard(
                  transaction: transaction,
                  borrowService: borrowService,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BorrowedItemCard extends StatelessWidget {
  const _BorrowedItemCard({
    required this.transaction,
    required this.borrowService,
  });

  final BorrowTransaction transaction;
  final BorrowService borrowService;

  Future<void> _startReturnFlow(BuildContext context) async {
    final returnType = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _ReturnTypeSelectionDialog(resourceName: transaction.resourceName),
    );

    if (returnType == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReturnItemScreen(transaction: transaction, returnType: returnType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Borrowed: ${formatBorrowDate(transaction.borrowDate)}'),
              Text('Due: ${formatBorrowDate(transaction.expectedReturnDate)}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                    fontSize: 12,
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
                      onPressed: () => _startReturnFlow(context),
                      icon: const Icon(Icons.assignment_return, size: 18),
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

class _ReturnStatusCard extends StatefulWidget {
  const _ReturnStatusCard({
    required this.transaction,
    required this.borrowService,
  });

  final BorrowTransaction transaction;
  final BorrowService borrowService;

  @override
  State<_ReturnStatusCard> createState() => _ReturnStatusCardState();
}

class _ReturnStatusCardState extends State<_ReturnStatusCard> {
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
              if (transaction.status ==
                  BorrowTransactionStatus.returnPending) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Awaiting verification from the Property Custodian.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (transaction.isReturnRejected) ...[
                const SizedBox(height: 10),
                if (transaction.rejectionReason?.trim().isNotEmpty ?? false)
                  Text(
                    'Rejection Reason: ${transaction.rejectionReason!.trim()}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 14),
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

class _ReturnTypeSelectionDialog extends StatelessWidget {
  const _ReturnTypeSelectionDialog({required this.resourceName});

  final String resourceName;

  static const _icons = <String, IconData>{
    ReturnType.goodCondition: Icons.check_circle_outline,
    ReturnType.paymentProof: Icons.receipt_long_outlined,
    ReturnType.repairedProof: Icons.build_outlined,
    ReturnType.replacementProof: Icons.swap_horiz_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Return Type'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you returning $resourceName?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...ReturnType.all.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: Icon(_icons[type]),
                  title: Text(
                    ReturnType.labelFor(type),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, type),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
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

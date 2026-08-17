import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';

/// Displays a colored status badge for a [BorrowTransaction].
class BorrowStatusBadge extends StatelessWidget {
  const BorrowStatusBadge({
    super.key,
    required this.transaction,
    this.compact = false,
  });

  final BorrowTransaction transaction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: transaction.statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(compact ? 12 : 20),
      ),
      child: Text(
        transaction.statusLabel,
        style: TextStyle(
          color: transaction.statusColor,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

String formatBorrowDate(DateTime date) =>
    '${date.month}/${date.day}/${date.year}';

String borrowDueLabel(BorrowTransaction transaction) {
  if (transaction.effectiveStatus == BorrowTransactionStatus.overdue) {
    final days = DateTime.now().difference(transaction.expectedReturnDate).inDays;
    return 'Overdue by $days day${days == 1 ? '' : 's'}';
  }
  final days = transaction.expectedReturnDate.difference(DateTime.now()).inDays;
  if (days <= 0) return 'Due today';
  return 'Due in $days day${days == 1 ? '' : 's'}';
}

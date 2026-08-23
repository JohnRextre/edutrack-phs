import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/dashboard_service.dart';

/// Whether a pending return was submitted past the expected return date.
bool isReturnOverdue(BorrowTransaction transaction) {
  if (transaction.overdueReason?.trim().isNotEmpty ?? false) {
    return true;
  }
  return DateTime.now().isAfter(transaction.expectedReturnDate);
}

/// Colored badge for the borrower's selected return proof type.
class ReturnTypeBadge extends StatelessWidget {
  const ReturnTypeBadge({
    super.key,
    required this.returnType,
    this.compact = false,
  });

  final String? returnType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = returnType != null && returnType!.trim().isNotEmpty
        ? ReturnType.labelFor(returnType!)
        : 'Return type not specified';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(compact ? 12 : 20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: compact ? 14 : 16,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent overdue alert shown on return verification cards and dialogs.
class OverdueReturnAlert extends StatelessWidget {
  const OverdueReturnAlert({
    super.key,
    this.overdueReason,
    this.compact = false,
  });

  final String? overdueReason;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Overdue Return',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
            ],
          ),
          if (overdueReason != null && overdueReason!.trim().isNotEmpty) ...[
            SizedBox(height: compact ? 6 : 8),
            Text(
              overdueReason!.trim(),
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: compact ? 12 : 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Borrower-submitted return details shown on pending return cards.
class ReturnSubmissionPreview extends StatelessWidget {
  const ReturnSubmissionPreview({
    super.key,
    required this.transaction,
    this.compact = false,
  });

  final BorrowTransaction transaction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conditionNotes = DashboardService.conditionNotes(transaction);
    final overdue = isReturnOverdue(transaction);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ReturnTypeBadge(returnType: transaction.returnType, compact: compact),
            if (overdue)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(compact ? 12 : 20),
                ),
                child: Text(
                  'Overdue',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          'Condition Notes',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          conditionNotes,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        if (overdue &&
            transaction.overdueReason?.trim().isNotEmpty == true) ...[
          SizedBox(height: compact ? 8 : 10),
          OverdueReturnAlert(
            overdueReason: transaction.overdueReason,
            compact: compact,
          ),
        ],
      ],
    );
  }
}


import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import '../services/borrow_service.dart';
import '../services/resource_service.dart';
import 'borrow_status_badge.dart';

/// Styled bottom sheet showing full details for a borrow transaction.
class BorrowTransactionDetailsModal extends StatelessWidget {
  const BorrowTransactionDetailsModal({
    super.key,
    required this.transaction,
    this.resource,
  });

  final BorrowTransaction transaction;
  final ResourceItem? resource;

  static Future<void> show(
    BuildContext context, {
    required BorrowTransaction transaction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => FutureBuilder<ResourceItem?>(
        future: ResourceService().getResourceById(transaction.resourceId),
        builder: (context, snapshot) {
          return BorrowTransactionDetailsModal(
            transaction: transaction,
            resource: snapshot.data,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Transaction Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _ResourceHeader(transaction: transaction, resource: resource),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Status',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  BorrowStatusBadge(transaction: transaction),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _TimelineCard(
                children: [
                  _TimelineRow(
                    icon: Icons.event_outlined,
                    label: 'Borrow Date',
                    value: formatBorrowDate(transaction.borrowDate),
                  ),
                  _TimelineRow(
                    icon: Icons.event_available_outlined,
                    label: 'Expected Return / Due Date',
                    value: formatBorrowDate(transaction.expectedReturnDate),
                  ),
                  if (transaction.returnSubmittedDate != null)
                    _TimelineRow(
                      icon: Icons.assignment_return_outlined,
                      label: 'Return Submitted',
                      value: formatBorrowDate(transaction.returnSubmittedDate!),
                    ),
                  if (transaction.actualReturnDate != null)
                    _TimelineRow(
                      icon: Icons.check_circle_outline,
                      label: 'Actual Return Date',
                      value: formatBorrowDate(transaction.actualReturnDate!),
                      isLast: true,
                    )
                  else
                    _TimelineRow(
                      icon: Icons.hourglass_empty_outlined,
                      label: 'Actual Return Date',
                      value: 'Not yet returned',
                      muted: true,
                      isLast: true,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Request Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                children: [
                  _DetailRow(
                    label: 'Quantity Requested',
                    value: transaction.requestedQuantity.toString(),
                  ),
                  _DetailRow(
                    label: 'User Role',
                    value: transaction.userRole == 'teacher'
                        ? 'Teacher'
                        : 'Student',
                  ),
                  _DetailRow(
                    label: 'Purpose of Borrowing',
                    value: transaction.purpose.trim().isEmpty
                        ? 'Not specified'
                        : transaction.purpose.trim(),
                    multiline: true,
                    isLast: true,
                  ),
                ],
              ),
              if ((transaction.isBorrowRejected ||
                      transaction.isReturnRejected) &&
                  (transaction.isExpiredBorrowRejection ||
                      (transaction.rejectionReason?.trim().isNotEmpty ??
                          false))) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        (transaction.isExpiredBorrowRejection
                                ? Colors.amber
                                : Colors.red)
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (transaction.isExpiredBorrowRejection
                                  ? Colors.amber
                                  : Colors.red)
                              .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: transaction.isExpiredBorrowRejection
                                ? Colors.amber.shade900
                                : Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            transaction.isExpiredBorrowRejection
                                ? 'Expiration Reason'
                                : 'Rejection Reason',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: transaction.isExpiredBorrowRejection
                                  ? Colors.amber.shade900
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transaction.isExpiredBorrowRejection
                            ? BorrowService.borrowRequestExpiredDisplayReason
                            : transaction.rejectionReason!.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (transaction.isReturnRejected &&
                  (transaction.requiredReturnType?.trim().isNotEmpty ??
                      false)) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Correction Needed: Returned Type Item Should be: '
                          '${transaction.requiredReturnType!.trim()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResourceHeader extends StatelessWidget {
  const _ResourceHeader({required this.transaction, this.resource});

  final BorrowTransaction transaction;
  final ResourceItem? resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final category = resource != null
        ? '${resource!.mainCategory} · ${resource!.subCategory}'
        : 'Category unavailable';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TransactionResourceImage(
            imageUrl: resource?.imageUrl,
            mainCategory: resource?.mainCategory ?? '',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.resourceName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Code: ${transaction.resourceCode}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionResourceImage extends StatelessWidget {
  const _TransactionResourceImage({
    required this.imageUrl,
    required this.mainCategory,
  });

  final String? imageUrl;
  final String mainCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedUrl = imageUrl?.trim() ?? '';
    final fallbackIcon = ResourceTaxonomy.iconForMainCategory(mainCategory);

    Widget fallback() {
      return Container(
        height: 160,
        color: colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon,
          size: 56,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    }

    if (trimmedUrl.isEmpty) return fallback();

    if (trimmedUrl.startsWith('http')) {
      return Image.network(
        trimmedUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, exception, stackTrace) => fallback(),
      );
    }

    return Image.asset(
      trimmedUrl,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, exception, stackTrace) => fallback(),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: muted ? colorScheme.onSurfaceVariant : null,
                    fontStyle: muted ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool multiline;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: multiline ? 1.4 : null,
            ),
          ),
        ],
      ),
    );
  }
}

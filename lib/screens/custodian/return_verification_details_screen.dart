import 'package:flutter/material.dart';

import '../../models/borrow_transaction_model.dart';
import '../../services/borrow_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/borrow_status_badge.dart';
import '../../widgets/return_verification_details.dart';

/// Full-screen return verification review for custodians.
class ReturnVerificationDetailsScreen extends StatefulWidget {
  const ReturnVerificationDetailsScreen({
    super.key,
    required this.transaction,
    this.borrowerSection,
  });

  final BorrowTransaction transaction;
  final String? borrowerSection;

  static Future<void> open(
    BuildContext context, {
    required BorrowTransaction transaction,
    String? borrowerSection,
  }) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ReturnVerificationDetailsScreen(
          transaction: transaction,
          borrowerSection: borrowerSection,
        ),
      ),
    );
  }

  @override
  State<ReturnVerificationDetailsScreen> createState() =>
      _ReturnVerificationDetailsScreenState();
}

class _ReturnVerificationDetailsScreenState
    extends State<ReturnVerificationDetailsScreen> {
  final BorrowService _borrowService = BorrowService();
  bool _isProcessing = false;

  BorrowTransaction get transaction => widget.transaction;

  bool get _overdue => isReturnOverdue(transaction);

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _confirmReturn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _borrowService.returnResource(
        transaction.id,
        transaction.resourceId,
      );
      if (!mounted) return;
      _showSnackBar('Return accepted and stock restored.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectReturn() async {
    final reasonController = TextEditingController();
    String? rejectionReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject the return request from ${transaction.userName} for '
              '${transaction.resourceName}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              rejectionReason = reasonController.text;
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Return'),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);

    if (confirmed != true || !mounted) return;

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _borrowService.rejectReturn(
        transaction.id,
        rejectionReason: rejectionReason,
      );
      if (!mounted) return;
      _showSnackBar('Return rejected.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conditionNotes = DashboardService.conditionNotes(transaction);
    final borrowerLabel = DashboardService.borrowerSubtitle(
      transaction,
      section: widget.borrowerSection,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Return Verification Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ItemOverviewHeaderCard(transaction: transaction),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Borrower & Timeline'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Borrower', value: borrowerLabel),
                    _DetailRow(
                      label: 'Borrow Date',
                      value: formatBorrowDate(transaction.borrowDate),
                    ),
                    _DetailRow(
                      label: 'Expected Return',
                      value: formatBorrowDate(transaction.expectedReturnDate),
                    ),
                    if (transaction.returnSubmittedDate != null)
                      _DetailRow(
                        label: 'Return Submitted',
                        value: formatBorrowDate(
                          transaction.returnSubmittedDate!,
                        ),
                      ),
                    if (transaction.requestedQuantity > 1)
                      _DetailRow(
                        label: 'Quantity',
                        value: transaction.requestedQuantity.toString(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Return Submission Details'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReturnTypeBadge(returnType: transaction.returnType),
                    const SizedBox(height: 16),
                    Text(
                      'Item Condition Notes',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conditionNotes,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    if (_overdue) ...[
                      const SizedBox(height: 16),
                      OverdueReturnAlert(
                        overdueReason: transaction.overdueReason,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Proof of Return'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proof of Return (Attach Image Placeholder)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _isProcessing ? null : _confirmReturn,
                icon: _isProcessing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Confirm & Accept Return'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isProcessing ? null : _rejectReturn,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject Return'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemOverviewHeaderCard extends StatelessWidget {
  const _ItemOverviewHeaderCard({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
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
            const SizedBox(height: 4),
            Text(
              transaction.resourceCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                BorrowStatusBadge(transaction: transaction, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

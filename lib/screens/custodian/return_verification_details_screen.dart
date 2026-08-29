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

  static Future<bool?> open(
    BuildContext context, {
    required BorrowTransaction transaction,
    String? borrowerSection,
  }) {
    return Navigator.push<bool>(
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
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(BorrowService.friendlyErrorMessage(error), isError: true);
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectReturn() async {
    if (_isProcessing) return;

    final dialogResult = await showDialog<_RejectReturnDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RejectReturnDialog(transaction: transaction),
    );

    if (!mounted || dialogResult == null || !dialogResult.confirmed) return;

    _isProcessing = true;

    try {
      await _borrowService.rejectReturn(
        transaction.id,
        rejectionReason: dialogResult.reason ?? '',
        requiredReturnType: dialogResult.requiredReturnType ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(BorrowService.friendlyErrorMessage(error), isError: true);
      setState(() => _isProcessing = false);
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
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

class _RejectReturnDialogResult {
  const _RejectReturnDialogResult.cancelled()
    : confirmed = false,
      reason = null,
      requiredReturnType = null;

  const _RejectReturnDialogResult.confirmed(
    this.reason,
    this.requiredReturnType,
  ) : confirmed = true;

  final bool confirmed;
  final String? reason;
  final String? requiredReturnType;
}

class _RejectReturnDialog extends StatefulWidget {
  const _RejectReturnDialog({required this.transaction});

  final BorrowTransaction transaction;

  @override
  State<_RejectReturnDialog> createState() => _RejectReturnDialogState();
}

class _RejectReturnDialogState extends State<_RejectReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  String? _selectedRequiredReturnType;

  BorrowTransaction get transaction => widget.transaction;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _selectedRequiredReturnType = transaction.requiredReturnType;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop(_RejectReturnDialogResult.cancelled());
  }

  void _confirmReject() {
    if (!_formKey.currentState!.validate()) return;

    final reason = _reasonController.text.trim();
    final requiredReturnType = _selectedRequiredReturnType?.trim();

    Navigator.of(
      context,
    ).pop(_RejectReturnDialogResult.confirmed(reason, requiredReturnType));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Return'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject the return request from ${transaction.userName} for '
                '${transaction.resourceName}?',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason for Rejection *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for rejecting this return';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRequiredReturnType,
                decoration: const InputDecoration(
                  labelText: 'Returned Type Item Should be *',
                  border: OutlineInputBorder(),
                ),
                items: ReturnType.correctiveReturnTypeOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRequiredReturnType = value);
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select a corrective return type.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        FilledButton(
          onPressed: _confirmReject,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject Return'),
        ),
      ],
    );
  }
}

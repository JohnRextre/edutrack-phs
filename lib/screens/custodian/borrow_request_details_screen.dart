import 'package:flutter/material.dart';

import '../../models/borrow_transaction_model.dart';
import '../../models/resource_item.dart';
import '../../services/borrow_service.dart';
import '../../services/resource_service.dart';
import '../../widgets/borrow_status_badge.dart';

class BorrowRequestDetailsScreen extends StatefulWidget {
  const BorrowRequestDetailsScreen({
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
        builder: (_) => BorrowRequestDetailsScreen(
          transaction: transaction,
          borrowerSection: borrowerSection,
        ),
      ),
    );
  }

  @override
  State<BorrowRequestDetailsScreen> createState() =>
      _BorrowRequestDetailsScreenState();
}

class _BorrowRequestDetailsScreenState
    extends State<BorrowRequestDetailsScreen> {
  final BorrowService _borrowService = BorrowService();
  final ResourceService _resourceService = ResourceService();
  ResourceItem? _resource;
  bool _isProcessing = false;

  BorrowTransaction get transaction => widget.transaction;

  bool get _isExpired =>
      BorrowService.isPendingBorrowTransactionExpired(transaction);

  String get _durationLabel {
    final difference = transaction.expectedReturnDate.difference(
      transaction.borrowDate,
    );
    final days = difference.inDays;
    return days <= 0 ? 'Same day' : '$days ${days == 1 ? 'day' : 'days'}';
  }

  String get _roleLabel {
    final role = transaction.userRole.trim();
    if (role.isEmpty) return 'Student';
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _loadResource();
  }

  Future<void> _loadResource() async {
    final resource = await _resourceService.getResourceById(
      transaction.resourceId,
    );
    if (!mounted) return;
    setState(() => _resource = resource);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _approveRequest() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _borrowService.approveBorrow(
        transaction.id,
        transaction.resourceId,
      );
      if (!mounted) return;
      _showSnackBar('Borrow request approved successfully.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(BorrowService.friendlyErrorMessage(error), isError: true);
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest() async {
    if (_isProcessing) return;

    final dialogResult = await showDialog<_RejectBorrowDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RejectBorrowDialog(transaction: transaction),
    );

    if (!mounted || dialogResult == null || !dialogResult.confirmed) return;

    setState(() => _isProcessing = true);

    try {
      await _borrowService.rejectBorrow(
        transaction.id,
        rejectionReason: dialogResult.reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(BorrowService.friendlyErrorMessage(error), isError: true);
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _markExpired() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _borrowService.expireBorrowRequest(transaction.id);
      if (!mounted) return;
      _showSnackBar('Borrow request marked as expired.');
      Navigator.of(context).pop(true);
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
    final resource = _resource;
    final itemName = resource?.itemName ?? transaction.resourceName;
    final itemCode = resource?.itemCode ?? transaction.resourceCode;
    final itemCategory = resource?.mainCategory ?? 'Resource';
    final imageUrl = resource?.imageUrl;
    final availableQuantity = resource?.availableQuantity ?? 0;
    final totalQuantity =
        resource?.totalQuantity ?? transaction.requestedQuantity;
    final borrowerSection = widget.borrowerSection?.trim();
    final purpose = transaction.purpose.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Borrow Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _ResourceFallbackIcon(
                                      icon:
                                          ResourceTaxonomy.iconForMainCategory(
                                            itemCategory,
                                          ),
                                    ),
                              )
                            : _ResourceFallbackIcon(
                                icon: ResourceTaxonomy.iconForMainCategory(
                                  itemCategory,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itemCode,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  itemCategory,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Stock: $availableQuantity / $totalQuantity',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Borrower Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Borrower', value: transaction.userName),
                    _DetailRow(label: 'Role', value: _roleLabel),
                    _DetailRow(
                      label: 'Section / Dept.',
                      value:
                          borrowerSection != null && borrowerSection.isNotEmpty
                          ? borrowerSection
                          : 'Not specified',
                    ),
                    _DetailRow(
                      label: 'Purpose',
                      value: purpose.isNotEmpty
                          ? purpose
                          : 'No purpose specified',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Timeline & Quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Borrow Date',
                      value: formatBorrowDate(transaction.borrowDate),
                    ),
                    _DetailRow(
                      label: 'Expected Return',
                      value: formatBorrowDate(transaction.expectedReturnDate),
                    ),
                    _DetailRow(label: 'Duration', value: _durationLabel),
                    _DetailRow(
                      label: 'Requested Quantity',
                      value:
                          '${transaction.requestedQuantity} ${transaction.requestedQuantity == 1 ? 'unit' : 'units'}',
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpired) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.amber.shade700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This request has expired because the scheduled date has passed.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _markExpired,
                icon: const Icon(Icons.history_toggle_off),
                label: const Text('Mark Expired'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _isExpired
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _approveRequest,
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
                      label: const Text('Confirm & Approve Request'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _isProcessing ? null : _rejectRequest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject Request'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ResourceFallbackIcon extends StatelessWidget {
  const _ResourceFallbackIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
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

class _RejectBorrowDialogResult {
  const _RejectBorrowDialogResult.cancelled() : confirmed = false, reason = '';

  const _RejectBorrowDialogResult.confirmed(this.reason) : confirmed = true;

  final bool confirmed;
  final String reason;
}

class _RejectBorrowDialog extends StatefulWidget {
  const _RejectBorrowDialog({required this.transaction});

  final BorrowTransaction transaction;

  @override
  State<_RejectBorrowDialog> createState() => _RejectBorrowDialogState();
}

class _RejectBorrowDialogState extends State<_RejectBorrowDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  void _cancel() {
    Navigator.of(context).pop(_RejectBorrowDialogResult.cancelled());
  }

  void _confirmReject() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(
      context,
    ).pop(_RejectBorrowDialogResult.confirmed(_reasonController.text.trim()));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Borrow Request'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject the request from ${widget.transaction.userName} for '
                '${widget.transaction.resourceName}?',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for rejecting this request';
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
          child: const Text('Reject Request'),
        ),
      ],
    );
  }
}

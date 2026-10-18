import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/borrow_transaction_model.dart';
import '../../services/borrow_service.dart';
import '../../widgets/borrow_status_badge.dart';
import '../../widgets/proof_image_attachment_field.dart';

/// Full-screen form for submitting a return request with proof type and details.
class ReturnItemScreen extends StatefulWidget {
  const ReturnItemScreen({
    super.key,
    required this.transaction,
    required this.returnType,
  });

  final BorrowTransaction transaction;
  final String returnType;

  @override
  State<ReturnItemScreen> createState() => _ReturnItemScreenState();
}

class _ReturnItemScreenState extends State<ReturnItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _overdueReasonController = TextEditingController();
  final _itemConditionController = TextEditingController();
  late final TextEditingController _quantityController;
  final _borrowService = BorrowService();
  String? _proofImageUrl;
  late String _selectedReturnType;
  bool _isSubmitting = false;

  BorrowTransaction get transaction => widget.transaction;

  bool get _isTeacher => transaction.userRole.trim().toLowerCase() == 'teacher';

  bool get _isOverdue => DateTime.now().isAfter(transaction.expectedReturnDate);

  int get _quantityToReturn =>
      _isTeacher ? int.tryParse(_quantityController.text) ?? 0 : 1;

  int get _remainingAfterReturn =>
      transaction.requestedQuantity - _quantityToReturn;

  void _setQuantity(int quantity) {
    _quantityController.text = quantity.toString();
    setState(() {});
  }

  void _decrementQuantity() {
    if (_quantityToReturn > 1) _setQuantity(_quantityToReturn - 1);
  }

  void _incrementQuantity() {
    if (_quantityToReturn < transaction.requestedQuantity) {
      _setQuantity(_quantityToReturn + 1);
    }
  }

  String _returnTypeLabel(String type) {
    switch (type) {
      case ReturnType.goodCondition:
        return 'Good Condition';
      case ReturnType.paymentProof:
        return 'Payment Proof';
      case ReturnType.repairedProof:
        return 'Repaired Item';
      case ReturnType.replacementProof:
        return 'Replacement Item';
      default:
        return ReturnType.labelFor(type);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedReturnType = widget.returnType;
    _quantityController = TextEditingController(
      text: _isTeacher ? transaction.requestedQuantity.toString() : '1',
    );
  }

  @override
  void dispose() {
    _overdueReasonController.dispose();
    _itemConditionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_quantityToReturn < 1 ||
        _quantityToReturn > transaction.requestedQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity must be between 1 and ${transaction.requestedQuantity}.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _borrowService.submitReturn(
        transactionId: transaction.id,
        returnType: _selectedReturnType,
        returnQuantity: _quantityToReturn,
        itemConditionNotes: _itemConditionController.text.trim(),
        overdueReason: _isOverdue ? _overdueReasonController.text.trim() : null,
        returnProofImage: _proofImageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted for verification'),
        ),
      );
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/my-borrowings', arguments: 1);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BorrowService.friendlyErrorMessage(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Return Item')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ItemDetailsCard(
                      transaction: transaction,
                      isOverdue: _isOverdue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Return Quantity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Quantity to Return *',
                        helperText:
                            'Borrowed: ${transaction.requestedQuantity} • Remaining after this return: $_remainingAfterReturn',
                        border: const OutlineInputBorder(),
                      ),
                      child: _isTeacher
                          ? Row(
                              children: [
                                IconButton.outlined(
                                  onPressed: _quantityToReturn > 1
                                      ? _decrementQuantity
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      TextInputFormatter.withFunction((
                                        oldValue,
                                        newValue,
                                      ) {
                                        if (newValue.text.isEmpty) {
                                          return newValue;
                                        }
                                        final parsed = int.tryParse(
                                          newValue.text,
                                        );
                                        if (parsed == null ||
                                            parsed < 1 ||
                                            parsed >
                                                transaction.requestedQuantity) {
                                          return oldValue;
                                        }
                                        return newValue;
                                      }),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    validator: (value) {
                                      final quantity = int.tryParse(
                                        value?.trim() ?? '',
                                      );
                                      if (quantity == null || quantity < 1) {
                                        return 'Enter at least 1.';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                IconButton.outlined(
                                  onPressed:
                                      _quantityToReturn <
                                          transaction.requestedQuantity
                                      ? _incrementQuantity
                                      : null,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            )
                          : const Text(
                              '1',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedReturnType,
                      decoration: const InputDecoration(
                        labelText: 'Return Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment_return_outlined),
                      ),
                      items: ReturnType.all
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                _returnTypeLabel(type),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedReturnType = value);
                        }
                      },
                    ),
                    if (_isOverdue) ...[
                      const SizedBox(height: 16),
                      _OverdueWarningBanner(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _overdueReasonController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Overdue / Delay *',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (!_isOverdue) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please explain why the return is overdue.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Proof of Return',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment_return_outlined,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _returnTypeLabel(_selectedReturnType),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ProofImageAttachmentField(
                      imageUrl: _proofImageUrl,
                      title: 'Attach Return Proof Image',
                      subtitle:
                          'Take a photo of the item, receipt, or select from gallery',
                      onImageChanged: (url) {
                        setState(() => _proofImageUrl = url);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Item Condition',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _itemConditionController,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Item Condition Details *',
                        hintText:
                            'Describe the current physical/working condition of the item...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe the item condition.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Return Request',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemDetailsCard extends StatelessWidget {
  const _ItemDetailsCard({required this.transaction, required this.isOverdue});

  final BorrowTransaction transaction;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
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
                    'Item Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                BorrowStatusBadge(transaction: transaction, compact: true),
              ],
            ),
            const SizedBox(height: 14),
            _DetailRow(label: 'Item Name', value: transaction.resourceName),
            const SizedBox(height: 8),
            _DetailRow(label: 'Item Code', value: transaction.resourceCode),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Borrow Date',
              value: formatBorrowDate(transaction.borrowDate),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Expected Return Date',
              value: formatBorrowDate(transaction.expectedReturnDate),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.12)
                    : Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOverdue ? 'Status: Overdue' : 'Status: Normal',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? Colors.red.shade700 : Colors.blue.shade800,
                ),
              ),
            ),
          ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
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
    );
  }
}

class _OverdueWarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This item is overdue!',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

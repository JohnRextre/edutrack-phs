import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';

class ReturnTypeSelectionDialog extends StatelessWidget {
  const ReturnTypeSelectionDialog({super.key, required this.resourceName});

  final String resourceName;

  static const _icons = <String, IconData>{
    ReturnType.goodCondition: Icons.check_circle_outline,
    ReturnType.paymentProof: Icons.receipt_long_outlined,
    ReturnType.repairedProof: Icons.build_outlined,
    ReturnType.replacementProof: Icons.swap_horiz_outlined,
  };

  static const _labels = <String, String>{
    ReturnType.goodCondition: 'Good Condition',
    ReturnType.paymentProof: 'Payment Proof',
    ReturnType.repairedProof: 'Repaired Item',
    ReturnType.replacementProof: 'Replacement Item',
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
            ...ReturnType.all.map(
              (type) => Padding(
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
                    _labels[type] ?? ReturnType.labelFor(type),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, type),
                ),
              ),
            ),
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

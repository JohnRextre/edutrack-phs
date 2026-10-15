import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import '../services/borrow_service.dart';

Future<void> showBorrowerReturnPreviewModal({
  required BuildContext context,
  required BorrowTransaction transaction,
  ResourceItem? resource,
  required VoidCallback onProceed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _BorrowerQrReturnPreviewSheet(
      transaction: transaction,
      resource: resource,
      onProceed: () {
        Navigator.of(sheetContext).pop();
        onProceed();
      },
    ),
  );
}

class _BorrowerQrReturnPreviewSheet extends StatelessWidget {
  const _BorrowerQrReturnPreviewSheet({
    required this.transaction,
    required this.resource,
    required this.onProceed,
  });

  final BorrowTransaction transaction;
  final ResourceItem? resource;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = BorrowService.isOverdueBorrowing(transaction);
    final imageUrl = resource?.imageUrl?.trim() ?? '';

    return SafeArea(
      top: false,
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 170,
                child: imageUrl.isEmpty
                    ? _ResourceFallback(resource: resource)
                    : _ResourceImage(
                        imageUrl: imageUrl,
                        fallback: _ResourceFallback(resource: resource),
                      ),
              ),
              const SizedBox(height: 18),
              Text(
                transaction.resourceName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.qr_code_2, size: 18),
                  label: Text(transaction.resourceCode),
                ),
              ),
              const SizedBox(height: 10),
              _TimelineRow(
                label: 'Borrow date',
                value: _formatDate(transaction.borrowDate),
              ),
              _TimelineRow(
                label: 'Due date',
                value: _formatDate(transaction.expectedReturnDate),
              ),
              if (overdue)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade800,
                    ),
                    label: const Text('Overdue'),
                    labelStyle: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.red.withValues(alpha: .12),
                    side: BorderSide.none,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Please ensure the item is complete and in good condition before returning.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onProceed,
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Proceed to Return Item'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel / Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ResourceFallback extends StatelessWidget {
  const _ResourceFallback({required this.resource});

  final ResourceItem? resource;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        resource?.fallbackIcon ?? Icons.inventory_2_outlined,
        size: 68,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}

class _ResourceImage extends StatelessWidget {
  const _ResourceImage({required this.imageUrl, required this.fallback});

  final String imageUrl;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(
          imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl,
        );
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

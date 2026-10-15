import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/dashboard_service.dart';
import 'return_verification_details.dart';

Future<void> showQrReturnResponseModal({
  required BuildContext context,
  required BorrowTransaction transaction,
  required Future<void> Function(BorrowTransaction transaction) onReview,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _QrReturnResponseSheet(
      transaction: transaction,
      onReview: () async {
        Navigator.of(sheetContext).pop();
        await onReview(transaction);
      },
    ),
  );
}

class _QrReturnResponseSheet extends StatelessWidget {
  const _QrReturnResponseSheet({
    required this.transaction,
    required this.onReview,
  });

  final BorrowTransaction transaction;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = isReturnOverdue(transaction);
    final proofImage = transaction.returnProofImage?.trim() ?? '';

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
              if (proofImage.isNotEmpty) ...[
                SizedBox(
                  height: 190,
                  child: _ReturnProofImage(image: proofImage),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Borrower's Return Proof Photo",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ] else
                _MissingProofNotice(),
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
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.person_outline,
                label: 'Borrower',
                value:
                    '${transaction.userName} (${transaction.userRole})',
              ),
              _SummaryRow(
                icon: Icons.notes_outlined,
                label: 'Condition notes',
                value: DashboardService.conditionNotes(transaction),
              ),
              if (overdue)
                Chip(
                  avatar: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade800,
                  ),
                  label: const Text('Return is overdue'),
                  labelStyle: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.red.withValues(alpha: .12),
                  side: BorderSide.none,
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review & Verify Return'),
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
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _MissingProofNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_not_supported_outlined, size: 34),
        SizedBox(height: 6),
        Text('No return proof photo was uploaded.'),
      ],
    ),
  );
}

class _ReturnProofImage extends StatelessWidget {
  const _ReturnProofImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final fallback = _MissingProofNotice();
    if (image.startsWith('data:image')) {
      try {
        final bytes = base64Decode(
          image.contains(',') ? image.split(',').last : image,
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
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      image,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

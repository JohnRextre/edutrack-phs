import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/resource_item.dart';

Future<void> showQrBorrowResponseModal({
  required BuildContext context,
  required ResourceItem resource,
  required Future<void> Function(ResourceItem resource) onProceed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _QrBorrowResponseSheet(
      resource: resource,
      onProceed: () async {
        Navigator.of(sheetContext).pop();
        await onProceed(resource);
      },
    ),
  );
}

class _QrBorrowResponseSheet extends StatelessWidget {
  const _QrBorrowResponseSheet({
    required this.resource,
    required this.onProceed,
  });

  final ResourceItem resource;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAvailable = resource.availableQuantity > 0;

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
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 210,
                child: _QrResourceImage(resource: resource),
              ),
              const SizedBox(height: 18),
              Text(
                resource.itemName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(resource.itemCode),
                  avatar: const Icon(Icons.qr_code_2, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: [
                  resource.mainCategory,
                  if (resource.subCategory.isNotEmpty) resource.subCategory,
                ].join(' / '),
              ),
              if (resource.storageLocation.isNotEmpty)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Storage location',
                  value: resource.storageLocation,
                ),
              const SizedBox(height: 12),
              Chip(
                avatar: Icon(
                  isAvailable
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 18,
                  color: isAvailable
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
                label: Text(
                  isAvailable
                      ? '${resource.availableQuantity} available'
                      : 'Item is currently unavailable for borrowing.',
                ),
                labelStyle: TextStyle(
                  color: isAvailable
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: isAvailable
                    ? Colors.green.withValues(alpha: .12)
                    : Colors.red.withValues(alpha: .12),
                side: BorderSide.none,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isAvailable ? onProceed : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Proceed to Borrow Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value.isEmpty ? 'Not specified' : value)),
      ],
    ),
  );
}

class _QrResourceImage extends StatelessWidget {
  const _QrResourceImage({required this.resource});

  final ResourceItem resource;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resource.imageUrl?.trim() ?? '';
    final fallback = _fallback(context);
    if (imageUrl.isEmpty) return fallback;

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

  Widget _fallback(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.secondaryContainer,
    alignment: Alignment.center,
    child: Icon(
      resource.fallbackIcon,
      size: 80,
      color: Theme.of(context).colorScheme.onSecondaryContainer,
    ),
  );
}

import 'package:flutter/material.dart';

import '../models/borrow_transaction_model.dart';
import '../services/borrow_service.dart';
import '../services/qr_service.dart';
import '../widgets/borrow_status_badge.dart';

/// Custodian screen to verify returns submitted by borrowers.
class CustodianReturnVerificationScreen extends StatefulWidget {
  const CustodianReturnVerificationScreen({super.key});

  @override
  State<CustodianReturnVerificationScreen> createState() =>
      _CustodianReturnVerificationScreenState();
}

class _CustodianReturnVerificationScreenState
    extends State<CustodianReturnVerificationScreen> {
  final BorrowService _borrowService = BorrowService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _qrPayloadController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _qrPayloadController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Action completed successfully.');
      }
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _verifyReturn(BorrowTransaction transaction) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verify Return'),
        content: Text(
          'Confirm that ${transaction.resourceName} (${transaction.resourceCode}) '
          'has been returned by ${transaction.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _runWithLoading(
                () => _borrowService.verifyReturn(
                  transaction.id,
                  transaction.resourceId,
                ),
              );
            },
            icon: const Icon(Icons.verified_user),
            label: const Text('Verify Return'),
          ),
        ],
      ),
    );
  }

  void _rejectReturn(BorrowTransaction transaction) {
    final reasonController = TextEditingController();

    showDialog<void>(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _runWithLoading(
                () => _borrowService.rejectReturn(
                  transaction.id,
                  rejectionReason: reasonController.text,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Return'),
          ),
        ],
      ),
    ).whenComplete(reasonController.dispose);
  }

  Future<void> _lookupByQrPayload() async {
    final payload = _qrPayloadController.text.trim();
    if (payload.isEmpty) {
      _showSnackBar('Paste or enter the scanned QR payload.', isError: true);
      return;
    }

    final itemCode = QrService.parseItemCodeFromPayload(payload);
    if (itemCode == null) {
      _showSnackBar(
        'Could not find an Item Code in the QR payload.',
        isError: true,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transaction =
          await _borrowService.findPendingReturnByResourceCode(itemCode);
      if (!mounted) return;
      Navigator.pop(context);

      if (transaction == null) {
        _showSnackBar(
          'No pending return request found for code "$itemCode".',
          isError: true,
        );
        return;
      }

      _verifyReturn(transaction);
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          BorrowService.friendlyErrorMessage(error),
          isError: true,
        );
      }
    }
  }

  void _openQrLookupDialog() {
    _qrPayloadController.clear();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QR Code Lookup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the scanned QR payload below. The item code will be '
              'extracted automatically.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qrPayloadController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'QR Payload',
                hintText:
                    'System: EduTrack PHS\nItem Name: ...\nItem Code: ...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _lookupByQrPayload();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Look Up'),
          ),
        ],
      ),
    );
  }

  List<BorrowTransaction> _filterTransactions(
    List<BorrowTransaction> transactions,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return transactions;

    return transactions.where((transaction) {
      return transaction.resourceName.toLowerCase().contains(query) ||
          transaction.resourceCode.toLowerCase().contains(query) ||
          transaction.userName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Verification'),
        actions: [
          IconButton(
            tooltip: 'QR Code Lookup',
            onPressed: _openQrLookupDialog,
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by borrower, item name, or code...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _openQrLookupDialog,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Verify via QR Payload'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<BorrowTransaction>>(
              stream: _borrowService.watchPendingReturnRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      BorrowService.friendlyErrorMessage(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = _filterTransactions(
                  snapshot.data ?? const [],
                );

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No return requests awaiting verification.\n'
                        'Items appear here after a borrower submits a return.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final transaction = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PendingReturnCard(
                        transaction: transaction,
                        onVerify: () => _verifyReturn(transaction),
                        onReject: () => _rejectReturn(transaction),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingReturnCard extends StatelessWidget {
  const _PendingReturnCard({
    required this.transaction,
    required this.onVerify,
    required this.onReject,
  });

  final BorrowTransaction transaction;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.resourceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                BorrowStatusBadge(transaction: transaction, compact: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              transaction.resourceCode,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(transaction.userName)),
              ],
            ),
            if (transaction.returnSubmittedDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Return submitted: '
                '${formatBorrowDate(transaction.returnSubmittedDate!)}',
              ),
            ],
            if (transaction.requestedQuantity > 1) ...[
              const SizedBox(height: 4),
              Text('Quantity: ${transaction.requestedQuantity}'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Verify Return'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/account_role.dart';
import '../models/borrow_transaction_model.dart';
import '../models/resource_item.dart';
import '../services/auth_service.dart';
import '../services/borrow_service.dart';
import '../services/qr_service.dart';
import '../services/resource_service.dart';
import '../widgets/access_banner.dart';
import '../widgets/borrow_transaction_details_modal.dart';
import '../widgets/borrower_qr_return_preview_modal.dart';
import '../widgets/qr_borrow_response_modal.dart';
import '../widgets/qr_camera_scanner_screen.dart';
import '../widgets/return_type_selection_dialog.dart';
import 'student/borrow_item_screen.dart';
import 'student/return_item_screen.dart';

class BorrowerDashboardScreen extends StatelessWidget {
  const BorrowerDashboardScreen({
    super.key,
    required this.role,
    required this.onSignOut,
  });

  final AccountRole role;
  final VoidCallback onSignOut;

  Future<String?> _scanPayload(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrCameraScannerScreen()),
    );
  }

  Future<void> _scanToBorrow(BuildContext context) async {
    final payload = await _scanPayload(context);
    if (!context.mounted || payload == null) return;

    final itemCode = QrService.parseItemCodeFromPayload(payload);
    if (itemCode == null) {
      _showSnackBar(context, 'Invalid EduTrack QR code.', isError: true);
      return;
    }

    final resourceService = ResourceService();
    _showLoading(context);
    var loadingVisible = true;
    try {
      final resource = await resourceService.getResourceByItemCode(itemCode);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      loadingVisible = false;
      if (resource == null) {
        _showSnackBar(
          context,
          "No item found for code '$itemCode'.",
          isError: true,
        );
        return;
      }
      await showQrBorrowResponseModal(
        context: context,
        resource: resource,
        onProceed: (_) async => _openBorrowItem(context, resource),
      );
    } catch (error) {
      if (!context.mounted) return;
      if (loadingVisible) Navigator.of(context).pop();
      _showSnackBar(
        context,
        'Unable to look up this item. '
        '${ResourceService.friendlyErrorMessage(error)}',
        isError: true,
      );
    }
  }

  Future<void> _scanToReturn(BuildContext context, String userId) async {
    final payload = await _scanPayload(context);
    if (!context.mounted || payload == null) return;

    final itemCode = QrService.parseItemCodeFromPayload(payload);
    if (itemCode == null) {
      _showSnackBar(context, 'Invalid EduTrack QR code.', isError: true);
      return;
    }

    _showLoading(context);
    var loadingVisible = true;
    try {
      final transaction = await BorrowService()
          .findActiveBorrowingByUserAndCode(userId: userId, itemCode: itemCode);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      loadingVisible = false;
      if (transaction == null) {
        _showSnackBar(
          context,
          "No active borrowed item found for code '$itemCode'.",
          isError: true,
        );
        return;
      }

      final resource = await ResourceService().getResourceById(
        transaction.resourceId,
      );
      if (!context.mounted) return;
      await showBorrowerReturnPreviewModal(
        context: context,
        transaction: transaction,
        resource: resource,
        onProceed: () {
          _selectReturnTypeAndContinue(context, transaction);
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      if (loadingVisible) Navigator.of(context).pop();
      _showSnackBar(
        context,
        'Unable to find this borrowed item. '
        '${BorrowService.friendlyErrorMessage(error)}',
        isError: true,
      );
    }
  }

  void _openBorrowItem(BuildContext context, ResourceItem resource) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BorrowItemScreen(resource: resource)),
    );
  }

  Future<void> _selectReturnTypeAndContinue(
    BuildContext context,
    BorrowTransaction transaction,
  ) async {
    final returnType = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          ReturnTypeSelectionDialog(resourceName: transaction.resourceName),
    );

    if (returnType == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReturnItemScreen(transaction: transaction, returnType: returnType),
      ),
    );
  }

  void _showLoading(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final borrowService = BorrowService();

    if (userId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Please sign in to view your dashboard.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        StreamBuilder(
          stream: AuthService.watchCurrentUserProfile(),
          builder: (context, snapshot) {
            final firstName = snapshot.data?.firstName.trim();
            final displayName = firstName != null && firstName.isNotEmpty
                ? firstName
                : 'Borrower';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $displayName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${role.label} account',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const AccessBanner(
          text:
              'Borrower Access: You can browse available learning resources, borrow items, view your borrowed inventory, and submit return verifications.',
        ),
        const SizedBox(height: 16),
        _QuickQrActions(
          onBorrow: () => _scanToBorrow(context),
          onReturn: () => _scanToReturn(context, userId),
        ),
        const SizedBox(height: 16),
        _BorrowerStats(userId: userId, borrowService: borrowService),
        const SizedBox(height: 18),
        Text(
          'Due Soon',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _DueSoonSection(userId: userId, borrowService: borrowService),
        const SizedBox(height: 18),
        Text(
          'Borrowing History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _BorrowingHistorySection(userId: userId, borrowService: borrowService),
      ],
    );
  }
}

class _BorrowerStats extends StatelessWidget {
  const _BorrowerStats({required this.userId, required this.borrowService});

  final String userId;
  final BorrowService borrowService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BorrowerDashboardMetrics>(
      stream: borrowService.watchBorrowerMetrics(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            BorrowService.friendlyErrorMessage(snapshot.error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }

        final metrics = snapshot.data ?? BorrowerDashboardMetrics.empty;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'My Borrowed Resources',
                    value: metrics.borrowedCount.toString(),
                    icon: Icons.inventory_2_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/my-borrowings',
                      arguments: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pending Return Requests',
                    value: metrics.pendingReturnCount.toString(),
                    icon: Icons.assignment_turned_in_outlined,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/my-borrowings',
                      arguments: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Overdue Resources',
                    value: metrics.overdueCount.toString(),
                    icon: Icons.warning_amber_outlined,
                    accentColor: metrics.overdueCount > 0 ? Colors.red : null,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/my-borrowings',
                      arguments: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuickQrActions extends StatelessWidget {
  const _QuickQrActions({required this.onBorrow, required this.onReturn});

  final VoidCallback onBorrow;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick QR Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickQrActionCard(
                label: 'Scan to Borrow',
                icon: Icons.qr_code_scanner,
                onTap: onBorrow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickQrActionCard(
                label: 'Scan to Return',
                icon: Icons.assignment_return_outlined,
                onTap: onReturn,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickQrActionCard extends StatelessWidget {
  const _QuickQrActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Open camera scanner',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = accentColor ?? colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueSoonSection extends StatelessWidget {
  const _DueSoonSection({required this.userId, required this.borrowService});

  final String userId;
  final BorrowService borrowService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BorrowTransaction>>(
      stream: borrowService.watchDueSoonBorrowings(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyStateCard(
            icon: Icons.error_outline,
            message: BorrowService.friendlyErrorMessage(snapshot.error!),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const _EmptyStateCard(
            icon: Icons.event_available_outlined,
            message: 'No upcoming due dates',
          );
        }

        return Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              _DueSoonTile(transaction: items[index]),
            ],
          ],
        );
      },
    );
  }
}

class _DueSoonTile extends StatelessWidget {
  const _DueSoonTile({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final overdue = BorrowService.isOverdueBorrowing(transaction);
    final dueLabel = BorrowService.dueSoonLabel(transaction.expectedReturnDate);
    final accentColor = overdue ? Colors.red.shade700 : Colors.amber.shade800;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/my-borrowings'),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Icon(Icons.schedule_outlined, color: accentColor, size: 20),
          ),
          title: Text(
            transaction.resourceName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${transaction.resourceCode} · $dueLabel'),
          trailing: Icon(Icons.chevron_right, color: accentColor),
        ),
      ),
    );
  }
}

class _BorrowingHistorySection extends StatelessWidget {
  const _BorrowingHistorySection({
    required this.userId,
    required this.borrowService,
  });

  final String userId;
  final BorrowService borrowService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BorrowTransaction>>(
      stream: borrowService.watchRecentBorrowingHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyStateCard(
            icon: Icons.error_outline,
            message: BorrowService.friendlyErrorMessage(snapshot.error!),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const _EmptyStateCard(
            icon: Icons.history,
            message: 'No borrowing history yet',
          );
        }

        return Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              _HistoryTile(transaction: items[index]),
            ],
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.transaction});

  final BorrowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isReturned = transaction.status == BorrowTransactionStatus.returned;
    final iconColor = isReturned ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => BorrowTransactionDetailsModal.show(
          context,
          transaction: transaction,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(
              isReturned ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(
            transaction.resourceName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${transaction.resourceCode} · '
            '${BorrowService.historySubtitle(transaction)}',
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
